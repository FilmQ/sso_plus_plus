import 'package:flutter/material.dart';

import '../../../theme/status_colors.dart';
import '../../../widgets/status_chip.dart';
import '../verification/claim_cards.dart';

/// The right side of the report page (Figma C2.1-1 to C2.3-2): "Signature
/// status" with the stored signature image (R-048), "Filing" and "Actions"
/// with "User did not attend" (C2.1-5, R-051).
class ReportStatusCards extends StatelessWidget {
  const ReportStatusCards({
    super.key,
    required this.signed,
    required this.signedDate,
    required this.signatureImage,
    required this.filed,
    required this.editing,
    required this.busy,
    required this.onAmend,
    required this.onSign,
    required this.onFile,
    required this.onNoShow,
  });

  final bool signed;
  final String? signedDate;

  /// The stored signature image of a signed report, or null.
  final Widget? signatureImage;
  final bool filed;
  final bool editing;
  final bool busy;
  final VoidCallback onAmend;
  final VoidCallback onSign;
  final VoidCallback onFile;

  /// "User did not attend", or null to hide the button (the consultation
  /// has a report).
  final VoidCallback? onNoShow;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final StatusColors s = StatusColors.of(context);
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
        if (signed && signatureImage != null) signatureImage!,
        if (!signed) const Text('Sign the report after the text or file is ready.'),
      ]),
      ConsoleCard(title: 'Filing', children: <Widget>[
        filed ? chip(Icons.task_alt, 'Filed', true) : chip(Icons.drafts, 'Not filed', false),
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
        if (onNoShow != null)
          OutlinedButton.icon(
            onPressed: busy || filed || editing ? null : onNoShow,
            icon: const Icon(Icons.person_off),
            label: const Text('User did not attend'),
          ),
      ]),
    ]);
  }
}
