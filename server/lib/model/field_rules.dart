/// The field rules of the U1 use case description (step 4) and the data
/// dictionary (SA report 2.17). The messages are the texts of frame U1-3.
abstract final class FieldRules {
  static const titles = ['นาย', 'นาง', 'นางสาว'];
  static const genders = ['M', 'F', 'O'];
  static const maxFileBytes = 10485760; // 10 MB (ClaimDocument.file_size_bytes)
  static const mimeTypes = {'.jpg': 'image/jpeg', '.jpeg': 'image/jpeg', '.png': 'image/png', '.pdf': 'application/pdf'};

  static final _nationalId = RegExp(r'^\d{13}$');
  static final _password = RegExp(r'^[A-Za-z0-9]{8,}$');
  static final _phone = RegExp(r'^0\d{8,9}$');
  static final _thai = RegExp(r'^[\u0E00-\u0E7F]+( [\u0E00-\u0E7F]+)*$');

  /// isThaiEncoding() of the U1 description: Thai characters only.
  static bool isThaiEncoding(String s) => _thai.hasMatch(s);

  /// RE: ^\d{13}$
  static bool isNationalId(String s) => _nationalId.hasMatch(s);

  /// RE: ^[A-Za-z0-9]{8,}$
  static bool isPassword(String s) => _password.hasMatch(s);

  /// passwordMatches() of the U1 description.
  static bool passwordMatches(String password, String confirm) => password == confirm;

  /// The data dictionary rule (D-016): 9 or 10 digits that start with 0,
  /// after [normalPhone].
  static bool isPhone(String s) => _phone.hasMatch(normalPhone(s));

  /// Removes spaces, dots, dashes and brackets, and changes a leading +66
  /// into 0 (D-016). '+66 81 234 5678' gives '0812345678'.
  static String normalPhone(String s) {
    final digits = s.replaceAll(RegExp(r'[ ().-]'), '');
    return digits.startsWith('+66') ? '0${digits.substring(3)}' : digits;
  }

  /// The MIME type from the file name, or null when the type is not allowed.
  static String? mimeTypeOf(String fileName) {
    final dot = fileName.lastIndexOf('.');
    return dot < 0 ? null : mimeTypes[fileName.substring(dot).toLowerCase()];
  }

  static const required = 'Fill in this field';
  static const thaiName = 'Use Thai characters only, as on your national ID card';
  static const nationalId = 'National ID must be exactly 13 digits';
  static const notActive = 'No ACTIVE Section 33 coverage was found for this national ID';
  static const alreadyRegistered = 'This national ID is already registered';
  static const phone = 'Enter a valid phone number, for example 081 234 5678';
  static const password = 'At least 8 characters, English letters and numbers only';
  static const passwordMismatch = 'Passwords do not match';
  static const title = 'Choose one of the provided titles: นาย, นาง, นางสาว';
  static const gender = 'Choose Male, Female or Others';
  static const birthDate = 'Enter a correct birth date. You must be 15 years old or older';
  static const injuryDate = 'Enter the date and time of the injury. It cannot be in the future';
  static const tooLong = 'This text is too long';
  static const fileMissing = 'Attach this file';
  static const fileType = 'Use a PDF, JPG or PNG file of 10 MB or less';
}
