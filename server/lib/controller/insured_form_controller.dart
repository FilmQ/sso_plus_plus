import 'package:postgres/postgres.dart' show ServerException;

import '../auth/session_token.dart';
import '../auth/user_session.dart';
import '../db/db_connector.dart';
import '../model/claim_model.dart';
import '../model/field_rules.dart';
import '../model/injury_form.dart';
import '../model/insured_person_model.dart';
import '../model/model.dart';
import '../repository/user_account_repository.dart';
import 'controller.dart';

/// U1 Submit Injury Application (SA report 2.13, sequence U1).
class InsuredFormController extends Controller {
  InsuredFormController({
    required this.db,
    required this.personModel,
    required this.claimModel,
    required this.accounts,
    required this.tokens,
  }) : super(null);

  final DBConnector db;
  final InsuredPersonModel personModel;
  final ClaimModel claimModel;
  final UserAccountRepository accounts;
  final SessionToken tokens;

  /// Registers the person, saves the claim and the files, and makes the login
  /// account, all in one transaction. Gives the data of screen U1-5 and a
  /// login token, so that "Go to Home" opens U2-1 at once.
  Future<Map<String, Object?>> submitInjuryForm(InjuryForm form, List<UploadedFile> files) async {
    try {
      return await db.transaction(() async {
        final reg = await personModel.register(form, files);
        final claimNo = await claimModel.createClaim(reg.insuredId, form, files, reg);
        final accountId = await accounts.insertUserAccount(
            loginName: form.nationalId, password: form.password, insuredId: reg.insuredId);
        final claim = (await claimModel.claims.findLatestClaimOf(reg.insuredId))!;
        final session = UserSession(
          accountId: accountId,
          role: Role.user,
          displayName: form.fullName,
          firstName: form.firstName,
          insuredId: reg.insuredId,
        );
        return {
          'token': tokens.issue(session),
          'session': session.toJson(),
          'claim': {
            'claim_no': claimNo,
            'claim_status': claim['claim_status'],
            'submitted_time': claim['submitted_time'],
            'claimant_name': form.fullName,
            'files_received': [for (final f in files) f.docTypeId],
          },
        };
      });
    } on ValidationFailedException catch (e) {
      throw _validationFailed(e.fieldErrors, alreadyRegistered: e.alreadyRegistered);
    } on ServerException catch (e) {
      await _removeFiles();
      // Two submissions with one national ID at the same time: the UNIQUE key stops the second.
      if (e.code == '23505') {
        throw _validationFailed({'national_id': FieldRules.alreadyRegistered}, alreadyRegistered: true);
      }
      handleError(e);
    } catch (e) {
      await _removeFiles();
      handleError(e);
    }
  }

  Future<void> _removeFiles() async {
    final id = claimModel.lastClaimId;
    if (id != null) await claimModel.storage.deleteClaim(id);
  }

  static ControllerException _validationFailed(Map<String, String> fields, {required bool alreadyRegistered}) =>
      ControllerException(422, 'validation_failed', details: {
        'fields': fields,
        'already_registered': alreadyRegistered,
      });
}
