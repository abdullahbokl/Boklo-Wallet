import 'package:boklo/config/theme/app_dimens.dart';
import 'package:boklo/config/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    required this.controller,
    required this.hintText,
    super.key,
    this.label,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.prefixIcon,
    this.suffixIcon,
    this.onSubmitted,
    this.enabled = true,
    this.inputFormatters,
    this.autofocus = false,
    this.helperText,
  });

  final TextEditingController controller;
  final String hintText;
  final String? label;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final void Function(String)? onSubmitted;
  final bool enabled;
  final List<TextInputFormatter>? inputFormatters;
  final bool autofocus;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTypography.bodySmall.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppDimens.xs),
        ],
        TextFormField(
          controller: controller,
          enabled: enabled,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          onFieldSubmitted: onSubmitted,
          inputFormatters: inputFormatters,
          autofocus: autofocus,
          style: AppTypography.bodyLarge.copyWith(color: scheme.onSurface),
          cursorColor: scheme.primary,
          decoration: InputDecoration(
            hintText: hintText,
            helperText: helperText,
            prefixIcon: prefixIcon != null
                ? IconTheme(
                    data: IconThemeData(
                      color: scheme.onSurfaceVariant,
                      size: AppDimens.iconMd,
                    ),
                    child: prefixIcon!,
                  )
                : null,
            suffixIcon: suffixIcon != null
                ? IconTheme(
                    data: IconThemeData(
                      color: scheme.onSurfaceVariant,
                      size: AppDimens.iconMd,
                    ),
                    child: suffixIcon!,
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
