import 'package:flutter/material.dart';

import 'console_nav.dart';

/// The frame of the officer pages: the navigation on the left on a wide
/// screen (Figma 1440 x 900), or in a drawer on a narrow screen.
class ConsoleShell extends StatelessWidget {
  const ConsoleShell({super.key, required this.location, required this.child});

  static const double wideWidth = 840;

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool wide = MediaQuery.sizeOf(context).width >= wideWidth;
    return Scaffold(
      drawer: wide ? null : Drawer(width: 256, child: ConsoleNav(location: location)),
      body: wide ? Row(children: <Widget>[ConsoleNav(location: location), Expanded(child: child)]) : child,
    );
  }
}

/// One officer page: the top bar (back, title, subtitle, actions) and the
/// body under it.
class ConsolePage extends StatelessWidget {
  const ConsolePage({super.key, required this.title, required this.subtitle, required this.body, this.onBack});

  final String title;
  final String subtitle;
  final Widget body;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool drawer = Scaffold.maybeOf(context)?.hasDrawer ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(spacing: 8, children: <Widget>[
              if (drawer)
                IconButton(
                  tooltip: 'Menu',
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              if (onBack != null) IconButton(tooltip: 'Back', icon: const Icon(Icons.arrow_back), onPressed: onBack),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  Text(title, style: text.headlineSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(subtitle, style: text.bodyMedium),
                ]),
              ),
            ]),
          ),
        ),
        const Divider(height: 1),
        Expanded(child: body),
      ],
    );
  }
}

/// A floating snackbar of the console (Figma O2-3, O3-3).
SnackBar consoleSnackBar(String text) => SnackBar(content: Text(text), behavior: SnackBarBehavior.floating, width: 520);
