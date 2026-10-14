import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:test/test.dart';

import '../support/http.dart';
import '../support/test_db.dart';
import '../use_cases/u1_fixtures.dart';

/// Builds the multipart request that the Flutter InjuryFormPage sends.
Future<Request> _multipart(Map<String, Object?> form, {bool withFiles = true}) async {
  final m = http.MultipartRequest('POST', Uri.parse('http://localhost/u1/injury-forms'))
    ..fields['form'] = jsonEncode(form);
  if (withFiles) {
    m.files
      ..add(http.MultipartFile.fromBytes('id_card', [1, 2, 3], filename: 'id_card_front.jpg'))
      ..add(http.MultipartFile.fromBytes('medical_record', [4], filename: 'medical_record.pdf'))
      ..add(http.MultipartFile.fromBytes('injury_form', [5], filename: 'injury_form_kt16.pdf'));
  }
  final stream = m.finalize();
  return Request('POST', m.url, headers: m.headers, body: stream);
}

void main() {
  final db = useTestDb();
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('sst-http-'));
  tearDown(() => dir.deleteSync(recursive: true));

  Map<String, Object?> form([Map<String, Object?> changes = const {}]) => {
        'title_name': 'นาย', 'first_name': 'ทดลอง', 'last_name': 'ใจดี', 'address': '1 ถนนพหลโยธิน กรุงเทพฯ',
        'national_id': newNationalId, 'date_of_birth': '1988-03-12', 'phone_no': '0812345678', 'gender': 'M',
        'password': 'Secret123', 'confirm_password': 'Secret123', 'injury_datetime': '2026-10-01 08:40',
        'injury_place': 'Factory', 'injury_cause': 'Roller', 'body_part': 'right wrist', 'injury_category': 'Fracture',
        ...changes,
      };

  test('POST /u1/injury-forms: 201 with the U1-5 data, then the new user can sign in', () => inRollback(db, () async {
        final client = TestClient(db, storageDir: dir.path);
        final r = await client.send(await _multipart(form()));
        expect(r.status, 201);
        expect((r.json['claim'] as Map)['files_received'], [1, 2, 3]);
        expect((await client.login(newNationalId, password: 'Secret123')).status, 200);
      }));

  test('POST /u1/injury-forms: 422 with field errors when files are missing', () => inRollback(db, () async {
        final r = await TestClient(db, storageDir: dir.path).send(await _multipart(form(), withFiles: false));
        expect(r.status, 422);
        expect((r.json['fields'] as Map).keys, containsAll(['id_card', 'medical_record', 'injury_form']));
      }));
}
