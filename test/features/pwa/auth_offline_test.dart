import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:colmeia/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:colmeia/features/auth/data/models/auth_session_model.dart';
import 'package:colmeia/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Local extends Mock implements AuthLocalDataSource {}

class _Remote extends Mock implements AuthRemoteDataSource {}

class _Cache extends Mock implements AppCacheStore {}

void main() {
  late _Local local;
  late _Remote remote;
  late _Cache cache;
  late AuthSessionModel session;
  setUp(() {
    local = _Local();
    remote = _Remote();
    cache = _Cache();
    session = AuthSessionModel(
      userId: 'user',
      email: 'test@example.test',
      accessToken: 'expired',
      refreshToken: 'refresh',
      expiresAt: DateTime.utc(2020),
    );
    when(local.readSession).thenAnswer((_) async => session);
    when(local.clearSession).thenAnswer((_) async {});
    when(cache.clearAll).thenAnswer((_) async {});
  });
  AuthRepositoryImpl repository({
    Future<bool?> Function(String)? offline,
    Future<void> Function(String)? cleanup,
  }) => AuthRepositoryImpl(
    localDataSource: local,
    remoteDataSource: remote,
    appCacheStore: cache,
    offlineSessionAllowed: offline,
    beforeLocalLogout: cleanup,
  );
  test(
    'offline authorization restores local access without a remote refresh',
    () async {
      expect(
        (await repository(
          offline: (_) async => true,
        ).restoreSession()).isSuccess(),
        isTrue,
      );
      verifyZeroInteractions(remote);
      verifyNever(local.clearSession);
    },
  );
  test('expired offline grant blocks access without deleting the persisted session', () async {
    expect(
      (await repository(
        offline: (_) async => false,
      ).restoreSession()).isError(),
      isTrue,
    );
    verifyZeroInteractions(remote);
    verifyNever(local.clearSession);
  });
  test('transient refresh failure preserves persisted credentials', () async {
    when(() => remote.refreshSession(currentSession: session)).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/refresh'),
        type: DioExceptionType.connectionError,
      ),
    );
    expect((await repository().restoreSession()).isError(), isTrue);
    verifyNever(local.clearSession);
  });
  test('logout still clears local access when PWA cleanup fails', () async {
    when(() => remote.logout(refreshToken: 'refresh')).thenAnswer((_) async {});
    expect(
      (await repository(
        cleanup: (_) async => throw StateError('storage unavailable'),
      ).logout()).isSuccess(),
      isTrue,
    );
    verify(local.clearSession).called(1);
    verify(cache.clearAll).called(1);
  });
}
