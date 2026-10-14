import 'package:flutter_test/flutter_test.dart';
import 'package:sso_plus_plus/legacy/models/appointment.dart';
import 'package:sso_plus_plus/legacy/models/appointment_slot.dart';
import 'package:sso_plus_plus/legacy/models/claim_status.dart';
import 'package:sso_plus_plus/legacy/models/consultation_report.dart';
import 'package:sso_plus_plus/legacy/use-cases/uc_11_schedule_treatment.dart';

import '../support/test_context.dart';

void main() {
  late TestContext context;
  late ScheduleTreatment useCase;

  setUp(() {
    context = TestContext();
    useCase = ScheduleTreatment(
      scheduling: context.scheduling,
      claims: context.claims,
      notices: context.notices,
      clock: context.clock,
    );
  });

  /// The seeded report that is signed and has no treatment date.
  Future<ConsultationReport> signed() async =>
      (await context.consultation.byId('RPT-0088-1'))!;

  /// The seeded report that nobody has signed.
  Future<ConsultationReport> draft() async =>
      (await context.consultation.byId('RPT-0108-1'))!;

  test('books the date and writes it to the claimant at once', () async {
    final AppointmentSlot slot = (await useCase.slots()).first;

    final TreatmentResult result = await useCase.book(
      report: await signed(),
      slot: slot,
      treatmentType: 'Cast immobilisation and review',
    );

    expect(result, isA<TreatmentBooked>());
    final Appointment made = (result as TreatmentBooked).appointment;

    expect(made.kind, AppointmentKind.treatment);
    // BR-31: the treatment is traceable to the report it came from.
    expect(made.reportId, 'RPT-0088-1');
    expect(made.start, slot.start);

    expect(
      (await context.claims.byNumber('CLM-2569-0088'))?.status,
      ClaimStatus.treatmentScheduled,
    );

    // BR-32: the date reaches the claimant with no step by hand.
    final notices = await context.notices.forPerson('USR-006');
    expect(notices.first.title, 'Treatment booked');
  });

  test('UC-11 3a: the confirmation cycle of UC-05 applies here too', () async {
    final AppointmentSlot slot = (await useCase.slots()).first;
    final TreatmentResult result = await useCase.book(
      report: await signed(),
      slot: slot,
      treatmentType: 'Cast immobilisation and review',
    );

    final Appointment made = (result as TreatmentBooked).appointment;
    expect(made.status, AppointmentStatus.awaitingConfirmation);
    expect(made.needsReply, isTrue);
  });

  test('BR-31: a treatment cannot come from an unsigned report', () async {
    final TreatmentResult result = await useCase.book(
      report: await draft(),
      slot: (await useCase.slots()).first,
      treatmentType: 'Physiotherapy',
    );

    expect(result, isA<ReportNotSigned>());
  });

  test('refuses a slot that somebody else took', () async {
    final AppointmentSlot slot = (await useCase.slots()).first;
    await context.scheduling.saveSlot(
      slot.copyWith(state: SlotState.booked, heldForClaim: 'CLM-2569-0001'),
    );

    final TreatmentResult result = await useCase.book(
      report: await signed(),
      slot: slot,
      treatmentType: 'Cast immobilisation and review',
    );

    expect(result, isA<TreatmentSlotTaken>());
  });

  test('flow 1a: "no treatment required" closes the claim', () async {
    final TreatmentResult result = await useCase.recordNoTreatment(
      await signed(),
    );

    expect(result, isA<NoTreatmentRequired>());
    expect(
      (await context.claims.byNumber('CLM-2569-0088'))?.status,
      ClaimStatus.closed,
    );
  });

  test('BR-33: nothing is booked for a claim that is closed', () async {
    // Close the claim first.
    await useCase.recordNoTreatment(await signed());

    final TreatmentResult result = await useCase.book(
      report: await signed(),
      slot: (await useCase.slots()).first,
      treatmentType: 'Cast immobilisation and review',
    );

    expect(result, isA<ClaimNotOpen>());
  });
}
