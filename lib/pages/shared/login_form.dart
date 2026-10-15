import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../api/api_exception.dart';
import '../../session/session_providers.dart';

/// The login name, the password and "Sign in" of L-1 and L-2 (D-003).
class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key, required this.loginLabel, this.loginHelper, this.pushButtonDown = false});

  final String loginLabel;
  final String? loginHelper;

  /// L-1: the button is at the bottom of the screen. Put the form in an
  /// Expanded (or another widget with a bounded height) when this is true.
  final bool pushButtonDown;

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
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
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          TextField(
            key: const Key('login_name'),
            controller: _login,
            autofillHints: const <String>[AutofillHints.username],
            decoration: InputDecoration(labelText: widget.loginLabel, helperText: widget.loginHelper),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 20),
          TextField(
            key: const Key('password'),
            controller: _password,
            obscureText: _hidden,
            autofillHints: const <String>[AutofillHints.password],
            onSubmitted: (_) => _signIn(),
            decoration: InputDecoration(
              labelText: 'Password',
              errorText: _error,
              errorMaxLines: 2,
              suffixIcon: IconButton(
                tooltip: _hidden ? 'Show password' : 'Hide password',
                icon: Icon(_hidden ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _hidden = !_hidden),
              ),
            ),
          ),
          if (widget.pushButtonDown) const Spacer(),
          const SizedBox(height: 20),
          FilledButton(
            key: const Key('sign_in'),
            onPressed: _busy ? null : _signIn,
            child: _busy
                ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Sign in'),
          ),
        ],
      ),
    );
  }
}
