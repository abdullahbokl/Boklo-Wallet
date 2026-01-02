import 'package:boklo/core/error/app_error.dart';
import 'package:boklo/core/utils/result.dart';

Future<Result<T>> performNetworkOperation<T>({
  required Future<bool> Function() isConnected,
  required Future<T> Function() networkCall,
  required Future<void> Function(T data) cacheData,
  required Future<T> Function() localCall,
}) async {
  if (await isConnected()) {
    try {
      final remoteData = await networkCall();
      await cacheData(remoteData);
      return Success(remoteData);
    } catch (e) {
      if (e is AppError) {
        return Failure(e);
      }
      return Failure(UnknownError(e.toString()));
    }
  } else {
    try {
      final localData = await localCall();
      return Success(localData);
    } catch (e) {
      return const Failure(CacheError('No local data found'));
    }
  }
}
