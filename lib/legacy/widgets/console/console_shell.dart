import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/staff_member.dart';
import '../../providers/rail_counts_provider.dart';
import '../../providers/staff_provider.dart';
import 'console_destination.dart';
import 'console_rail.dart';

/// The frame of the console: the rail, and the screen beside it.
///
/// The console is a desktop web surface. It builds one layout and assumes a
/// window of 1024 pixels or more, as section 7.2 of IMPLEMENTATION.md says.
class ConsoleShell extends ConsumerWidget {
  const ConsoleShell({super.key, required this.child});

  final Widget child;

  /// The console does not adapt below this width. It scrolls sideways.
  static const double minimumWidth = 1024;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<ConsoleGroup>> groups = ref.watch(
      consoleGroupsProvider,
    );
    final StaffMember staff = ref.watch(currentStaffProvider);
    final String location = GoRouterState.of(context).uri.path;

    return Scaffold(
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final Widget frame = Row(
            children: <Widget>[
              ConsoleRail(
                groups: groups.value ?? _emptyGroups,
                currentRoute: location,
                onSelect: (String route) => context.go(route),
                staff: staff,
                onChangeStaff: () => _changeStaff(context, ref, staff),
              ),
              Expanded(child: child),
            ],
          );

          if (constraints.maxWidth >= minimumWidth) {
            return frame;
          }
          // A narrow window is not a supported case. The console keeps its
          // width and the page scrolls sideways.
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: minimumWidth,
              height: constraints.maxHeight,
              child: frame,
            ),
          );
        },
      ),
    );
  }

  static const List<ConsoleGroup> _emptyGroups = <ConsoleGroup>[
    ConsoleGroup(
      label: 'Evaluation Officer',
      destinations: ConsoleDestinations.officer,
    ),
    ConsoleGroup(label: 'Consultant', destinations: ConsoleDestinations.clinic),
  ];

  /// One console serves two roles, so a demonstration must change the person
  /// who is signed in. The identity is what every record carries.
  Future<void> _changeStaff(
    BuildContext context,
    WidgetRef ref,
    StaffMember current,
  ) async {
    final List<StaffMember> everybody = ref.read(staffListProvider);

    final StaffMember? chosen = await showDialog<StaffMember>(
      context: context,
      builder: (BuildContext context) => SimpleDialog(
        title: const Text('Who is signed in?'),
        children: <Widget>[
          for (final StaffMember member in everybody)
            SimpleDialogOption(
              onPressed: () => Navigator.of(context).pop(member),
              child: ListTile(
                leading: CircleAvatar(child: Text(member.initials)),
                title: Text(member.name),
                subtitle: Text('${member.role.label} · ${member.office}'),
                trailing: member.id == current.id
                    ? const Icon(Icons.check)
                    : null,
              ),
            ),
        ],
      ),
    );

    if (chosen != null) {
      ref.read(currentStaffProvider.notifier).change(chosen);
    }
  }
}
