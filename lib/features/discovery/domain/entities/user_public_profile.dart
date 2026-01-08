import 'package:equatable/equatable.dart';

class UserPublicProfile extends Equatable {
  const UserPublicProfile({
    required this.userId,
    required this.email,
    required this.walletId,
  });

  final String userId;
  final String email;
  final String walletId;

  @override
  List<Object?> get props => [userId, email, walletId];
}
