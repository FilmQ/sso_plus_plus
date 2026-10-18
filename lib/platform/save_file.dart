import 'dart:typed_data';

import 'save_file_stub.dart' if (dart.library.js_interop) 'save_file_web.dart' as impl;

/// Gives [bytes] to the browser as a download named [fileName] (O1-3
/// "Download"). Gives false where the platform cannot do it (mobile).
bool saveFile(Uint8List bytes, String fileName, String mimeType) => impl.saveFile(bytes, fileName, mimeType);
