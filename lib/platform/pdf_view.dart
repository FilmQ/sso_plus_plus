import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import 'pdf_view_stub.dart' if (dart.library.js_interop) 'pdf_view_web.dart' as impl;

/// Shows the PDF [bytes] in the page, with no download (O1-3, D-071). Gives
/// null where the platform cannot do it (mobile).
Widget? pdfView(Uint8List bytes) => impl.pdfView(bytes);
