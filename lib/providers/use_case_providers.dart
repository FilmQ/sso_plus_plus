import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../use-cases/uc_01_submit_injury_application.dart';
import '../use-cases/uc_03_reject_application.dart';
import '../use-cases/uc_05_confirm_appointment.dart';
import 'repository_providers.dart';

/// One provider for each use case that the patient application drives.
///
/// UC-02, UC-04 and UC-06 to UC-11 belong to the officer and the consultant.
/// They arrive with the console in phases P4 and P5.

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
