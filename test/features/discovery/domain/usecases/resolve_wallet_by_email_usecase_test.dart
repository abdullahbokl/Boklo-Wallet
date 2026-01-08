import 'package:boklo/core/base/result.dart';
import 'package:boklo/core/error/app_error.dart';
import 'package:boklo/features/discovery/domain/entities/user_public_profile.dart';
import 'package:boklo/features/discovery/domain/repositories/discovery_repository.dart';
import 'package:boklo/features/discovery/domain/usecases/resolve_wallet_by_email_usecase.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDiscoveryRepository extends Mock implements DiscoveryRepository {}

void main() {
  late ResolveWalletByEmailUseCase useCase;
  late MockDiscoveryRepository mockDiscoveryRepository;

  setUp(() {
    mockDiscoveryRepository = MockDiscoveryRepository();
    useCase = ResolveWalletByEmailUseCase(mockDiscoveryRepository);
  });

  const tEmail = 'test@example.com';
  const tProfile = UserPublicProfile(
    userId: 'user1',
    email: tEmail,
    walletId: 'wallet1',
  );

  test('should return walletId when repository call is successful', () async {
    // Arrange
    when(() => mockDiscoveryRepository.resolveWalletByEmail(tEmail))
        .thenAnswer((_) async => const Success(tProfile));

    // Act
    final result = await useCase(tEmail);

    // Assert
    expect(result, const Success('wallet1'));
    verify(() => mockDiscoveryRepository.resolveWalletByEmail(tEmail))
        .called(1);
  });

  test('should return Failure when repository call fails', () async {
    // Arrange
    when(() => mockDiscoveryRepository.resolveWalletByEmail(tEmail))
        .thenAnswer((_) async => const Failure(NetworkError('Network error')));

    // Act
    final result = await useCase(tEmail);

    // Assert
    expect(result, const Failure<String>(NetworkError('Network error')));
    verify(() => mockDiscoveryRepository.resolveWalletByEmail(tEmail))
        .called(1);
  });
}
