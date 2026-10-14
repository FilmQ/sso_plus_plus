import 'package:flutter/material.dart';

import '../../../widgets/form_text_field.dart';
import '../../../widgets/section_header.dart';
import 'injury_form_data.dart';

/// U1-2 "Password": password and confirm password.
class PasswordSection extends StatelessWidget {
  const PasswordSection({super.key, required this.data, required this.errors, required this.onChanged});

  final InjuryFormData data;
  final Map<String, String> errors;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: <Widget>[
        const SectionHeader(title: 'Password', subtitle: 'At least 8 characters, English letters and numbers only'),
        FormTextField(
          key: const ValueKey<String>('password'),
          label: 'Password',
          controller: data.password,
          secret: true,
          error: errors['password'],
          onChanged: (_) => onChanged('password'),
        ),
        FormTextField(
          key: const ValueKey<String>('confirm_password'),
          label: 'Confirm password',
          controller: data.confirmPassword,
          secret: true,
          error: errors['confirm_password'],
          onChanged: (_) => onChanged('confirm_password'),
        ),
      ],
    );
  }
}
