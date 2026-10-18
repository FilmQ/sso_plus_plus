import 'dart:typed_data';

import '../auth/user_session.dart';
import '../db/db_connector.dart';
import '../model/claim_model.dart';
import '../model/field_rules.dart';
import '../model/model.dart';
import '../model/notification_model.dart';
import '../storage/file_storage.dart';
import 'controller.dart';

/// O1 View Injury Application, O2 Approve Injury Application and O3 Reject
/// Injury Application (SA report 2.13, sequences O1 to O3). Only an
/// Evaluation Officer can use it.
class VerificationController extends Controller {
  VerificationController(super.session, this.db, this.claimModel, this.notificationModel, this.storage);

  final DBConnector db;
  final ClaimModel claimModel;
  final NotificationModel notificationModel;
  final FileStorage storage;

  int get _officerId => requireRole(Role.officer).officerId!;

  /// O1 steps 1 to 2 (QO1.1, QO1.2): the Verification Page.
  Future<Map<String, Object?>> getVerificationList() async {
    _officerId;
    final list = await claimModel.getPendingApplications();
    return {'claims': list.claims, 'counts': list.counts};
  }

  /// O1 steps 3 to 4 (QO1.3 to QO1.5): the Eligibility Decision Page.
  Future<Map<String, Object?>> getClaimDetail(int claimId) async {
    _officerId;
    final detail = await claimModel.getClaimDetail(claimId);
    if (detail == null) throw const ControllerException(404, 'There is no claim with this ID.');
    return detail;
  }

  /// O3 step 2 (QO1.6): the reasons of the dropdown.
  Future<List<Map<String, Object?>>> getRejectionReasons() {
    _officerId;
    return claimModel.getRejectionReasons();
  }

  /// O1 steps 5 to 6: the file of a QO1.4 row of the claim. Gives the bytes
  /// and the MIME type.
  Future<({Uint8List bytes, String mimeType})> openFile(int claimId, String fileName) async {
    final detail = await getClaimDetail(claimId);
    final documents = (detail['documents']! as List).cast<Map<String, Object?>>();
    final doc = documents.where((d) => d['file_name'] == fileName).firstOrNull;
    final bytes = doc == null ? null : await storage.read(doc['file_uri']! as String);
    if (bytes == null) throw const ControllerException(404, 'The file is not available.');
    return (bytes: bytes, mimeType: FieldRules.mimeTypeOf(fileName) ?? 'application/octet-stream');
  }

  /// O2 step 6.1: QO2.1 ('Covered'), then QN.1 to the user, in one
  /// transaction. A decided claim gives 409.
  Future<Map<String, Object?>> confirmResult(int claimId, {String? overrideReason}) {
    final officerId = _officerId;
    _checkLength({'override_reason': (overrideReason, 255)});
    return db.transaction(() async {
      final summary = (await getClaimDetail(claimId))['summary']! as Map<String, Object?>;
      await claimModel.confirmResult(claimId, officerId: officerId, overrideReason: _blankToNull(overrideReason));
      // The QN.1 text of O2 is the text of the seed messages 901 and 906 (D-048).
      await notificationModel.notifyUser(
          claimId, 'Claim confirmed', 'Your claim ${summary['claim_no']} is covered under Section 33.');
      return {'claim_status': 'Covered'};
    });
  }

  /// O3 step 6.1: QO3.1 ('Not covered'), QO3.2 ('Rejected'), then QN.2 to the
  /// user, in one transaction. A decided claim gives 409.
  Future<Map<String, Object?>> rejectApplication(int claimId,
      {required String reasonCode, String? officerMessage, String? overrideReason}) async {
    final officerId = _officerId;
    _checkLength({'officer_message': (officerMessage, 1000), 'override_reason': (overrideReason, 255)});
    final codes = [for (final r in await claimModel.getRejectionReasons()) r['reason_code']];
    if (!codes.contains(reasonCode)) {
      throw const ValidationFailedException({'reason_code': 'Choose a rejection reason.'});
    }
    return db.transaction(() async {
      await getClaimDetail(claimId);
      await claimModel.rejectApplication(claimId,
          officerId: officerId,
          reasonCode: reasonCode,
          officerMessage: _blankToNull(officerMessage),
          overrideReason: _blankToNull(overrideReason));
      await notificationModel.notifyRejection(claimId);
      return {'claim_status': 'Rejected'};
    });
  }

  /// The column lengths of the data dictionary (422).
  static void _checkLength(Map<String, (String?, int)> fields) {
    final errors = {
      for (final MapEntry(key: name, value: (text, max)) in fields.entries)
        if (text != null && text.length > max) name: 'Use $max characters or fewer.',
    };
    if (errors.isNotEmpty) throw ValidationFailedException(errors);
  }

  static String? _blankToNull(String? text) => (text == null || text.trim().isEmpty) ? null : text.trim();
}
