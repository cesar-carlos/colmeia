import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:colmeia/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:colmeia/features/auth/data/models/auth_session_model.dart';
import 'package:colmeia/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

class _MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class _MockAppCacheStore extends Mock implements AppCacheStore {}

void main() {
  late _MockAuthLocalDataSource local;
  late _MockAuthRemoteDataSource remote;
  late _MockAppCacheStore cache;
  late AuthRepositoryImpl repository;

  setUp(() {
    local = _MockAuthLocalDataSource();
    remote = _MockAuthRemoteDataSource();
    cache = _MockAppCacheStore();
    repository = AuthRepositoryImpl(
      localDataSource: local,
      remoteDataSource: remote,
      appCacheStore: cache,
    );
  });

  test(
    'logout should clear app cache after local session is cleared',
    () async {
      final session = AuthSessionModel(
        userId: 'u1',
        email: 'u1@corp.com',
        accessToken: 'at',
        refreshToken: 'rt',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      when(() => local.readSession()).thenAnswer((_) async => session);
      when(
        () => remote.logout(accessToken: any(named: 'accessToken')),
      ).thenAnswer((_) async {});
      when(() => local.clearSession()).thenAnswer((_) async {});
      when(() => cache.clearAll()).thenAnswer((_) async {});

      final result = await repository.logout();

      expect(result.isSuccess(), isTrue);
      verify(() => local.readSession()).called(1);
      verify(
        () => remote.logout(accessToken: session.accessToken),
      ).called(1);
      verify(() => local.clearSession()).called(1);
      verify(() => cache.clearAll()).called(1);
    },
  );
}
