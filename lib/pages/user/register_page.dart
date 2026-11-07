import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/tr.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/centered_body.dart';
import '../../widgets/info_card.dart';
import '../../widgets/language_toggle.dart';

/// U1-1 Register Page (SA report figure 2-9).
class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  /// U1 step 1: the user clicks "Register"; step 2: redirect to U1-2.
  void clickRegister(BuildContext context) => context.go('/register/form');

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
                      const AppHeader(title: 'SST Injury Claim'),
                      const SizedBox(height: 24),
                      const InfoCard(
                        icon: Icons.info,
                        title: 'Before you start',
                        tonal: true,
                        children: <Widget>[
                          CheckLine('Your Thai national ID card'),
                          CheckLine('A medical record file from the hospital'),
                          CheckLine('The injury form (Kor Thor 16) as a file'),
                        ],
                      ),
                      const Spacer(),
                      const SizedBox(height: 24),
                      FilledButton(onPressed: () => clickRegister(context), child: Text(context.tr('Register'))),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: Text(context.tr('Already registered? Sign in')),
                      ),
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
