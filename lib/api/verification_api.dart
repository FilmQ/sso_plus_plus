import 'dart:typed_data';

import 'api_client.dart';

/// The page side of server VerificationController (O1, O2, O3; D-048).
class VerificationApi {
  const VerificationApi(this.api);

  final ApiClient api;

  /// QO1.1 and QO1.2: the Verification Page (claims, counts).
  Future<Map<String, Object?>> getVerificationList() => api.get('/o1/claims');

  /// QO1.3 to QO1.5: the Eligibility Decision Page (summary, documents,
  /// eligibility).
  Future<Map<String, Object?>> getClaimDetail(int claimId) => api.get('/o1/claims/$claimId');

  /// O1 step 6: the stored file of a QO1.4 row.
  Future<({Uint8List bytes, String? mimeType})> openFile(int claimId, String fileName) =>
      api.getBytes('/o1/claims/$claimId/documents/${Uri.encodeComponent(fileName)}');

  /// QO1.6: reason_code and name_th of each rejection reason.
  Future<List<Map<String, Object?>>> getRejectionReasons() async =>
      ((await api.get('/o3/rejection-reasons'))['reasons']! as List<Object?>).cast<Map<String, Object?>>();

  /// QO2.1 and QN.1. Gives claim_status and decided_at.
  Future<Map<String, Object?>> confirmResult(int claimId, {String? overrideReason}) =>
      api.post('/o2/claims/$claimId/confirm', <String, Object?>{'override_reason': overrideReason});

  /// QO3.1, QO3.2 and QN.2. Gives claim_status and decided_at.
  Future<Map<String, Object?>> rejectApplication(int claimId,
          {required String reasonCode, String? officerMessage, String? overrideReason}) =>
      api.post('/o3/claims/$claimId/reject', <String, Object?>{
        'reason_code': reasonCode,
        'officer_message': officerMessage,
        'override_reason': overrideReason,
      });
}
