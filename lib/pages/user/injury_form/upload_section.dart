import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../widgets/section_header.dart';
import '../../../widgets/upload_tile.dart';
import 'injury_form_data.dart';

/// Picks one file. Tests replace it, because the platform picker cannot run there.
typedef FileChooser = Future<PickedFile?> Function();

Future<PickedFile?> chooseFileFromDevice() async {
  final PlatformFile? f = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: <String>['pdf', 'jpg', 'jpeg', 'png'],
  );
  return f == null ? null : PickedFile(f.name, await f.readAsBytes());
}

/// The file chooser of U1-2. Widget tests override it.
final Provider<FileChooser> fileChooserProvider = Provider<FileChooser>((Ref ref) => chooseFileFromDevice);

/// U1-2 "Upload files": the image of the ID card, the medical record and the
/// injury form (Kor Thor 16).
class UploadSection extends StatelessWidget {
  const UploadSection({
    super.key,
    required this.data,
    required this.errors,
    required this.onChanged,
    required this.chooseFile,
  });

  final InjuryFormData data;
  final Map<String, String> errors;
  final ValueChanged<String> onChanged;
  final FileChooser chooseFile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: <Widget>[
        const SectionHeader(title: 'Upload files', subtitle: 'Attach all three files before submitting'),
        for (final (String field, String title, IconData icon) in uploadSlots)
          UploadTile(
            key: ValueKey<String>('upload:$field'),
            title: title,
            icon: icon,
            fileName: data.files[field]?.name,
            fileSize: data.files[field]?.bytes.length,
            errorText: errors[field],
            onUpload: () async {
              final PickedFile? f = await chooseFile();
              if (f != null) {
                data.files[field] = f;
                onChanged(field);
              }
            },
          ),
      ],
    );
  }
}
