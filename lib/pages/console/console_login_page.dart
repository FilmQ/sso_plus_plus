import 'package:flutter/material.dart';

import '../../widgets/app_logo.dart';
import '../shared/login_form.dart';

/// L-2 Console Login Page (Figma node 146:125): staff e-mail and password in a
/// card. The role of the account decides which console opens (D-003).
class ConsoleLoginPage extends StatelessWidget {
  const ConsoleLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: colors.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Row(children: <Widget>[
                      const AppLogo(size: 40),
                      const SizedBox(width: 12),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                        Text('SST Console', style: text.titleMedium),
                        Text('Social Security Office', style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                      ]),
                    ]),
                    const SizedBox(height: 28),
                    Text('Sign in', style: text.headlineMedium),
                    const SizedBox(height: 20),
                    Text('For evaluation officers and consultants of the SSO Rehabilitation Center',
                        style: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant)),
                    const SizedBox(height: 20),
                    const LoginForm(loginLabel: 'Staff e-mail'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
