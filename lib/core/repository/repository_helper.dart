import 'package:boklo/core/error/failures.dart';
import 'package:fpdart/fpdart.dart';

Future<Either<Failure, T>> performNetworkOperation<T>({
  required Future<bool> Function() isConnected,
  required Future<T> Function() networkCall,
  required Future<void> Function(T data) cacheData,
  required Future<T> Function() localCall,
}) async {
  if (await isConnected()) {
    try {
      final remoteData = await networkCall();
      await cacheData(remoteData);
      return Right(remoteData);
    } catch (e) {
      if (e is Failure) {
        return Left(e);
      }
      return Left(UnknownFailure(e.toString()));
    }
  } else {
    try {
      final localData = await localCall();
      return Right(localData);
    } catch (e) {
      return const Left(CacheFailure('No local data found'));
    }
  }
}
