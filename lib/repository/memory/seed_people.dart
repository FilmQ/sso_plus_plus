import '../../models/appointment_slot.dart';
import '../../models/consultant.dart';
import '../../models/insured_person.dart';
import '../../models/staff_member.dart';

/// The people, the staff, the consultants and their free slots.
///
/// `SeedData` holds the claims of the patient. `SeedConsole` holds the claims
/// that fill the officer and consultant worklists. This file holds what both
/// of them point at.
abstract final class SeedPeople {
  /// The moment at which the demonstration starts.
  ///
  /// A fixed time keeps the demonstration the same at every run. Both
  /// surfaces start here, so their seeded data agrees.
  static final DateTime demoStart = DateTime(2026, 9, 14, 9, 0);

  static const String facility = 'Bangkok Rehabilitation Centre';
  static const String register = 'SSO insured register';

  // --- Staff ---

  static const StaffMember officer = StaffMember(
    id: 'STF-001',
    name: 'P. Chaiyaporn',
    role: StaffRole.evaluationOfficer,
    office: 'Bangkok 3',
  );

  static const StaffMember consultantStaff = StaffMember(
    id: 'STF-002',
    name: 'Dr. Anong Wattana',
    role: StaffRole.consultant,
    office: 'Bangkok 3',
    consultantId: 'CON-001',
  );

  static const List<StaffMember> staff = <StaffMember>[
    officer,
    consultantStaff,
  ];

  // --- Consultants ---

  static const Consultant anong = Consultant(
    id: 'CON-001',
    name: 'Dr. Anong Wattana',
    specialty: 'Orthopaedics',
    facility: facility,
    area: 'Bangkok 3',
  );

  static const List<Consultant> consultants = <Consultant>[
    anong,
    Consultant(
      id: 'CON-002',
      name: 'Dr. Surasak Kittipong',
      specialty: 'Orthopaedics',
      facility: 'Prachahai Hospital',
      area: 'Prachahai',
    ),
    Consultant(
      id: 'CON-003',
      name: 'Dr. Nipa Pongsri',
      specialty: 'Orthopaedics',
      facility: 'Dindaeng Clinic',
      area: 'Dindaeng',
    ),
    Consultant(
      id: 'CON-004',
      name: 'Dr. Prasit Meechai',
      specialty: 'General surgery',
      facility: facility,
      area: 'Bangkok 3',
    ),
  ];

  // --- Insured people ---

  static const InsuredPerson patient = InsuredPerson(
    id: 'USR-001',
    fullName: 'Somchai Prasert',
    nationalId: '1100967890451',
    employer: 'Siam Logistics Co., Ltd.',
    telephone: '081-234-4471',
  );

  static const List<InsuredPerson> people = <InsuredPerson>[
    patient,
    InsuredPerson(
      id: 'USR-002',
      fullName: 'Malee Srisuk',
      nationalId: '1100912345672',
      employer: 'Thai Steel Works',
      telephone: '081-555-2201',
    ),
    InsuredPerson(
      id: 'USR-003',
      fullName: 'Anan Chaisiri',
      nationalId: '1100923456783',
      employer: 'P.N. Foods',
      telephone: '081-555-3312',
    ),
    InsuredPerson(
      id: 'USR-004',
      fullName: 'Wichai Thongdee',
      nationalId: '1100934567894',
      employer: 'BKK Metro',
      telephone: '081-555-4423',
    ),
    InsuredPerson(
      id: 'USR-005',
      fullName: 'Pranee Kaewsai',
      nationalId: '1100945678905',
      employer: 'Nova Textile',
      telephone: '081-555-5534',
    ),
    InsuredPerson(
      id: 'USR-006',
      fullName: 'Kanya Bootnil',
      nationalId: '1100956789016',
      employer: 'Siam Logistics Co., Ltd.',
      telephone: '081-555-6645',
    ),
    InsuredPerson(
      id: 'USR-007',
      fullName: 'Decha Rattana',
      nationalId: '1100967890127',
      employer: 'BKK Metro',
      telephone: '081-555-7756',
    ),
    InsuredPerson(
      id: 'USR-008',
      fullName: 'Urai Somsak',
      nationalId: '1100978901238',
      employer: 'Nova Textile',
      telephone: '081-555-8867',
    ),
    InsuredPerson(
      id: 'USR-009',
      fullName: 'Chaiwat Boonmee',
      nationalId: '1100989012349',
      employer: 'Thai Steel Works',
      telephone: '081-555-9978',
    ),
    InsuredPerson(
      id: 'USR-010',
      fullName: 'Ratana Pimsen',
      nationalId: '1100990123450',
      employer: 'P.N. Foods',
      telephone: '081-555-1089',
    ),
    InsuredPerson(
      id: 'USR-011',
      fullName: 'Thida Wong',
      nationalId: '1100901234561',
      employer: 'Siam Logistics Co., Ltd.',
      telephone: '081-555-2190',
    ),
    InsuredPerson(
      id: 'USR-012',
      fullName: 'Narong Sae-lim',
      nationalId: '1100912345673',
      employer: 'BKK Metro',
      telephone: '081-555-3201',
    ),
  ];

  /// The free slots that screen D3 offers.
  ///
  /// The design shows one week, `14 – 18 Sep`, for three orthopaedic
  /// consultants.
  static List<AppointmentSlot> slots() {
    final List<AppointmentSlot> made = <AppointmentSlot>[];

    void add(String consultantId, int day, int hour, int minute) {
      final DateTime start = DateTime(2026, 9, day, hour, minute);
      made.add(
        AppointmentSlot(
          id: 'SLT-$consultantId-$day-$hour$minute',
          consultantId: consultantId,
          start: start,
          end: start.add(const Duration(minutes: 30)),
          facility: consultants
              .firstWhere((Consultant c) => c.id == consultantId)
              .facility,
          room: 'Room 4, 2nd floor',
        ),
      );
    }

    // Dr. Anong Wattana
    add('CON-001', 14, 9, 0);
    add('CON-001', 15, 11, 0);
    add('CON-001', 17, 14, 30);
    add('CON-001', 18, 10, 30);
    add('CON-001', 18, 15, 0);

    // Dr. Surasak Kittipong
    add('CON-002', 14, 13, 0);
    add('CON-002', 16, 9, 30);
    add('CON-002', 16, 16, 0);
    add('CON-002', 18, 8, 0);

    // Dr. Nipa Pongsri
    add('CON-003', 15, 9, 0);
    add('CON-003', 17, 10, 0);
    add('CON-003', 18, 13, 30);

    return made;
  }

  /// The treatment slots that screen D8 offers, `21 – 25 Sep`.
  static List<AppointmentSlot> treatmentSlots() {
    final List<AppointmentSlot> made = <AppointmentSlot>[];

    void add(int day, int hour, int minute) {
      final DateTime start = DateTime(2026, 9, day, hour, minute);
      made.add(
        AppointmentSlot(
          id: 'TRT-$day-$hour$minute',
          consultantId: 'CON-001',
          start: start,
          end: start.add(const Duration(minutes: 60)),
          facility: facility,
          room: 'Physiotherapy unit, 3rd floor',
          isTreatment: true,
        ),
      );
    }

    add(21, 9, 0);
    add(21, 13, 0);
    add(22, 8, 30);
    add(22, 15, 0);
    add(23, 10, 0);
    add(24, 9, 30);
    add(24, 14, 0);
    add(25, 11, 0);

    return made;
  }
}
