import 'dart:async';

import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/snackbar_service.dart';
import 'package:boklo/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:boklo/shared/extensions/l10n.dart';
import 'package:boklo/shared/widgets/atoms/app_button.dart';
import 'package:boklo/shared/widgets/atoms/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Shows a dialog that sends a password-reset email. The response is
/// uniform regardless of whether the account exists (enumeration safety).
Future<void> showForgotPasswordDialog(BuildContext context) async {
  final controller = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final l10n = context.l10n;
  final cubit = context.read<AuthCubit>();
  final snackbar = getIt<SnackbarService>();

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.forgotPasswordTitle),
        content: Form(
          key: formKey,
          child: AppTextField(
            controller: controller,
            label: l10n.email,
            hintText: l10n.email,
            keyboardType: TextInputType.emailAddress,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? l10n.required : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          AppButton(
            text: l10n.forgotPasswordSend,
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final email = controller.text.trim();
              Navigator.of(dialogContext).pop();
              unawaited(
                cubit.sendPasswordResetEmail(email).then((result) {
                  result.fold(
                    (failure) => snackbar.showError(failure.message),
                    (_) => snackbar.showInfo(l10n.passwordResetSent),
                  );
                }),
              );
            },
          ),
        ],
      );
    },
  );
}
