import 'package:boklo/l10n/generated/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Convenience accessor: `context.l10n.signInToBoklo`.
extension L10nExtension on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
