import 'dart:typed_data';

/// The fields of U1-2 Fill in Injury Forms Page.
///
/// The injury fields (injury_datetime to injury_category) are not on the
/// Figma frame, but Q1.6 needs them (R-003).
class InjuryForm {
  const InjuryForm({
    required this.titleName,
    required this.firstName,
    required this.lastName,
    required this.address,
    required this.nationalId,
    required this.dateOfBirth,
    required this.phoneNo,
    required this.gender,
    required this.password,
    required this.confirmPassword,
    required this.injuryDatetime,
    required this.injuryPlace,
    required this.injuryCause,
    required this.bodyPart,
    required this.injuryCategory,
  });

  final String titleName;
  final String firstName;
  final String lastName;
  final String address;
  final String nationalId;

  /// 'yyyy-MM-dd'
  final String dateOfBirth;
  final String phoneNo;

  /// 'M', 'F' or 'O' (Others, R-005).
  final String gender;
  final String password;
  final String confirmPassword;

  /// 'yyyy-MM-dd HH:mm'
  final String injuryDatetime;
  final String injuryPlace;
  final String injuryCause;
  final String bodyPart;
  final String injuryCategory;

  /// The display name of U1-5, for example 'นาย สมชาย ประเสริฐ'.
  String get fullName => '$titleName $firstName $lastName';

  factory InjuryForm.fromJson(Map<String, Object?> j) {
    String s(String key) => ((j[key] as String?) ?? '').trim();
    return InjuryForm(
      titleName: s('title_name'),
      firstName: s('first_name'),
      lastName: s('last_name'),
      address: s('address'),
      nationalId: s('national_id'),
      dateOfBirth: s('date_of_birth'),
      phoneNo: s('phone_no'),
      gender: s('gender'),
      password: (j['password'] as String?) ?? '',
      confirmPassword: (j['confirm_password'] as String?) ?? '',
      injuryDatetime: s('injury_datetime'),
      injuryPlace: s('injury_place'),
      injuryCause: s('injury_cause'),
      bodyPart: s('body_part'),
      injuryCategory: s('injury_category'),
    );
  }
}

/// One uploaded file of U1-2. [docTypeId] is a DocumentType row (seed: 1, 2, 3).
class UploadedFile {
  const UploadedFile({required this.docTypeId, required this.fileName, required this.bytes});

  final int docTypeId;
  final String fileName;
  final Uint8List bytes;
}

/// The three files of U1-2: form field name to DocumentType.doc_type_id.
const requiredDocuments = <String, int>{
  'id_card': 1, // DOC-ID  Image of National ID Card
  'medical_record': 2, // DOC-MED Medical Record File
  'injury_form': 3, // KT-16   Injury Form File
};
