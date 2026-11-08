import 'dart:js_interop';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:web/web.dart' as web;

/// Web: the browser PDF viewer in an iframe, from an object URL of type
/// application/pdf. A blob of another type makes the browser download it.
Widget? pdfView(Uint8List bytes) => _PdfView(bytes);

class _PdfView extends StatefulWidget {
  const _PdfView(this.bytes);

  final Uint8List bytes;

  @override
  State<_PdfView> createState() => _PdfViewState();
}

class _PdfViewState extends State<_PdfView> {
  late final String _url = web.URL.createObjectURL(
      web.Blob(<JSUint8Array>[widget.bytes.toJS].toJS, web.BlobPropertyBag(type: 'application/pdf')));

  @override
  void dispose() {
    web.URL.revokeObjectURL(_url);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HtmlElementView.fromTagName(
        tagName: 'iframe',
        onElementCreated: (Object element) {
          final web.HTMLIFrameElement frame = element as web.HTMLIFrameElement;
          frame
            ..src = _url
            ..title = 'PDF'
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '100%';
        },
      );
}
