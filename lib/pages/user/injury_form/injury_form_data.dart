import 'dart:typed_data';

import 'package:flutter/material.dart';

/// A file that the user picked for U1-2.
class PickedFile {
  const PickedFile(this.name, this.bytes);

  final String name;
  final Uint8List bytes;
}

/// The three uploads of U1-2: server part name, title and icon.
const List<(String, String, IconData)> uploadSlots = <(String, String, IconData)>[
  ('id_card', 'Image of National ID Card', Icons.image),
  ('medical_record', 'Medical Record File', Icons.description),
  ('injury_form', 'Injury Form File', Icons.description),
];

/// The values of InjuryFormPage (U1-2). The JSON names are the server names
/// (server: InjuryForm.fromJson).
class InjuryFormData {
  final TextEditingController firstName = TextEditingController();
  final TextEditingController lastName = TextEditingController();
  final TextEditingController address = TextEditingController();
  final TextEditingController nationalId = TextEditingController();
  final TextEditingController phone = TextEditingController();
  final TextEditingController password = TextEditingController();
  final TextEditingController confirmPassword = TextEditingController();
  final TextEditingController injuryPlace = TextEditingController();
  final TextEditingController injuryCause = TextEditingController();
  final TextEditingController bodyPart = TextEditingController();

  String title = 'นาย';
  String gender = 'M';
  DateTime? birthDate;
  DateTime? injuryDateTime;
  String? injuryCategory;
  final Map<String, PickedFile> files = <String, PickedFile>{};

  static const List<String> titles = <String>['นาย', 'นาง', 'นางสาว'];
  static const List<String> categories = <String>[
    'Fracture', 'Sprain', 'Burn', 'Cut', 'Crush injury', 'Back strain', 'Other',
  ];

  Map<String, Object?> toJson() => <String, Object?>{
        'title_name': title,
        'first_name': firstName.text.trim(),
        'last_name': lastName.text.trim(),
        'address': address.text.trim(),
        'national_id': nationalId.text.trim(),
        'date_of_birth': birthDate == null ? '' : _date(birthDate!),
        'phone_no': phone.text.trim(),
        'gender': gender,
        'password': password.text,
        'confirm_password': confirmPassword.text,
        'injury_datetime': injuryDateTime == null ? '' : '${_date(injuryDateTime!)} ${_time(injuryDateTime!)}',
        'injury_place': injuryPlace.text.trim(),
        'injury_cause': injuryCause.text.trim(),
        'body_part': bodyPart.text.trim(),
        'injury_category': injuryCategory ?? '',
      };

  void dispose() {
    for (final TextEditingController c in <TextEditingController>[
      firstName, lastName, address, nationalId, phone, password, confirmPassword, injuryPlace, injuryCause, bodyPart,
    ]) {
      c.dispose();
    }
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
  static String _date(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';
  static String _time(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';

  /// 'dd/MM/yyyy', as on frame U1-2.
  static String showDate(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';

  /// 'dd/MM/yyyy HH:mm'
  static String showDateTime(DateTime d) => '${showDate(d)} ${_time(d)}';
}
