// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:boklo/core/di/app_module.dart' as _i11;
import 'package:boklo/features/auth/data/datasources/auth_remote_data_source.dart'
    as _i649;
import 'package:boklo/features/auth/data/repositories/auth_repository_impl.dart'
    as _i560;
import 'package:boklo/features/auth/domain/repositories/auth_repository.dart'
    as _i46;
import 'package:boklo/features/auth/presentation/bloc/auth_bloc.dart' as _i895;
import 'package:dio/dio.dart' as _i361;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final appModule = _$AppModule();
    gh.lazySingleton<_i361.Dio>(() => appModule.dio);
    gh.lazySingleton<_i558.FlutterSecureStorage>(
      () => appModule.flutterSecureStorage,
    );
    gh.lazySingleton<_i649.AuthRemoteDataSource>(
      () => _i649.AuthRemoteDataSourceImpl(),
    );
    gh.lazySingleton<_i46.AuthRepository>(
      () => _i560.AuthRepositoryImpl(gh<_i649.AuthRemoteDataSource>()),
    );
    gh.factory<_i895.AuthBloc>(() => _i895.AuthBloc(gh<_i46.AuthRepository>()));
    return this;
  }
}

class _$AppModule extends _i11.AppModule {}
