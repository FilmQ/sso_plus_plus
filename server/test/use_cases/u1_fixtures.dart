import 'dart:typed_data';

import 'package:sst_server/model/injury_form.dart';

/// An ACTIVE person of the register stub who is not yet in InsuredPerson
/// (server/db/seeds/002_register_demo_people.sql). The employer account is the seed employer 11.
const newNationalId = '1555500011122';

/// A correct U1-2 form. [changes] replaces fields (JSON names).
InjuryForm validForm([Map<String, Object?> changes = const {}]) => InjuryForm.fromJson({
      'title_name': 'นาย',
      'first_name': 'ทดลอง',
      'last_name': 'ใจดี',
      'address': '99/12 ถนนพหลโยธิน แขวงสามเสนใน เขตพญาไท กรุงเทพฯ 10400',
      'national_id': newNationalId,
      'date_of_birth': '1988-03-12',
      'phone_no': '081 234 5678',
      'gender': 'M',
      'password': 'Secret123',
      'confirm_password': 'Secret123',
      'injury_datetime': '2026-10-01 08:40',
      'injury_place': 'Factory line 3, Bang Phli, Samut Prakan',
      'injury_cause': 'Hand caught in a conveyor roller',
      'body_part': 'right wrist',
      'injury_category': 'Fracture',
      ...changes,
    });

/// The three files of U1-2.
List<UploadedFile> validFiles() => [
      UploadedFile(docTypeId: 1, fileName: 'id_card_front.jpg', bytes: Uint8List.fromList([1, 2, 3])),
      UploadedFile(docTypeId: 2, fileName: 'medical_record_rama.pdf', bytes: Uint8List.fromList([4, 5])),
      UploadedFile(docTypeId: 3, fileName: 'injury_form_kt16.pdf', bytes: Uint8List.fromList([6])),
    ];
