import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../session/session_providers.dart';
import '../../../session/user_session.dart';
import '../../../widgets/app_logo.dart';
import '../../../widgets/person_avatar.dart';
import '../scheduling/scheduling_providers.dart';
import '../treatment/treatment_providers.dart';
import '../verification/verification_providers.dart';

/// One destination of the officer navigation (Figma O1-1, left side).
class ConsoleDestination {
  const ConsoleDestination(this.label, this.icon, this.path);

  final String label;
  final IconData icon;
  final String path;
}

/// The officer pages (site map: diagrams/sitemap-officer.png).
const List<ConsoleDestination> officerDestinations = <ConsoleDestination>[
  ConsoleDestination('Verification', Icons.fact_check, '/verification'),
  ConsoleDestination('Scheduling', Icons.calendar_month, '/scheduling'),
  ConsoleDestination('Treatment', Icons.healing, '/treatment'),
  ConsoleDestination('Consultation Reports', Icons.description, '/reports'),
];

/// The left navigation of the console: the logo, the officer pages with
/// their counts, and the signed-in person with "Sign out".
class ConsoleNav extends ConsumerWidget {
  const ConsoleNav({super.key, required this.location});

  /// The current path, for the selected destination.
  final String location;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final UserSession? session = ref.watch(sessionProvider).value;
    // QO1.2: the number of claims that wait for verification.
    final Map<String, Object?>? counts = ref.watch(verificationListProvider).value?['counts'] as Map<String, Object?>?;
    final Object? awaiting = counts?['awaiting_verification'];
    // QO4.1: the number of claims ready to schedule.
    final int? toSchedule = ref.watch(claimsToScheduleProvider).value?.length;
    final Map<String, String?> navCounts = <String, String?>{
      '/verification': awaiting?.toString(),
      '/scheduling': toSchedule?.toString(),
      // QO5.1: the number of claims with a filed report.
      '/treatment': ref.watch(claimsForTreatmentProvider).value?.length.toString(),
    };
    return Container(
      width: 256,
      color: colors.surfaceContainerLow,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              child: Row(spacing: 12, children: <Widget>[
                const AppLogo(size: 40),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                    Text('SST Console', style: text.titleMedium, overflow: TextOverflow.ellipsis),
                    Text('Social Security Office', style: text.bodySmall, overflow: TextOverflow.ellipsis),
                  ]),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text('EVALUATION OFFICER', style: text.labelSmall?.copyWith(color: colors.onSurfaceVariant)),
            ),
            for (final ConsoleDestination d in officerDestinations)
              _NavItem(
                destination: d,
                selected: location.startsWith(d.path),
                count: navCounts[d.path],
              ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(spacing: 12, children: <Widget>[
                PersonAvatar(session?.displayName ?? ''),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                    Text(session?.displayName ?? '', style: text.titleSmall),
                    Text('Evaluation Officer', style: text.bodySmall),
                  ]),
                ),
                IconButton(
                  tooltip: 'Sign out',
                  icon: const Icon(Icons.logout),
                  onPressed: () => ref.read(sessionProvider.notifier).logout(),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.destination, required this.selected, this.count});

  final ConsoleDestination destination;
  final bool selected;
  final String? count;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final Color fg = selected ? colors.onSecondaryContainer : colors.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: selected ? colors.secondaryContainer : Colors.transparent,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            Scaffold.maybeOf(context)?.closeDrawer();
            context.go(destination.path);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(spacing: 12, children: <Widget>[
              Icon(destination.icon, color: fg),
              Expanded(
                child: Text(destination.label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(color: fg)),
              ),
              if (count != null) Text(count!, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg)),
            ]),
          ),
        ),
      ),
    );
  }
}
