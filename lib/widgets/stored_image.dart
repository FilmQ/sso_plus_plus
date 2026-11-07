import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../l10n/tr.dart';

/// An image that the server keeps (for example the signature of a report,
/// R-048). [load] gets the bytes once; a new [cacheKey] gets them again.
class StoredImage extends StatefulWidget {
  const StoredImage({super.key, required this.load, required this.cacheKey, this.height = 80, this.label});

  final Future<({Uint8List bytes, String? mimeType})> Function() load;
  final Object cacheKey;
  final double height;

  /// The text for a screen reader.
  final String? label;

  @override
  State<StoredImage> createState() => _StoredImageState();
}

class _StoredImageState extends State<StoredImage> {
  late Future<Uint8List> _bytes = _load();

  Future<Uint8List> _load() async => (await widget.load()).bytes;

  @override
  void didUpdateWidget(StoredImage old) {
    super.didUpdateWidget(old);
    if (old.cacheKey != widget.cacheKey) _bytes = _load();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      height: widget.height,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest,
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(4),
      ),
      child: FutureBuilder<Uint8List>(
        future: _bytes,
        builder: (BuildContext context, AsyncSnapshot<Uint8List> snap) => switch (snap) {
          AsyncSnapshot<Uint8List>(hasData: true, :final Uint8List data) =>
            Image.memory(data, fit: BoxFit.contain, semanticLabel: widget.label),
          AsyncSnapshot<Uint8List>(hasError: true) =>
            Center(child: Text(context.tr('The image cannot be shown now.'), style: Theme.of(context).textTheme.bodySmall)),
          _ => const Center(child: SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))),
        },
      ),
    );
  }
}
