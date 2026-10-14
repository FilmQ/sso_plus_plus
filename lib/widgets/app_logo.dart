import 'package:flutter/material.dart';

/// The app logo of the Figma frames: a white cross on a primary square.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: colors.primary, borderRadius: BorderRadius.circular(size * 0.28)),
      child: Icon(Icons.local_hospital, size: size * 0.55, color: colors.onPrimary),
    );
  }
}

/// The logo, the app name and the Thai name of the centre (U1-1, login).
class AppHeader extends StatelessWidget {
  const AppHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Column(
      children: <Widget>[
        const AppLogo(),
        const SizedBox(height: 24),
        Text(title, style: text.headlineSmall, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        Text(
          'ศูนย์ฟื้นฟูผู้ป่วย (ประกันสังคม)',
          style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
