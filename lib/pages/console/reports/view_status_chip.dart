import 'package:flutter/material.dart';

import '../../../theme/status_colors.dart';
import '../../../widgets/status_chip.dart';

/// The view status of QO6.1 and QO6.2 (Figma O6-1, O6-2): Pending or Viewed.
class ViewStatusChip extends StatelessWidget {
  const ViewStatusChip(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final StatusColors s = StatusColors.of(context);
    final bool viewed = status == 'Viewed';
    return StatusPill(
      icon: viewed ? Icons.visibility : Icons.schedule,
      label: status,
      background: viewed ? s.successContainer : s.warningContainer,
      foreground: viewed ? s.success : s.warning,
    );
  }
}
