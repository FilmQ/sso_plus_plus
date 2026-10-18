import 'package:flutter/material.dart';

import '../../../theme/status_colors.dart';
import '../../../widgets/status_chip.dart';
import 'claim_cards.dart';

/// "Section 33 eligibility" (QO1.5) with [decision] under it: the form
/// before the decision, or the saved result after it (Figma O1-2 to O3-3).
class EligibilityPanel extends StatelessWidget {
  const EligibilityPanel({super.key, required this.eligibility, required this.decision});

  /// The QO1.5 row, or null when the claim has no automatic result.
  final Map<String, Object?>? eligibility;
  final Widget decision;

  @override
  Widget build(BuildContext context) {
    final Map<String, Object?>? e = eligibility;
    Widget line(IconData icon, String label, String value) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 12,
          children: <Widget>[
            Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Text(label, style: Theme.of(context).textTheme.titleSmall),
              Text(value, style: Theme.of(context).textTheme.bodySmall),
            ])),
          ],
        );
    return ConsoleCard(
      title: 'Section 33 eligibility',
      subtitle: 'Automatic result from the SSO insured register',
      trailing: e == null ? null : ClaimStatusChip('${e['eligibility_status']}'),
      children: <Widget>[
        if (e == null) const Text('There is no automatic result for this claim.'),
        if (e != null) ...<Widget>[
          line(Icons.history, 'Contribution period', '${e['contribution_period'] ?? '-'}'),
          line(
              Icons.domain,
              'Employer in register',
              e['employer_in_register'] == null
                  ? '-'
                  : '${e['employer_in_register']} · SSO account ${e['sso_account_no']}'),
          line(Icons.update, 'Register queried', '${e['register_queried'] ?? '-'}'),
        ],
        const Divider(height: 1),
        decision,
      ],
    );
  }
}

/// The saved result of O2-3 or O3-3: who decided and when, and the reason.
class DecisionResult extends StatelessWidget {
  const DecisionResult({super.key, required this.covered, required this.by, required this.at, this.reason});

  final bool covered;
  final String by;
  final String at;
  final String? reason;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final StatusColors s = StatusColors.of(context);
    final Color fg = covered ? s.success : colors.onErrorContainer;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: covered ? s.successContainer : colors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 8, children: <Widget>[
        Row(spacing: 12, children: <Widget>[
          Icon(covered ? Icons.check_circle : Icons.block, color: fg),
          Expanded(
            child: Text(covered ? 'Result confirmed: Covered' : 'Result confirmed: Not covered, claim rejected',
                style: Theme.of(context).textTheme.titleSmall),
          ),
        ]),
        Text('By $by · $at', style: Theme.of(context).textTheme.bodySmall),
        if (reason != null) Text('Reason: $reason', style: Theme.of(context).textTheme.bodySmall),
      ]),
    );
  }
}
