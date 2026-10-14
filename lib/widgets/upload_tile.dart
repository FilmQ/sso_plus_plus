import 'package:flutter/material.dart';

import '../theme/status_colors.dart';
import 'dashed_border.dart';

/// One file row of U1-2 "Upload files". Without a file: a dashed box with an
/// Upload button. With a file: the name and size with a green check mark.
class UploadTile extends StatelessWidget {
  const UploadTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onUpload,
    this.fileName,
    this.fileSize,
    this.errorText,
  });

  final String title;
  final IconData icon;
  final VoidCallback onUpload;
  final String? fileName;
  final int? fileSize;
  final String? errorText;

  bool get _attached => fileName != null;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final TextTheme text = Theme.of(context).textTheme;
    final Color border = errorText != null ? colors.error : (_attached ? colors.outlineVariant : colors.outline);
    final Widget row = Row(
      children: <Widget>[
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _attached ? colors.primaryContainer : colors.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_attached ? icon : Icons.upload_file,
              size: 22, color: _attached ? colors.onPrimaryContainer : colors.onSurfaceVariant),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: text.titleSmall),
              Text(
                _attached ? '$fileName · ${formatBytes(fileSize ?? 0)}' : 'PDF, JPG or PNG, up to 10 MB',
                style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        if (_attached)
          IconButton(
            tooltip: 'Change file',
            onPressed: onUpload,
            icon: Icon(Icons.check_circle, color: StatusColors.of(context).success),
          )
        else
          FilledButton.tonal(onPressed: onUpload, child: const Text('Upload')),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DashedBorder(
          dashed: !_attached,
          color: border,
          radius: 12,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _attached ? colors.surfaceContainerLowest : colors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: row,
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(errorText!, style: text.bodySmall?.copyWith(color: colors.error)),
          ),
      ],
    );
  }
}

/// '1.2 MB', '845 KB'.
String formatBytes(int bytes) {
  if (bytes >= 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  return '${(bytes / 1024).ceil()} KB';
}
