import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../widgets/console/console_destination.dart';
import 'clinic_providers.dart';
import 'officer_providers.dart';

/// The seven numbers that the console rail shows.
///
/// Open point 5 of IMPLEMENTATION.md records that the deck names no source
/// for these figures. Each one counts the rows of the screen it points at,
/// so the rail and the screen always agree.
final FutureProvider<Map<String, int>> railCountsProvider =
    FutureProvider<Map<String, int>>((Ref ref) async {
      final verification = await ref.watch(verificationWorklistProvider.future);
      final scheduling = await ref.watch(schedulingWorklistProvider.future);
      final confirmations = await ref.watch(unconfirmedWorklistProvider.future);
      final consultations = await ref.watch(
        consultationWorklistProvider.future,
      );
      final sessions = await ref.watch(sessionQueueProvider.future);
      final reports = await ref.watch(reportQueueProvider.future);
      final treatment = await ref.watch(treatmentQueueProvider.future);

      return <String, int>{
        '/officer/verification': verification.length,
        '/officer/scheduling': scheduling.length,
        '/officer/confirmations': confirmations.length,
        '/officer/consultations': consultations.length,
        '/clinic/sessions': sessions.length,
        '/clinic/reports': reports.length,
        '/clinic/treatment': treatment.length,
      };
    });

/// The rail groups, with their counts filled in.
final FutureProvider<List<ConsoleGroup>> consoleGroupsProvider =
    FutureProvider<List<ConsoleGroup>>((Ref ref) async {
      final Map<String, int> counts = await ref.watch(
        railCountsProvider.future,
      );

      List<ConsoleDestination> withCounts(List<ConsoleDestination> source) {
        return source
            .map((ConsoleDestination d) => d.withCount(counts[d.route] ?? 0))
            .toList();
      }

      return <ConsoleGroup>[
        ConsoleGroup(
          label: 'Evaluation Officer',
          destinations: withCounts(ConsoleDestinations.officer),
        ),
        ConsoleGroup(
          label: 'Consultant',
          destinations: withCounts(ConsoleDestinations.clinic),
        ),
      ];
    });
