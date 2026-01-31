import 'package:boklo/core/base/result.dart';

import 'package:boklo/features/discovery/domain/usecases/resolve_wallet_by_email_usecase.dart';
import 'package:boklo/features/discovery/domain/usecases/resolve_wallet_by_username_usecase.dart';
import 'package:injectable/injectable.dart';

@injectable
class ResolveRecipientUseCase {
  final ResolveWalletByEmailUseCase _emailUseCase;
  final ResolveWalletByUsernameUseCase _usernameUseCase;

  const ResolveRecipientUseCase(this._emailUseCase, this._usernameUseCase);

  Future<Result<String>> call(String recipient) async {
    if (recipient.contains('@')) {
      return _emailUseCase(recipient);
    } else if (recipient.length < 28 &&
        !recipient.contains(RegExp(r'[^a-zA-Z0-9_.]'))) {
      final resolution = await _usernameUseCase(recipient);

      return resolution.fold(
        (error) {
          // If username resolution fails, check if it COULD be a wallet ID.
          if (recipient.length != 28) {
            return Failure(error);
          }
          // Fallback to treating as Wallet ID is handled by caller or implicitly if we return error/null here?
          // Actually, the original logic said: "If it IS 28 chars, ignore username error and try as Wallet ID"
          // So if error, and length == 28, we return Success(recipient) assuming it's an ID?
          // The original logic was: toWalletId = recipient (initial).
          // If resolution succeeds, toWalletId = resolvedId.
          // If resolution fails, and length != 28, return error.
          // If resolution fails, and length == 28, keep original recipient.

          return Success(recipient);
        },
        (id) => Success(id),
      );
    }

    // Default: Assume it's a Wallet ID
    return Success(recipient);
  }
}
