import 'package:equatable/equatable.dart';

/// A registered push-notification device for the current user.
class DeviceSession extends Equatable {
  const DeviceSession({
    required this.token,
    required this.platform,
    this.createdAt,
    this.currentDeviceToken,
  });

  /// Firestore doc id == the FCM registration token.
  final String token;
  final String platform;
  final DateTime? createdAt;

  /// The FCM token of the device making the request, when it matches one
  /// of the listed sessions.
  final String? currentDeviceToken;

  bool get isCurrentDevice =>
      currentDeviceToken != null && token == currentDeviceToken;

  @override
  List<Object?> get props => [token, platform, createdAt, currentDeviceToken];
}
