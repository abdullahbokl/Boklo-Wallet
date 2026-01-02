import 'package:flutter/material.dart';

/// A standardized button atom.
///
/// Rules:
/// - [Theme-Aware]: Inherits colors/shapes from [Theme] and [AppRadius].
/// - [Localization]: [text] must be localized.
/// - [Responsiveness]: Sizing should be handled by the parent or strict constraints, no [MediaQuery].
/// - [No Business Logic]: Callbacks only.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.text,
    super.key,
    this.onPressed,
    this.isLoading = false,
  });

  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(text),
    );
  }
}
