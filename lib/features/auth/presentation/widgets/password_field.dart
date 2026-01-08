import 'package:boklo/shared/widgets/atoms/app_text_field.dart';
import 'package:flutter/material.dart';

class PasswordField extends StatelessWidget {
  const PasswordField({
    required this.controller,
    super.key,
    this.onSubmitted,
    this.hintText = 'Password',
    this.enabled = true,
  });

  final TextEditingController controller;
  final void Function(String)? onSubmitted;
  final String hintText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      enabled: enabled,
      controller: controller,
      hintText: hintText,
      obscureText: true,
      prefixIcon: const Icon(Icons.lock_outline),
      validator: (value) =>
          value?.isEmpty ?? true ? 'Please enter your password' : null,
      onSubmitted: onSubmitted,
    );
  }
}
