import 'dart:io';

import 'package:sst_server/auth/session_token.dart';
import 'package:sst_server/controller/controller.dart';
import 'package:sst_server/controller/insured_form_controller.dart';
import 'package:sst_server/model/claim_model.dart';
import 'package:sst_server/model/field_rules.dart';
import 'package:sst_server/model/injury_form.dart';
import 'package:sst_server/model/insured_person_model.dart';
import 'package:sst_server/repository/claim_repository.dart';
import 'package:sst_server/repository/insured_person_repository.dart';
import 'package:sst_server/repository/user_account_repository.dart';
import 'package:sst_server/storage/file_storage.dart';
import 'package:test/test.dart';

import '../support/test_db.dart';
import 'u1_fixtures.dart';

/// A register that cannot be reached (07-open-questions.md, item 3).
class _UnreachableRegister extends InsuredPersonRepository {
  _UnreachableRegister(super.db);

  @override
  Future<Map<String, Object?>?> findInSSORegister(String nationalId) =>
      Future.error(const RegisterUnavailableException());
}

void main() {
  final db = useTestDb();
  late Directory storageDir;
  setUp(() => storageDir = Directory.systemTemp.createTempSync('sst-u1-'));
  tearDown(() => storageDir.deleteSync(recursive: true));

  InsuredFormController controller({InsuredPersonRepository? people}) => InsuredFormController(
        db: db,
        personModel: InsuredPersonModel(people ?? InsuredPersonRepository(db)),
        claimModel: ClaimModel(ClaimRepository(db), LocalFileStorage(storageDir.path)),
        accounts: UserAccountRepository(db),
        tokens: SessionToken('test'),
      );

  Future<Map<String, String>> fieldErrorsOf(InjuryForm form, [List<UploadedFile>? files]) async {
    try {
      await controller().submitInjuryForm(form, files ?? validFiles());
      fail('Validation did not fail');
    } on ControllerException catch (e) {
      expect(e.status, 422);
      return (e.details!['fields'] as Map).cast<String, String>();
    }
  }

  Future<Map<String, Object?>> row(String sql, Map<String, Object?> p) async =>
      (await db.performQuery(sql, p)).rows.single;

  test('U1 Normal Case: person, employer, coverage, claim, 3 files, check, history and account', () =>
      inRollback(db, () async {
        final result = await controller().submitInjuryForm(validForm(), validFiles());

        final claim = result['claim'] as Map<String, Object?>;
        expect(claim['claim_no'], matches(RegExp(r'^SST-\d{4}-\d{6}$')));
        expect(claim['claim_status'], 'Awaiting verification');
        expect(claim['claimant_name'], 'นาย ทดลอง ใจดี');
        expect(result['token'], isA<String>());

        final person = await row('SELECT * FROM InsuredPerson WHERE national_id = :id', {'id': newNationalId});
        expect(person['phone_no'], '0812345678');
        final claimId = int.parse((claim['claim_no'] as String).substring(9));
        final ic = await row('SELECT * FROM InjuryClaim WHERE claim_id = :id', {'id': claimId});
        expect(ic['employer_id'], 11, reason: 'Q1.4 found the employer account of the register');
        final docs = await ClaimRepository(db).findDocuments(claimId);
        expect(docs.map((d) => d['file_uri']), contains('/claims/$claimId/id_card_front.jpg'));
        expect(File('${storageDir.path}/claims/$claimId/id_card_front.jpg').existsSync(), isTrue);
        final check = await ClaimRepository(db).findAutoEligibility(claimId);
        expect(check!['eligibility_status'], 'Covered');
        final history = await row('SELECT * FROM ClaimStatusHistory WHERE claim_id = :id', {'id': claimId});
        expect(history['to_status'], 'Awaiting verification');
        expect(await UserAccountRepository(db).findAccountByLogin(newNationalId, 'Secret123'), isNotNull);
      }));

  test('U1 Normal Case [Register unavailable]: the claim is saved for the officer to check', () =>
      inRollback(db, () async {
        final result =
            await controller(people: _UnreachableRegister(db)).submitInjuryForm(validForm(), validFiles());
        expect((result['claim'] as Map)['claim_status'], 'Register unavailable');
        final ic = await row(
            'SELECT employer_id FROM InjuryClaim WHERE claim_no = :no', {'no': (result['claim'] as Map)['claim_no']});
        expect(ic['employer_id'], isNull);
      }));

  test('U1 Alternate Case 1 [Validation Failed]: the four errors of frame U1-3', () => inRollback(db, () async {
        final errors = await fieldErrorsOf(validForm({
          'first_name': 'Somchai',
          'national_id': '11037001234',
          'phone_no': '08-12',
          'confirm_password': 'Secret12',
        }));
        expect(errors, {
          'first_name': FieldRules.thaiName,
          'national_id': FieldRules.nationalId,
          'phone_no': FieldRules.phone,
          'confirm_password': FieldRules.passwordMismatch,
        });
      }));

  test('U1 Alternate Case 1 [Validation Failed]: national ID already registered (Q1.2, frame U1-4)', () =>
      inRollback(db, () async {
        try {
          await controller().submitInjuryForm(validForm({'national_id': '1103700123456'}), validFiles());
          fail('Validation did not fail');
        } on ControllerException catch (e) {
          expect(e.details!['already_registered'], true);
          expect((e.details!['fields'] as Map)['national_id'], FieldRules.alreadyRegistered);
        }
      }));

  test('U1 Alternate Case 1 [Validation Failed]: Section 33 coverage not ACTIVE (Q1.1)', () => inRollback(db, () async {
        final errors = await fieldErrorsOf(validForm({'national_id': '1909900111222'}));
        expect(errors, {'national_id': FieldRules.notActive});
      }));

  test('U1 Alternate Case 1 [Validation Failed]: password rule, title, gender, empty fields and files', () =>
      inRollback(db, () async {
        final errors = await fieldErrorsOf(
          validForm({'password': 'short', 'confirm_password': 'short', 'title_name': 'Mr', 'gender': 'X', 'address': ''}),
          [validFiles().first, UploadedFile(docTypeId: 2, fileName: 'record.exe', bytes: validFiles()[1].bytes)],
        );
        expect(errors, {
          'title_name': FieldRules.title,
          'address': FieldRules.required,
          'gender': FieldRules.gender,
          'medical_record': FieldRules.fileType,
          'injury_form': FieldRules.fileMissing,
          'password': FieldRules.password,
        });
      }));

  test('U1 Alternate Case 1 [Validation Failed]: nothing is saved', () => inRollback(db, () async {
        await fieldErrorsOf(validForm({'first_name': 'Somchai'}));
        final n = await row('SELECT COUNT(*) AS n FROM InsuredPerson WHERE national_id = :id', {'id': newNationalId});
        expect(n['n'], 0);
      }));
}
