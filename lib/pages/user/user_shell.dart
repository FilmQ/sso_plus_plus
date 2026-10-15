import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'notifications/notification_providers.dart';

/// The navigation bar of the user app (U2-1): Home, Schedule, Notifications,
/// Profile. The Notifications destination has the red dot of U3.1 step 1 (Q3.1).
class UserShell extends ConsumerWidget {
  const UserShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool unread = (ref.watch(unreadOnNotificationPageProvider).value ?? 0) > 0;
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: (int i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
        destinations: <NavigationDestination>[
          const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          const NavigationDestination(icon: Icon(Icons.event_outlined), selectedIcon: Icon(Icons.event), label: 'Schedule'),
          NavigationDestination(
            icon: Badge(
                key: const Key('notifications_dot'),
                isLabelVisible: unread,
                smallSize: 8,
                child: const Icon(Icons.notifications_outlined)),
            selectedIcon: Badge(isLabelVisible: unread, smallSize: 8, child: const Icon(Icons.notifications)),
            label: 'Notifications',
          ),
          const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
