import 'package:flutter/material.dart';

import '../../models/staff_member.dart';
import 'console_destination.dart';

/// The extended navigation rail of the console.
///
/// It shows the work of the officer and the work of the consultant at the
/// same time, as the design does. The person at the foot is the identity
/// that every decision is recorded against.
class ConsoleRail extends StatelessWidget {
  const ConsoleRail({
    super.key,
    required this.groups,
    required this.currentRoute,
    required this.onSelect,
    required this.staff,
    this.onChangeStaff,
  });

  final List<ConsoleGroup> groups;
  final String currentRoute;
  final void Function(String route) onSelect;
  final StaffMember staff;
  final VoidCallback? onChangeStaff;

  static const double width = 232;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        border: Border(right: BorderSide(color: colors.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _Brand(colors: colors, theme: theme),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 8),
              children: <Widget>[
                for (final ConsoleGroup group in groups) ...<Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
                    child: Text(
                      group.label.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  for (final ConsoleDestination destination
                      in group.destinations)
                    _RailTile(
                      destination: destination,
                      selected: currentRoute.startsWith(destination.route),
                      onTap: () => onSelect(destination.route),
                    ),
                ],
              ],
            ),
          ),
          Divider(height: 1, color: colors.outlineVariant),
          _StaffCard(staff: staff, onChange: onChangeStaff),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.colors, required this.theme});

  final ColorScheme colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Row(
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              Icons.health_and_safety_outlined,
              size: 20,
              color: colors.onPrimary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'SST Console',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Social Security Office',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RailTile extends StatelessWidget {
  const _RailTile({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final ConsoleDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: selected ? colors.secondaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: <Widget>[
                Icon(
                  destination.icon,
                  size: 20,
                  color: selected
                      ? colors.onSecondaryContainer
                      : colors.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    destination.label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: selected
                          ? colors.onSecondaryContainer
                          : colors.onSurface,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
                if (destination.count > 0)
                  Text(
                    '${destination.count}',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  const _StaffCard({required this.staff, this.onChange});

  final StaffMember staff;
  final VoidCallback? onChange;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 16),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 17,
            backgroundColor: colors.primaryContainer,
            child: Text(
              staff.initials,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(staff.name, style: theme.textTheme.bodyMedium),
                Text(
                  '${staff.role.label} · ${staff.office}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 18),
            tooltip: 'Change the member of staff',
            onPressed: onChange,
          ),
        ],
      ),
    );
  }
}
