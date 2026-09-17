import 'package:flutter/material.dart';

/// One entry in the console rail.
class ConsoleDestination {
  const ConsoleDestination({
    required this.label,
    required this.icon,
    required this.route,
    this.count = 0,
  });

  final String label;
  final IconData icon;

  /// The route that this entry opens.
  final String route;

  /// The number that the rail shows at the right of the label.
  final int count;

  ConsoleDestination withCount(int value) =>
      ConsoleDestination(label: label, icon: icon, route: route, count: value);
}

/// One labelled group of entries, for example `EVALUATION OFFICER`.
class ConsoleGroup {
  const ConsoleGroup({required this.label, required this.destinations});

  final String label;
  final List<ConsoleDestination> destinations;
}

/// The groups that the rail shows.
///
/// The design shows both groups at all times. The member of staff who is
/// signed in does not hide a group. Section 7.2 of IMPLEMENTATION.md records
/// that decision, and BR-22 is enforced in the repository instead.
abstract final class ConsoleDestinations {
  static const List<ConsoleDestination> officer = <ConsoleDestination>[
    ConsoleDestination(
      label: 'Verification',
      icon: Icons.fact_check_outlined,
      route: '/officer/verification',
    ),
    ConsoleDestination(
      label: 'Scheduling',
      icon: Icons.event_available_outlined,
      route: '/officer/scheduling',
    ),
    ConsoleDestination(
      label: 'Confirmations',
      icon: Icons.call_outlined,
      route: '/officer/confirmations',
    ),
    ConsoleDestination(
      label: 'Consultations',
      icon: Icons.assignment_outlined,
      route: '/officer/consultations',
    ),
  ];

  static const List<ConsoleDestination> clinic = <ConsoleDestination>[
    ConsoleDestination(
      label: 'Sessions',
      icon: Icons.medical_information_outlined,
      route: '/clinic/sessions',
    ),
    ConsoleDestination(
      label: 'Reports',
      icon: Icons.description_outlined,
      route: '/clinic/reports',
    ),
    ConsoleDestination(
      label: 'Treatment',
      icon: Icons.healing_outlined,
      route: '/clinic/treatment',
    ),
  ];
}
