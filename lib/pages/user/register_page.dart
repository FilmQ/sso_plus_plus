import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/app_logo.dart';
import '../../widgets/centered_body.dart';
import '../../widgets/info_card.dart';

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
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
            child: CenteredBody(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: box.maxHeight - 80),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
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
                      FilledButton(onPressed: () => clickRegister(context), child: const Text('Register')),
                      const SizedBox(height: 24),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Already registered? Sign in'),
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
