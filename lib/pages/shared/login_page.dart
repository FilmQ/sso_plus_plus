import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../api/api_exception.dart';
import '../../session/session_providers.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/centered_body.dart';

/// Sign in (infrastructure, D-003). The site map has Login as the root page,
/// but the report and Figma have no login frame, so the page uses the style
/// of U1-1 Register Page.
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key, required this.title, required this.loginLabel, this.registerRoute});

  final String title;
  final String loginLabel;

  /// The user app shows a link to U1-1 Register Page. The console does not.
  final String? registerRoute;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final TextEditingController _login = TextEditingController();
  final TextEditingController _password = TextEditingController();
  bool _busy = false;
  bool _hidden = true;
  String? _error;

  @override
  void dispose() {
    _login.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(sessionProvider.notifier).login(_login.text, _password.text);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
          child: CenteredBody(
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  AppHeader(title: widget.title),
                  const SizedBox(height: 32),
                  TextField(
                    key: const Key('login_name'),
                    controller: _login,
                    autofillHints: const <String>[AutofillHints.username],
                    decoration: InputDecoration(labelText: widget.loginLabel),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('password'),
                    controller: _password,
                    obscureText: _hidden,
                    autofillHints: const <String>[AutofillHints.password],
                    onSubmitted: (_) => _signIn(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      errorText: _error,
                      suffixIcon: IconButton(
                        tooltip: _hidden ? 'Show password' : 'Hide password',
                        icon: Icon(_hidden ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _hidden = !_hidden),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _busy ? null : _signIn,
                    child: _busy
                        ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Sign in'),
                  ),
                  if (widget.registerRoute != null) ...<Widget>[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.go(widget.registerRoute!),
                      child: const Text('New user? Register'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
