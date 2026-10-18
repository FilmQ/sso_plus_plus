import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

/// Where uploaded files are kept (07-open-questions.md, item 4).
abstract interface class FileStorage {
  /// Keeps [bytes] for [claimId] and gives the file_uri for ClaimDocument,
  /// for example '/claims/143/id_card_front.jpg' (the seed format).
  Future<String> save(int claimId, String fileName, Uint8List bytes);

  /// Removes all files of [claimId] (when the submission rolls back).
  Future<void> deleteClaim(int claimId);

  /// Keeps the report file of a consultation session (C2.1 [Attach file]) and
  /// gives its report_file_uri, for example '/reports/306/xray.pdf'.
  Future<String> saveReportFile(int sessionId, String fileName, Uint8List bytes);

  /// The bytes of a [save]d file (O1 step 6), or null when there is no file.
  Future<Uint8List?> read(String fileUri);
}

/// Keeps the files in a local folder: `<root>/claims/<claim_id>/<file name>`.
class LocalFileStorage implements FileStorage {
  LocalFileStorage(this.root);

  final String root;

  @override
  Future<String> save(int claimId, String fileName, Uint8List bytes) => _saveIn('claims', claimId, fileName, bytes);

  @override
  Future<String> saveReportFile(int sessionId, String fileName, Uint8List bytes) =>
      _saveIn('reports', sessionId, fileName, bytes);

  /// Keeps [bytes] as `<root>/<folder>/<id>/<file name>`; a second file with
  /// the same name gets a number. Gives `/<folder>/<id>/<file name>`.
  Future<String> _saveIn(String folder, int id, String fileName, Uint8List bytes) async {
    final dir = Directory(p.join(root, folder, '$id'));
    await dir.create(recursive: true);
    var name = _safeName(fileName);
    var n = 1;
    while (File(p.join(dir.path, name)).existsSync()) {
      name = '${p.basenameWithoutExtension(_safeName(fileName))}_${n++}${p.extension(fileName)}';
    }
    await File(p.join(dir.path, name)).writeAsBytes(bytes, flush: true);
    return '/$folder/$id/$name';
  }

  @override
  Future<void> deleteClaim(int claimId) async {
    final dir = Directory(p.join(root, 'claims', '$claimId'));
    if (dir.existsSync()) await dir.delete(recursive: true);
  }

  @override
  Future<Uint8List?> read(String fileUri) async {
    final parts = p.posix.split(fileUri).where((String s) => s != '/').toList();
    // Only '/claims/<claim_id>/<file name>' or '/reports/<session_id>/<file name>',
    // as [save] and [saveReportFile] give them.
    if (parts.length != 3 ||
        !const ['claims', 'reports'].contains(parts[0]) ||
        int.tryParse(parts[1]) == null ||
        parts[2] != _safeName(parts[2])) {
      return null;
    }
    final file = File(p.join(root, parts[0], parts[1], parts[2]));
    return file.existsSync() ? file.readAsBytes() : null;
  }

  /// The base name with only letters, digits, '.', '_' and '-'.
  static String _safeName(String fileName) {
    final base = p.basename(fileName).replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    return base.isEmpty || base.startsWith('.') ? 'file$base' : base;
  }
}
