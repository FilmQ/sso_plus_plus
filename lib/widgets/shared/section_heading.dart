import 'package:flutter/material.dart';

/// The small heading above a group of cards.
///
/// The design uses `titleSmall` for "Claim progress", "What happens next",
/// "Before you go" and the other group headings.
class SectionHeading extends StatelessWidget {
  const SectionHeading(this.text, {super.key, this.trailing});

  final String text;

  /// An optional widget at the right end of the heading.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
