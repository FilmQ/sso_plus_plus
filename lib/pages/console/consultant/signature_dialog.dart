import 'package:flutter/material.dart';

import '../../../widgets/dashed_border.dart';

/// The strokes of a drawn signature: each stroke is a list of points.
typedef Signature = List<List<Offset>>;

/// C2.2-1 "Sign the report" (C2.2 steps 3 to 5): the consultant draws the
/// signature. "Delete" clears it (Alternate Case 1 [Delete]); "Confirm" gives
/// the strokes. Null for a closed card. QC2.6 saves only the time; the
/// drawing is not stored (D-059).
Future<Signature?> showSignatureDialog(BuildContext context) =>
    showDialog<Signature>(context: context, builder: (BuildContext _) => const _SignatureDialog());

class _SignatureDialog extends StatefulWidget {
  const _SignatureDialog();

  @override
  State<_SignatureDialog> createState() => _SignatureDialogState();
}

class _SignatureDialogState extends State<_SignatureDialog> {
  final Signature _strokes = <List<Offset>>[];

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return AlertDialog(
      icon: Icon(Icons.draw, color: colors.primary),
      title: const Text('Sign the report'),
      content: SizedBox(
        width: 480,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, spacing: 8,
            children: <Widget>[
          DashedBorder(
            color: colors.outline,
            radius: 4,
            child: SizedBox(
              key: const Key('signature_pad'),
              height: 180,
              width: double.infinity,
              child: ColoredBox(
                color: colors.surfaceContainerLowest,
                child: GestureDetector(
                  onPanStart: (DragStartDetails d) => setState(() => _strokes.add(<Offset>[d.localPosition])),
                  onPanUpdate: (DragUpdateDetails d) => setState(() => _strokes.last.add(d.localPosition)),
                  child: CustomPaint(painter: SignaturePainter(_strokes, colors.primary)),
                ),
              ),
            ),
          ),
          Text('Draw your signature in the box', style: Theme.of(context).textTheme.bodySmall),
        ]),
      ),
      actions: <Widget>[
        TextButton.icon(
          onPressed: () => setState(_strokes.clear),
          icon: const Icon(Icons.delete),
          label: const Text('Delete'),
        ),
        FilledButton(
          onPressed: _strokes.isEmpty ? null : () => Navigator.of(context).pop(_strokes),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

/// Draws the strokes of a signature (the card and the small copy on the page).
class SignaturePainter extends CustomPainter {
  SignaturePainter(this.strokes, this.color, {this.scale = 1});

  final Signature strokes;
  final Color color;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint pen = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final List<Offset> s in strokes) {
      final Path path = Path();
      for (int i = 0; i < s.length; i++) {
        final Offset o = s[i] * scale;
        i == 0 ? path.moveTo(o.dx, o.dy) : path.lineTo(o.dx, o.dy);
      }
      canvas.drawPath(path, pen);
    }
  }

  @override
  bool shouldRepaint(SignaturePainter old) => true;
}
