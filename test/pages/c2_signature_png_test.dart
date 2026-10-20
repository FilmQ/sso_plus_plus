import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sso_plus_plus/pages/console/consultant/signature_png.dart';

void main() {
  testWidgets('C2.2: the drawn signature becomes a PNG image around the strokes (R-048)', (WidgetTester tester) async {
    final Uint8List? png = await tester.runAsync(() => signatureToPng(<List<Offset>>[
          <Offset>[const Offset(20, 40), const Offset(80, 10), const Offset(140, 60)],
          <Offset>[const Offset(150, 30), const Offset(200, 30)],
        ]));
    expect(png!.sublist(0, 4), <int>[0x89, 0x50, 0x4E, 0x47]);
    final ByteData header = ByteData.sublistView(png, 16, 24);
    expect((header.getUint32(0), header.getUint32(4)), (196, 66), reason: '180 x 50 strokes and a margin of 8');
  });
}
