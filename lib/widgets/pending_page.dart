import 'package:flutter/material.dart';

/// The body of a page that a later session builds (brief, section 7).
class PendingPage extends StatelessWidget {
  const PendingPage({super.key, required this.title, required this.useCases, this.action});

  final String title;

  /// The use cases that will fill this page, for example 'U5 and U6'.
  final String useCases;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.construction, size: 48, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text(title, style: text.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text('This page is not available yet ($useCases).', style: text.bodyMedium, textAlign: TextAlign.center),
            if (action != null) ...<Widget>[const SizedBox(height: 24), action!],
          ],
        ),
      ),
    );
  }
}
