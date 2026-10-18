import 'package:flutter/material.dart';

import '../../../theme/status_colors.dart';
import '../../../widgets/status_chip.dart';
import '../verification/claim_cards.dart';
import 'signature_dialog.dart';

/// The right side of the report page (Figma C2.1-1 to C2.3-2): "Signature
/// status", "Filing" and "Actions".
class ReportStatusCards extends StatelessWidget {
  const ReportStatusCards({
    super.key,
    required this.signed,
    required this.signedDate,
    required this.signature,
    required this.filed,
    required this.editing,
    required this.busy,
    required this.onAmend,
    required this.onSign,
    required this.onFile,
  });

  final bool signed;
  final String? signedDate;

  /// The signature drawn in this visit of the page, or null.
  final Signature? signature;
  final bool filed;
  final bool editing;
  final bool busy;
  final VoidCallback onAmend;
  final VoidCallback onSign;
  final VoidCallback onFile;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final StatusColors s = StatusColors.of(context);
    final Signature? drawn = signature;
    Widget chip(IconData icon, String label, bool ok) => Align(
          alignment: Alignment.centerLeft,
          child: StatusPill(
            icon: icon,
            label: label,
            background: ok ? s.successContainer : colors.secondaryContainer,
            foreground: ok ? s.success : colors.onSecondaryContainer,
          ),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 16, children: <Widget>[
      ConsoleCard(title: 'Signature status', children: <Widget>[
        Align(
          alignment: Alignment.centerLeft,
          child: StatusPill(
            icon: signed ? Icons.check_circle : Icons.schedule,
            label: signed ? 'Signed' : 'Pending',
            background: signed ? s.successContainer : s.warningContainer,
            foreground: signed ? s.success : s.warning,
          ),
        ),
        if (signed && drawn != null)
          Container(
            height: 80,
            decoration: BoxDecoration(
                border: Border.all(color: colors.outlineVariant), borderRadius: BorderRadius.circular(4)),
            child: CustomPaint(painter: SignaturePainter(drawn, colors.primary, scale: 0.45)),
          ),
        Text(signed
            ? (drawn == null ? 'Signed on ${signedDate ?? '-'}' : 'Signed on ${signedDate ?? 'today'}')
            : 'Sign the report after the text or file is ready.'),
      ]),
      ConsoleCard(title: 'Filing', children: <Widget>[
        filed ? chip(Icons.task_alt, 'Filed · officer notified', true) : chip(Icons.drafts, 'Not filed', false),
      ]),
      ConsoleCard(title: 'Actions', children: <Widget>[
        FilledButton.icon(
          onPressed: busy || filed ? null : onAmend,
          icon: Icon(editing ? Icons.check : Icons.edit),
          label: Text(editing ? 'Finish the draft' : 'Amend the draft'),
        ),
        OutlinedButton.icon(
          onPressed: busy || filed || editing ? null : onSign,
          icon: const Icon(Icons.draw),
          label: const Text('Sign the signature'),
        ),
        FilledButton.tonalIcon(
          onPressed: busy || filed || editing ? null : onFile,
          icon: const Icon(Icons.send),
          label: const Text('File the report'),
        ),
      ]),
    ]);
  }
}
