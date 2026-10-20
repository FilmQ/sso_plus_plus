import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'signature_dialog.dart';

/// Makes the PNG image of a drawn signature for QC2.6 (R-048). Tests replace
/// it, because a widget test cannot encode an image.
final Provider<Future<Uint8List> Function(Signature)> signatureEncoderProvider =
    Provider<Future<Uint8List> Function(Signature)>((Ref ref) => signatureToPng);

/// Draws [strokes] in dark blue on a clear image around the strokes, with a
/// margin of 8 pixels, and gives the PNG bytes.
Future<Uint8List> signatureToPng(Signature strokes) async {
  final Iterable<Offset> points = strokes.expand((List<Offset> s) => s);
  final Rect bounds = points.isEmpty
      ? Rect.zero
      : points.skip(1).fold(Rect.fromPoints(points.first, points.first),
          (Rect r, Offset o) => r.expandToInclude(Rect.fromPoints(o, o)));
  final Rect area = bounds.inflate(8);
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  final Canvas canvas = Canvas(recorder)..translate(-area.left, -area.top);
  SignaturePainter(strokes, const Color(0xFF1A237E)).paint(canvas, area.size);
  final ui.Image image =
      await recorder.endRecording().toImage(area.width.ceil().clamp(1, 2000), area.height.ceil().clamp(1, 2000));
  final ByteData? png = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return png!.buffer.asUint8List();
}
