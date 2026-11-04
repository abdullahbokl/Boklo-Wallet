import 'dart:async';

import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/navigation_service.dart';
import 'package:boklo/features/contacts/domain/entity/contact_entity.dart';
import 'package:boklo/shared/extensions/l10n.dart';
import 'package:boklo/shared/widgets/atoms/app_text_field.dart';
import 'package:flutter/material.dart';

class TransferRecipientInput extends StatefulWidget {
  const TransferRecipientInput({
    required this.controller,
    required this.enabled,
    super.key,
  });

  final TextEditingController controller;
  final bool enabled;

  @override
  State<TransferRecipientInput> createState() => _TransferRecipientInputState();
}

class _TransferRecipientInputState extends State<TransferRecipientInput> {
  Future<void> _scanQr() async {
    final recipient = await getIt<NavigationService>().push<String>(
      '/scan-recipient',
    );
    if (recipient != null && mounted) {
      setState(() {
        widget.controller.text = recipient;
      });
    }
  }

  Future<void> _pickContact() async {
    final contact = await getIt<NavigationService>().push<ContactEntity>(
      '/contacts',
      extra: {'pickMode': true},
    );

    if (contact != null && mounted) {
      setState(() {
        widget.controller.text = contact.email;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: widget.controller,
      enabled: widget.enabled,
      label: context.l10n.recipient,
      hintText: context.l10n.recipientHint,
      prefixIcon: const Icon(Icons.person_outline),
      suffixIcon: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: context.l10n.qrScan,
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: widget.enabled ? _scanQr : null,
          ),
          IconButton(
            icon: const Icon(Icons.contacts),
            onPressed: widget.enabled ? _pickContact : null,
          ),
        ],
      ),
      validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
    );
  }
}
