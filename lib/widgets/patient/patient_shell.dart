import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/notice_providers.dart';

/// The frame that keeps the navigation bar while the branch changes.
///
/// The patient application runs on a phone only, so it builds one layout.
/// It has no navigation rail and no wide layout. Section 7.1 of
/// IMPLEMENTATION.md records that decision.
class PatientShell extends ConsumerWidget {
  const PatientShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<int> unread = ref.watch(unreadNoticeCountProvider);
    final int count = unread.value ?? 0;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _goToBranch,
        destinations: <Widget>[
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Claims',
          ),
          const NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event),
            label: 'Appointments',
          ),
          NavigationDestination(
            icon: Badge.count(
              count: count,
              isLabelVisible: count > 0,
              child: const Icon(Icons.inbox_outlined),
            ),
            selectedIcon: Badge.count(
              count: count,
              isLabelVisible: count > 0,
              child: const Icon(Icons.inbox),
            ),
            label: 'Inbox',
          ),
        ],
      ),
    );
  }

  /// Moves to a branch. A second tap on the same branch returns to its root.
  void _goToBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
