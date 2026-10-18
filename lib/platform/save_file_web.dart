import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Web: an object URL and a temporary link with the `download` attribute.
bool saveFile(Uint8List bytes, String fileName, String mimeType) {
  final web.Blob blob = web.Blob(<JSUint8Array>[bytes.toJS].toJS, web.BlobPropertyBag(type: mimeType));
  final String url = web.URL.createObjectURL(blob);
  final web.HTMLAnchorElement link = web.HTMLAnchorElement()
    ..href = url
    ..download = fileName;
  web.document.body?.append(link);
  link.click();
  link.remove();
  web.URL.revokeObjectURL(url);
  return true;
}
