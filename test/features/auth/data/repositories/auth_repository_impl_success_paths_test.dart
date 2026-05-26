import 'package:checks/checks.dart';
import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:colmeia/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:colmeia/features/auth/data/models/auth_session_model.dart';
import 'package:colmeia/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:colmeia/features/auth/domain/entities/client_registration_status.dart';
import 'package:colmeia/features/auth/domain/entities/client_registration_submission.dart';
import 'package:colmeia/features/user_context/domain/entities/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockAuthLocalDataSource extends Mock implements AuthLocalDataSource {}

class _MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class _MockAppCacheStore extends Mock implements AppCacheStore {}

class _FakeAuthSessionModel extends Fake implements AuthSessionModel {}

void main() {
  late _MockAuthLocalDataSource local;
  late _MockAuthRemoteDataSource remote;
  late _MockAppCacheStore cache;
  late AuthRepositoryImpl repository;

  AuthSessionModel buildSession({
    String userId = 'client-1',
    String email = 'client@corp.com',
    DateTime? expiresAt,
  }) {
    return AuthSessionModel(
      userId: userId,
      email: email,
      accessToken: 'access-token',
      refreshToken: 'refresh-token',
      expiresAt:
          expiresAt ?? DateTime.now().add(const Duration(hours: 1)),
    );
  }

  setUpAll(() {
    registerFallbackValue(_FakeAuthSessionModel());
  });

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

  group('login', () {
    test('returns Success with auth session and persists it locally',
        () async {
      final session = buildSession();
      when(
        () => remote.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => session);
      when(() => local.saveSession(any())).thenAnswer((_) async {});

      final result = await repository.login(
        email: 'client@corp.com',
        password: 'pa55w0rd',
      );

      check(result.isSuccess()).isTrue();
      check(result.getOrNull()?.userId).equals('client-1');
      verify(() => local.saveSession(session)).called(1);
    });
  });

  group('register', () {
    test('returns Success with registration submission on happy path',
        () async {
      const submission = ClientRegistrationSubmission(
        status: ClientRegistrationStatus.pending,
        message: 'Pending approval',
        approvalToken: 'token-abc',
      );
      when(
        () => remote.register(
          ownerEmail: any(named: 'ownerEmail'),
          firstName: any(named: 'firstName'),
          lastName: any(named: 'lastName'),
          email: any(named: 'email'),
          password: any(named: 'password'),
          mobile: any(named: 'mobile'),
        ),
      ).thenAnswer((_) async => submission);

      final result = await repository.register(
        ownerEmail: 'owner@corp.com',
        firstName: 'Alice',
        lastName: 'Doe',
        email: 'client@corp.com',
        password: 'pa55w0rd',
      );

      check(result.isSuccess()).isTrue();
      check(result.getOrNull()?.status)
          .equals(ClientRegistrationStatus.pending);
      check(result.getOrNull()?.approvalToken).equals('token-abc');
    });
  });

  group('restoreSession', () {
    test('returns local session when stored token is not expired', () async {
      final session = buildSession(
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );
      when(() => local.readSession()).thenAnswer((_) async => session);

      final result = await repository.restoreSession();

      check(result.isSuccess()).isTrue();
      check(result.getOrNull()?.userId).equals('client-1');
      verifyNever(() => remote.refreshSession(currentSession: any(named: 'currentSession')));
    });

    test('refreshes the session remotely when stored token is expired',
        () async {
      final expiredSession = buildSession(
        expiresAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );
      final refreshedSession = buildSession(
        expiresAt: DateTime.now().add(const Duration(hours: 2)),
      );
      when(() => local.readSession()).thenAnswer((_) async => expiredSession);
      when(
        () => remote.refreshSession(
          currentSession: any(named: 'currentSession'),
        ),
      ).thenAnswer((_) async => refreshedSession);
      when(() => local.saveSession(any())).thenAnswer((_) async {});

      final result = await repository.restoreSession();

      check(result.isSuccess()).isTrue();
      check(result.getOrNull()?.userId).equals('client-1');
      verify(() => local.saveSession(refreshedSession)).called(1);
    });
  });

  group('readCurrentUserProfile', () {
    test('returns Success with user profile when stored session exists',
        () async {
      const profile = UserProfile(
        id: 'client-1',
        name: 'Alice Doe',
        roleLabel: 'Owner',
      );
      when(() => local.readSession()).thenAnswer((_) async => buildSession());
      when(() => remote.readCurrentUserProfile()).thenAnswer(
        (_) async => profile,
      );

      final result = await repository.readCurrentUserProfile();

      check(result.isSuccess()).isTrue();
      check(result.getOrNull()?.id).equals('client-1');
      check(result.getOrNull()?.name).equals('Alice Doe');
    });
  });

  group('changePassword', () {
    test('returns Success(unit) when remote password change succeeds',
        () async {
      when(() => local.readSession()).thenAnswer((_) async => buildSession());
      when(
        () => remote.changePassword(
          currentPassword: any(named: 'currentPassword'),
          newPassword: any(named: 'newPassword'),
        ),
      ).thenAnswer((_) async {});

      final result = await repository.changePassword(
        currentPassword: 'old-pa55',
        newPassword: 'new-pa55',
      );

      check(result.isSuccess()).isTrue();
      check(result.getOrNull()).equals(unit);
      verify(
        () => remote.changePassword(
          currentPassword: 'old-pa55',
          newPassword: 'new-pa55',
        ),
      ).called(1);
    });
  });
}
