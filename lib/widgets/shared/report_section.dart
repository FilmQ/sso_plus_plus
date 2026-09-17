import 'package:flutter/material.dart';

/// One part of a consultation report: a heading and its text.
///
/// Screen M8 shows Findings, Diagnosis and Recommended treatment with this
/// widget. The consultant form on the console shows the same parts.
class ReportSection extends StatelessWidget {
  const ReportSection({
    super.key,
    required this.heading,
    required this.body,
    this.isLast = false,
  });

  final String heading;
  final String body;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            heading,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(body, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
