import 'package:flutter_test/flutter_test.dart';
import 'package:sso_plus_plus/l10n/tr.dart';

String _th(String text) => translate('th', text);

void main() {
  group('labels', () {
    test('English shows the key', () {
      expect(translate('en', 'Language'), 'Language');
    });

    test('Thai shows the table entry', () {
      expect(_th('Language'), 'ภาษา');
    });

    test('A text with no entry stays as it is', () {
      expect(_th('นาย สมชาย ประเสริฐ'), 'นาย สมชาย ประเสริฐ');
      expect(_th('88/5 Some Road'), '88/5 Some Road');
    });

    test('Each placeholder takes its value, and a value is not read as a placeholder', () {
      expect(translate('en', 'Hello {a} and {b}', <String, Object?>{'a': '{b}', 'b': 2}), 'Hello {b} and 2');
    });

    test('A placeholder with no value stays', () {
      expect(translate('en', 'Hello {a}', <String, Object?>{'b': 1}), 'Hello {a}');
    });

    test('A value also changes to the language', () {
      expect(translate('th', '{label}!', <String, Object?>{'label': 'Language'}), 'ภาษา!');
    });

    test('A second translation of Thai text changes nothing', () {
      expect(_th(_th('Sign out')), _th('Sign out'));
    });
  });

  group('dates', () {
    test('Each format of the SQL and DateText', () {
      expect(_th('16 October 2026'), '16 ตุลาคม 2026');
      expect(_th('16 October 2026 : 10:00'), '16 ตุลาคม 2026 : 10:00');
      expect(_th('Fri 16 October 2026'), 'ศ. 16 ตุลาคม 2026');
      expect(_th('Friday 23 October 2026'), 'วันศุกร์ 23 ตุลาคม 2026');
      expect(_th('Mon 09:00'), 'จ. 09:00');
      expect(_th('Fri 16 Oct - 10:00'), 'ศ. 16 ต.ค. - 10:00');
      expect(_th('16 / 10 / 2026 : 10:00'), '16 / 10 / 2026 : 10:00');
    });

    test('A name that is not next to a number stays', () {
      expect(_th('May'), 'May');
      expect(_th('Sun Mon'), 'Sun Mon');
      expect(_th('May 2026'), 'May 2026');
    });

    test('English dates stay', () {
      expect(translate('en', 'Fri 16 October 2026'), 'Fri 16 October 2026');
    });
  });

  group('server text', () {
    test('Status values and fixed values', () {
      expect(_th('Covered'), 'ได้รับความคุ้มครอง');
      expect(_th('SSO Rehabilitation Center'), 'ศูนย์ฟื้นฟูผู้ป่วย สำนักงานประกันสังคม');
    });

    test('A stored message of each query', () {
      const Map<String, String> messages = <String, String>{
        // O2.
        'Your claim SST-2026-000143 is covered under Section 33.':
            'คำร้อง SST-2026-000143 ของคุณได้รับความคุ้มครองตามมาตรา 33',
        // QN.3.
        'Your appointment with นพ. ธนา ศรีสุข is on 16 October 2026 : 10:00 at Building A, Floor 3, Room 305. '
                'Please confirm it in the application by 14 October 2026 : 10:00.':
            'คุณมีนัดหมายกับ นพ. ธนา ศรีสุข วันที่ 16 ตุลาคม 2026 : 10:00 ที่ อาคาร A ชั้น 3 ห้อง 305 '
                'กรุณายืนยันในแอปพลิเคชันภายใน 14 ตุลาคม 2026 : 10:00',
        'นาย สมชาย ประเสริฐ (claim SST-2026-000143) is booked with you on 16 October 2026 : 10:00 at Building A, '
                'Floor 3, Room 305. Waiting for the patient to confirm.':
            'นาย สมชาย ประเสริฐ (คำร้อง SST-2026-000143) มีนัดหมายกับคุณวันที่ 16 ตุลาคม 2026 : 10:00 '
                'ที่ อาคาร A ชั้น 3 ห้อง 305 กำลังรอผู้ป่วยยืนยัน',
        // QN.4.
        'The consultation report for your claim SST-2026-000147 says no treatment is required, so your claim is now closed.':
            'รายงานการปรึกษาของคำร้อง SST-2026-000147 ระบุว่าไม่ต้องรับการรักษา คำร้องของคุณจึงปิดแล้ว',
        // QN.5.
        'นาย สมชาย ประเสริฐ (claim SST-2026-000143) cannot attend the appointment on 16 October 2026 : 10:00. '
                'The appointment is cancelled and the claim is withdrawn.':
            'นาย สมชาย ประเสริฐ (คำร้อง SST-2026-000143) ไม่สามารถเข้าร่วมนัดหมายวันที่ 16 ตุลาคม 2026 : 10:00 '
                'นัดหมายจึงถูกยกเลิกและคำร้องถูกถอน',
        'นาย สมชาย ประเสริฐ (claim SST-2026-000143) moved the appointment to 20 October 2026 : 09:00 at Building A, Floor 3, Room 305.':
            'นาย สมชาย ประเสริฐ (คำร้อง SST-2026-000143) เปลี่ยนนัดหมายเป็นวันที่ 20 ตุลาคม 2026 : 09:00 ที่ อาคาร A ชั้น 3 ห้อง 305',
        'นาย สมชาย ประเสริฐ (claim SST-2026-000143) confirmed the appointment on 20 October 2026 : 09:00 at Building A, Floor 3, Room 305.':
            'นาย สมชาย ประเสริฐ (คำร้อง SST-2026-000143) ยืนยันนัดหมายวันที่ 20 ตุลาคม 2026 : 09:00 ที่ อาคาร A ชั้น 3 ห้อง 305',
        // O5.1.
        'Physiotherapy on 23 October 2026 : 13:00. Please accept or choose another date.':
            'กายภาพบำบัด วันที่ 23 ตุลาคม 2026 : 13:00 กรุณายอมรับหรือเลือกวันอื่น',
        // QU4.3.
        'Your treatment at SSO Rehabilitation Center on 19 October 2026 was cancelled because it was not accepted in time. '
                'Your claim SST-2026-000149 is now closed.':
            'การรักษาที่ ศูนย์ฟื้นฟูผู้ป่วย สำนักงานประกันสังคม วันที่ 19 ตุลาคม 2026 ถูกยกเลิก เพราะไม่ได้ยอมรับภายในกำหนด '
                'คำร้อง SST-2026-000149 ของคุณจึงปิดแล้ว',
      };
      messages.forEach((String english, String thai) => expect(_th(english), thai));
    });

    test('A stored message stays in English mode', () {
      const String text = 'Your claim SST-2026-000143 is covered under Section 33.';
      expect(translate('en', text), text);
    });

    test('Errors with a value', () {
      expect(_th('Use 255 characters or fewer.'), 'ใช้ไม่เกิน 255 ตัวอักษร');
      expect(_th('Error 500'), 'ข้อผิดพลาด 500');
    });

    test('The fixed category of an injury changes, and the typed body part stays', () {
      expect(_th('Fracture, right wrist'), 'กระดูกหัก, right wrist');
      expect(_th('Back strain, หลังส่วนล่าง'), 'กล้ามเนื้อหลังบาดเจ็บ, หลังส่วนล่าง');
    });
  });

  group('fixed Thai data in English mode', () {
    test('A rejection reason shows in English', () {
      expect(translate('en', 'ส่งเงินสมทบไม่ครบตามเงื่อนไข'), 'Contributions do not meet the conditions');
    });

    test('The same text stays Thai in Thai mode', () {
      expect(_th('ส่งเงินสมทบไม่ครบตามเงื่อนไข'), 'ส่งเงินสมทบไม่ครบตามเงื่อนไข');
    });
  });
}
