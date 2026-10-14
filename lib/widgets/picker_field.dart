import 'package:flutter/material.dart';

/// A field that opens a picker (date, time) when the user taps it.
class PickerField extends StatelessWidget {
  const PickerField({super.key, required this.label, required this.icon, required this.onTap, this.value, this.error});

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final String? value;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        isEmpty: value == null,
        decoration: InputDecoration(
          labelText: label,
          errorText: error,
          suffixIcon: Icon(error != null ? Icons.error : icon, color: error != null ? Theme.of(context).colorScheme.error : null),
        ),
        child: Text(value ?? '', style: Theme.of(context).textTheme.bodyLarge),
      ),
    );
  }
}
