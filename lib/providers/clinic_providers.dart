import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/claim.dart';
import '../models/claim_status.dart';
import '../models/consultation_report.dart';
import '../models/consultation_session.dart';
import 'repository_providers.dart';
import 'staff_provider.dart';

/// The sessions of the consultant who is signed in (D6).
///
/// BR-22 is enforced in the repository, so an officer who opens this screen
/// sees nothing rather than another consultant's caseload.
final FutureProvider<List<ConsultationSession>> sessionQueueProvider =
    FutureProvider<List<ConsultationSession>>((Ref ref) async {
      final String? consultantId = ref.watch(currentConsultantIdProvider);
      if (consultantId == null) {
        return <ConsultationSession>[];
      }
      final List<ConsultationSession> mine = await ref
          .watch(consultationRepositoryProvider)
          .sessionsForConsultant(consultantId);
      return mine
          .where(
            (ConsultationSession s) =>
                s.status == SessionStatus.prepared ||
                s.status == SessionStatus.inProgress,
          )
          .toList();
    });

/// One session by its identifier.
final sessionProvider = FutureProvider.family<ConsultationSession?, String>((
  Ref ref,
  String id,
) async {
  return ref.watch(consultationRepositoryProvider).sessionById(id);
});

/// The reports of the consultant that wait for a signature (D7).
final FutureProvider<List<ConsultationReport>> reportQueueProvider =
    FutureProvider<List<ConsultationReport>>((Ref ref) async {
      final String? consultantId = ref.watch(currentConsultantIdProvider);
      if (consultantId == null) {
        return <ConsultationReport>[];
      }
      return ref
          .watch(consultationRepositoryProvider)
          .unsignedFor(consultantId);
    });

/// One report by its identifier.
final reportProvider = FutureProvider.family<ConsultationReport?, String>((
  Ref ref,
  String id,
) async {
  return ref.watch(consultationRepositoryProvider).byId(id);
});

/// The signed reports whose claim still has no treatment date (D8).
final FutureProvider<List<ConsultationReport>> treatmentQueueProvider =
    FutureProvider<List<ConsultationReport>>((Ref ref) async {
      final List<Claim> signed = await ref
          .watch(claimRepositoryProvider)
          .byStatuses(<ClaimStatus>{ClaimStatus.reportSigned});

      final consultation = ref.watch(consultationRepositoryProvider);
      final List<ConsultationReport> waiting = <ConsultationReport>[];
      for (final Claim claim in signed) {
        final ConsultationReport? report = await consultation.latestSigned(
          claim.claimNumber,
        );
        // BR-31: a treatment must come from a signed report.
        // UC-11 (1a): a report that needs no treatment is not in this queue.
        if (report != null && report.treatmentRequired) {
          waiting.add(report);
        }
      }
      return waiting;
    });
