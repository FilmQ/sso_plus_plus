import 'package:flutter/material.dart';

/// How the banner reads.
enum BannerTone { info, warning }

/// The quiet strip of text that explains a rule to the person.
///
/// Screens M3 to M9 use it, for example "Reply by Wednesday 16 September" or
/// "A signed report cannot be changed".
class NoticeBanner extends StatelessWidget {
  const NoticeBanner({
    super.key,
    required this.text,
    this.icon = Icons.info_outline,
    this.tone = BannerTone.info,
  });

  final String text;
  final IconData icon;
  final BannerTone tone;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    final (Color background, Color foreground) = switch (tone) {
      BannerTone.info => (
        colors.surfaceContainerHighest,
        colors.onSurfaceVariant,
      ),
      BannerTone.warning => (colors.errorContainer, colors.onErrorContainer),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 16, color: foreground),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}
