import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../use-cases/uc_01_submit_injury_application.dart';
import '../use-cases/uc_02_verify_section_33_eligibility.dart';
import '../use-cases/uc_03_reject_application.dart';
import '../use-cases/uc_04_schedule_appointment.dart';
import '../use-cases/uc_05_confirm_appointment.dart';
import '../use-cases/uc_06_confirm_appointment_by_phone.dart';
import '../use-cases/uc_07_reschedule_appointment.dart';
import '../use-cases/uc_08_arrange_consultation.dart';
import '../use-cases/uc_09_conduct_consultation.dart';
import '../use-cases/uc_10_generate_consultation_report.dart';
import '../use-cases/uc_11_schedule_treatment.dart';
import 'repository_providers.dart';

/// One provider for each of the 11 use cases.
///
/// Both entry points link this file. The patient application calls UC-01,
/// UC-03 and UC-05. The console calls the rest.

final Provider<SubmitInjuryApplication> submitInjuryApplicationProvider =
    Provider<SubmitInjuryApplication>(
      (Ref ref) => SubmitInjuryApplication(
        claims: ref.watch(claimRepositoryProvider),
        notices: ref.watch(noticeRepositoryProvider),
        clock: ref.watch(clockProvider),
      ),
    );

final Provider<RejectApplication> rejectApplicationProvider =
    Provider<RejectApplication>(
      (Ref ref) => RejectApplication(
        claims: ref.watch(claimRepositoryProvider),
        notices: ref.watch(noticeRepositoryProvider),
        clock: ref.watch(clockProvider),
      ),
    );

final Provider<ConfirmAppointment> confirmAppointmentProvider =
    Provider<ConfirmAppointment>(
      (Ref ref) => ConfirmAppointment(
        scheduling: ref.watch(schedulingRepositoryProvider),
        claims: ref.watch(claimRepositoryProvider),
        notices: ref.watch(noticeRepositoryProvider),
        clock: ref.watch(clockProvider),
      ),
    );

// --- The console drives these ---

final Provider<VerifySection33Eligibility> verifyEligibilityProvider =
    Provider<VerifySection33Eligibility>(
      (Ref ref) => VerifySection33Eligibility(
        claims: ref.watch(claimRepositoryProvider),
        register: ref.watch(insuredRegisterRepositoryProvider),
        notices: ref.watch(noticeRepositoryProvider),
        clock: ref.watch(clockProvider),
      ),
    );

final Provider<ScheduleAppointment> scheduleAppointmentProvider =
    Provider<ScheduleAppointment>(
      (Ref ref) => ScheduleAppointment(
        scheduling: ref.watch(schedulingRepositoryProvider),
        claims: ref.watch(claimRepositoryProvider),
        notices: ref.watch(noticeRepositoryProvider),
        clock: ref.watch(clockProvider),
      ),
    );

final Provider<ConfirmAppointmentByPhone> confirmByPhoneProvider =
    Provider<ConfirmAppointmentByPhone>(
      (Ref ref) => ConfirmAppointmentByPhone(
        scheduling: ref.watch(schedulingRepositoryProvider),
        claims: ref.watch(claimRepositoryProvider),
        clock: ref.watch(clockProvider),
      ),
    );

final Provider<RescheduleAppointment> rescheduleAppointmentProvider =
    Provider<RescheduleAppointment>(
      (Ref ref) => RescheduleAppointment(
        scheduling: ref.watch(schedulingRepositoryProvider),
        notices: ref.watch(noticeRepositoryProvider),
        clock: ref.watch(clockProvider),
      ),
    );

final Provider<ArrangeConsultation> arrangeConsultationProvider =
    Provider<ArrangeConsultation>(
      (Ref ref) => ArrangeConsultation(
        consultation: ref.watch(consultationRepositoryProvider),
        scheduling: ref.watch(schedulingRepositoryProvider),
        notices: ref.watch(noticeRepositoryProvider),
        clock: ref.watch(clockProvider),
      ),
    );

final Provider<GenerateConsultationReport> generateReportProvider =
    Provider<GenerateConsultationReport>(
      (Ref ref) => GenerateConsultationReport(
        consultation: ref.watch(consultationRepositoryProvider),
        claims: ref.watch(claimRepositoryProvider),
        notices: ref.watch(noticeRepositoryProvider),
        clock: ref.watch(clockProvider),
      ),
    );

final Provider<ConductConsultation> conductConsultationProvider =
    Provider<ConductConsultation>(
      (Ref ref) => ConductConsultation(
        consultation: ref.watch(consultationRepositoryProvider),
        claims: ref.watch(claimRepositoryProvider),
        generateReport: ref.watch(generateReportProvider),
        clock: ref.watch(clockProvider),
      ),
    );

final Provider<ScheduleTreatment> scheduleTreatmentProvider =
    Provider<ScheduleTreatment>(
      (Ref ref) => ScheduleTreatment(
        scheduling: ref.watch(schedulingRepositoryProvider),
        claims: ref.watch(claimRepositoryProvider),
        notices: ref.watch(noticeRepositoryProvider),
        clock: ref.watch(clockProvider),
      ),
    );
