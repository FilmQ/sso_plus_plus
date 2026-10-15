import '../repository/insured_person_repository.dart';
import 'field_rules.dart';
import 'injury_form.dart';
import 'model.dart';

/// The result of [InsuredPersonModel.register] (sequence U1, message 29).
class Registration {
  const Registration({
    required this.insuredId,
    required this.employerId,
    required this.coverageId,
    required this.registerResult,
  });

  final int insuredId;
  final int? employerId;
  final int? coverageId;

  /// 'Covered' or 'Register unavailable' (the :register_result of Q1.6, Q1.9).
  final String registerResult;
}

/// InsuredPerson (SA report 2.18, used in U1).
class InsuredPersonModel extends Model {
  InsuredPersonModel(this.people);

  final InsuredPersonRepository people;

  /// U1 step 4 and 5.1 to 5.3. Throws [ValidationFailedException] when a check
  /// fails (Alternate Case 1). Run it in a transaction.
  Future<Registration> register(InjuryForm form, List<UploadedFile> files) async {
    validateFields(form, files);
    var registerResult = 'Covered';
    var alreadyRegistered = false;
    Map<String, Object?>? reg;
    if (!fieldErrors.containsKey('national_id')) {
      try {
        // Q1.1: Section 33 coverage must be ACTIVE. The row also has the
        // employer and contribution data for Q1.4 and Q1.5.
        reg = await people.findInSSORegister(form.nationalId);
        if (reg == null) fieldErrors['national_id'] = FieldRules.notActive;
      } on RegisterUnavailableException {
        registerResult = 'Register unavailable';
      }
      // Q1.2: the national ID must not be registered.
      if (await people.countByNationalId(form.nationalId) > 0) {
        fieldErrors['national_id'] = FieldRules.alreadyRegistered;
        alreadyRegistered = true;
      }
    }
    if (!isValid()) {
      throw ValidationFailedException(Map.of(fieldErrors), alreadyRegistered: alreadyRegistered);
    }

    // Q1.3
    final insuredId = await people.insertInsuredPerson(
      nationalId: form.nationalId,
      titleName: form.titleName,
      firstName: form.firstName,
      lastName: form.lastName,
      dateOfBirth: form.dateOfBirth,
      gender: form.gender,
      phoneNo: FieldRules.normalPhone(form.phoneNo),
      address: form.address,
    );
    if (reg == null) {
      return Registration(insuredId: insuredId, employerId: null, coverageId: null, registerResult: registerResult);
    }
    // Q1.4
    final employerId = await people.upsertEmployer(
      accountNo: reg['employer_account_no']! as String,
      name: reg['employer_name']! as String,
    );
    // Q1.5
    final coverageId = await people.insertCoverage(
      insuredId: insuredId,
      employerId: employerId,
      registrationDate: reg['registration_date']!,
      contributionStart: reg['contribution_start']!,
      contributionEnd: reg['contribution_end'],
      contributionMonths: reg['contribution_months']! as int,
    );
    return Registration(
        insuredId: insuredId, employerId: employerId, coverageId: coverageId, registerResult: registerResult);
  }

  /// The empty, format and length checks of U1 step 4 (no database).
  void validateFields(InjuryForm form, List<UploadedFile> files) {
    fieldErrors.clear();
    void check(String field, bool ok, String message) {
      if (!ok) fieldErrors.putIfAbsent(field, () => message);
    }

    void required(String field, String value, int max) {
      check(field, value.isNotEmpty, FieldRules.required);
      check(field, value.length <= max, FieldRules.tooLong);
    }

    check('title_name', FieldRules.titles.contains(form.titleName), FieldRules.title);
    required('first_name', form.firstName, 80);
    check('first_name', FieldRules.isThaiEncoding(form.firstName), FieldRules.thaiName);
    required('last_name', form.lastName, 80);
    check('last_name', FieldRules.isThaiEncoding(form.lastName), FieldRules.thaiName);
    required('address', form.address, 255);
    check('national_id', FieldRules.isNationalId(form.nationalId), FieldRules.nationalId);
    check('date_of_birth', _isAdultBirthDate(form.dateOfBirth), FieldRules.birthDate);
    check('phone_no', FieldRules.isPhone(form.phoneNo), FieldRules.phone);
    check('gender', FieldRules.genders.contains(form.gender), FieldRules.gender);
    check('injury_datetime', _isPastDateTime(form.injuryDatetime), FieldRules.injuryDate);
    required('injury_place', form.injuryPlace, 255);
    required('injury_cause', form.injuryCause, 255);
    required('body_part', form.bodyPart, 80);
    required('injury_category', form.injuryCategory, 60);
    for (final MapEntry(key: field, value: docTypeId) in requiredDocuments.entries) {
      final file = files.where((f) => f.docTypeId == docTypeId).firstOrNull;
      check(field, file != null, FieldRules.fileMissing);
      if (file != null) {
        final okType = FieldRules.mimeTypeOf(file.fileName) != null;
        final okSize = file.bytes.isNotEmpty && file.bytes.length <= FieldRules.maxFileBytes;
        check(field, okType && okSize, FieldRules.fileType);
      }
    }
    check('password', FieldRules.isPassword(form.password), FieldRules.password);
    check('confirm_password', FieldRules.passwordMatches(form.password, form.confirmPassword),
        FieldRules.passwordMismatch);
  }

  /// Data dictionary: before today, and 15 years old or older.
  static bool _isAdultBirthDate(String value) {
    final d = DateTime.tryParse(value);
    if (d == null || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return false;
    final now = DateTime.now();
    return !DateTime(d.year + 15, d.month, d.day).isAfter(now);
  }

  /// Data dictionary: not after the submission time.
  static bool _isPastDateTime(String value) {
    final d = DateTime.tryParse(value);
    return d != null && !d.isAfter(DateTime.now());
  }
}
