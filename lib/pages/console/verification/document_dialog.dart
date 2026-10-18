import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../api/api_exception.dart';
import '../../../platform/save_file.dart';
import 'claim_cards.dart';

/// O1-3 Document opened (SA report figure 2-57): O1 steps 5 to 6. [load]
/// gives the bytes of the file of a QO1.4 row.
Future<void> showDocumentDialog(BuildContext context, Map<String, Object?> document,
    Future<({Uint8List bytes, String? mimeType})> Function() load) {
  return showDialog<void>(context: context, builder: (BuildContext _) => _DocumentDialog(document, load));
}

class _DocumentDialog extends StatefulWidget {
  const _DocumentDialog(this.document, this.load);

  final Map<String, Object?> document;
  final Future<({Uint8List bytes, String? mimeType})> Function() load;

  @override
  State<_DocumentDialog> createState() => _DocumentDialogState();
}

class _DocumentDialogState extends State<_DocumentDialog> {
  late final Future<({Uint8List bytes, String? mimeType})> _file = widget.load();

  String get _name => '${widget.document['file_name']}';

  Future<void> _download() async {
    final ({Uint8List bytes, String? mimeType}) file;
    try {
      file = await _file;
    } on ApiException {
      return; // The preview shows the message.
    }
    final bool saved = saveFile(file.bytes, _name, file.mimeType ?? 'application/octet-stream');
    if (!saved && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Download is not available on this device.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return AlertDialog(
      icon: Icon(DocumentsCard.isImage(_name) ? Icons.image : Icons.description, color: colors.primary),
      title: Text(_name),
      content: SizedBox(
        width: 600,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, spacing: 12,
            children: <Widget>[
          Text('${widget.document['file_size']}'),
          Container(
            height: 360,
            width: double.infinity,
            decoration: BoxDecoration(
              color: colors.surfaceContainerLowest,
              border: Border.all(color: colors.outlineVariant),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FutureBuilder<({Uint8List bytes, String? mimeType})>(
              future: _file,
              builder: (BuildContext context, AsyncSnapshot<({Uint8List bytes, String? mimeType})> snap) {
                if (snap.hasError) {
                  final Object? e = snap.error;
                  return Center(child: Text(e is ApiException ? e.message : 'The file cannot be opened.'));
                }
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                return DocumentsCard.isImage(_name)
                    ? InteractiveViewer(child: Image.memory(snap.data!.bytes, fit: BoxFit.contain))
                    : const Center(
                        child: Text('The app cannot show a preview of this file type. Use Download to open it.'));
              },
            ),
          ),
        ]),
      ),
      actions: <Widget>[
        TextButton.icon(onPressed: _download, icon: const Icon(Icons.download), label: const Text('Download')),
        FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
      ],
    );
  }
}
