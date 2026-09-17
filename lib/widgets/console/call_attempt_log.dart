import 'package:flutter/material.dart';

import '../../models/contact_attempt.dart';
import '../shared/formats.dart';

/// The record of the calls made against one appointment.
///
/// BR-17 permits a fixed number of attempts, on different days and at
/// different times of day. Every attempt is logged, answered or not.
class CallAttemptLog extends StatelessWidget {
  const CallAttemptLog({
    super.key,
    required this.attempts,
    required this.allowed,
  });

  final List<ContactAttempt> attempts;
  final int allowed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    if (attempts.isEmpty) {
      return Text(
        'No call has been made yet.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: colors.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int i = 0; i < attempts.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == attempts.length - 1 ? 0 : 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  attempts[i].outcome == AttemptOutcome.answered
                      ? Icons.phone_in_talk_outlined
                      : Icons.phone_missed_outlined,
                  size: 16,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Attempt ${i + 1} of $allowed · '
                        '${Formats.dateAndTime(attempts[i].at)}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        attempts[i].note.isEmpty
                            ? attempts[i].outcome.label
                            : attempts[i].note,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
