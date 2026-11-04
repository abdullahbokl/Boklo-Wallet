import 'package:boklo/core/error/failures.dart';
import 'package:boklo/features/settings/data/datasources/session_remote_data_source.dart';
import 'package:boklo/features/settings/domain/entities/device_session.dart';
import 'package:fpdart/fpdart.dart';
import 'package:injectable/injectable.dart';

abstract class SessionRepository {
  /// All registered devices, annotated with which one is this device.
  Future<Either<Failure, List<DeviceSession>>> listDevices();

  /// Revokes every refresh token and push registration. The local session
  /// is signed out by the caller immediately afterwards.
  Future<Either<Failure, void>> revokeAllSessions();
}

@LazySingleton(as: SessionRepository)
class SessionRepositoryImpl implements SessionRepository {
  SessionRepositoryImpl(this._dataSource);

  final SessionRemoteDataSource _dataSource;

  @override
  Future<Either<Failure, List<DeviceSession>>> listDevices() async {
    try {
      final devices = await _dataSource.listDevices();
      final currentToken = await _dataSource.currentDeviceToken();

      return Right(
        devices
            .map(
              (d) => DeviceSession(
                token: d.token,
                platform: d.platform,
                createdAt: d.createdAt,
                currentDeviceToken: currentToken,
              ),
            )
            .toList(),
      );
    } on Object catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> revokeAllSessions() async {
    try {
      await _dataSource.revokeAllSessions();
      return const Right(null);
    } on Object catch (e) {
      return Left(UnknownFailure(e.toString()));
    }
  }
}
