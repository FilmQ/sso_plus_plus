import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/tr.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/centered_body.dart';
import '../../widgets/language_toggle.dart';
import 'login_form.dart';

/// L-1 Login Page of the user app (Figma node 146:8). Login is
/// infrastructure, not a use case (D-003).
class LoginPage extends StatelessWidget {
  const LoginPage({super.key, required this.title, required this.loginLabel, this.loginHelper, this.registerRoute});

  final String title;
  final String loginLabel;
  final String? loginHelper;

  /// The link "New here? Register" to U1-1 Register Page.
  final String? registerRoute;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints box) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: CenteredBody(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: box.maxHeight - 32),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      // The toggle is 48 high: it takes the place of the old top padding.
                      const Align(alignment: Alignment.centerRight, child: LanguageToggle()),
                      AppHeader(title: title),
                      const SizedBox(height: 24),
                      Expanded(child: LoginForm(loginLabel: loginLabel, loginHelper: loginHelper, pushButtonDown: true)),
                      if (registerRoute != null) ...<Widget>[
                        const SizedBox(height: 24),
                        TextButton(onPressed: () => context.go(registerRoute!), child: Text(context.tr('New here? Register'))),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
