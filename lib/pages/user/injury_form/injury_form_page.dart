import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../api/api_exception.dart';
import '../../../api/insured_form_api.dart';
import '../../../session/session_providers.dart';
import '../../../widgets/centered_body.dart';
import '../../../widgets/error_banner.dart';
import '../submission_provider.dart';
import 'already_registered_dialog.dart';
import 'general_section.dart';
import 'injury_form_data.dart';
import 'injury_section.dart';
import 'password_section.dart';
import 'upload_section.dart';

/// U1-2 Fill in Injury Forms Page, with the error states U1-3 (Validation
/// failed) and U1-4 (National ID already registered). SA report figures 2-10 to 2-12.
class InjuryFormPage extends ConsumerStatefulWidget {
  const InjuryFormPage({super.key});

  @override
  ConsumerState<InjuryFormPage> createState() => _InjuryFormPageState();
}

class _InjuryFormPageState extends ConsumerState<InjuryFormPage> {
  final InjuryFormData _form = InjuryFormData();
  final ScrollController _scroll = ScrollController();
  Map<String, String> _errors = <String, String>{};
  bool _busy = false;

  @override
  void dispose() {
    _form.dispose();
    _scroll.dispose();
    super.dispose();
  }

  /// The user changed a field: remove its old error.
  void _changed(String field) => setState(() => _errors.remove(field));

  /// U1 step 3: the user clicks "Submit Injury Forms".
  Future<void> submitForms() async {
    setState(() => _busy = true);
    try {
      final Map<String, Object?> body = await InsuredFormApi(ref.read(apiClientProvider)).submitInjuryForm(_form);
      ref.read(submissionProvider.notifier).set(body['claim']! as Map<String, Object?>);
      // Step 6: the router opens U1-5 when the session is set.
      await ref.read(sessionProvider.notifier).signedIn(body);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.status != 422) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
        return;
      }
      setState(() {
        _errors = (e.body['fields']! as Map<String, Object?>).cast<String, String>();
        _busy = false;
      });
      _scroll.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      if (e.body['already_registered'] == true) {
        await showAlreadyRegisteredDialog(context, _form.nationalId.text.trim());
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String get _bannerText {
    final int n = _errors.length;
    final String fields = n == 1 ? '1 field needs' : '$n fields need';
    return '$fields your attention. Correct them and press Submit Injury Forms again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/register')),
        title: const Text('Fill in Injury Forms'),
      ),
      body: SingleChildScrollView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: CenteredBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: <Widget>[
              if (_errors.isNotEmpty) ErrorBanner(_bannerText),
              GeneralSection(data: _form, errors: _errors, onChanged: _changed),
              const Divider(),
              InjurySection(data: _form, errors: _errors, onChanged: _changed),
              const Divider(),
              UploadSection(data: _form, errors: _errors, onChanged: _changed, chooseFile: ref.read(fileChooserProvider)),
              const Divider(),
              PasswordSection(data: _form, errors: _errors, onChanged: _changed),
              FilledButton(
                onPressed: _busy ? null : submitForms,
                child: _busy
                    ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Submit Injury Forms'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
