import 'package:checks/checks.dart';
import 'package:colmeia/core/network/auth_refresh_coordinator.dart';
import 'package:colmeia/core/network/auth_session_accessor.dart';
import 'package:colmeia/core/network/auth_session_events.dart';
import 'package:colmeia/core/socket/socket_auth_token_provider.dart';
import 'package:colmeia/features/auth/data/models/auth_session_model.dart';
import 'package:colmeia/shared/identity/client_account_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSessionAccessor extends Mock implements AuthSessionAccessor {}

class _MockRefreshCoordinator extends Mock implements AuthRefreshCoordinator {}

void main() {
  late _MockSessionAccessor sessionAccessor;
  late _MockRefreshCoordinator refreshCoordinator;
  late AuthSessionEvents sessionEvents;
  late SessionSocketAuthTokenProvider provider;

  setUp(() {
    sessionAccessor = _MockSessionAccessor();
    refreshCoordinator = _MockRefreshCoordinator();
    sessionEvents = AuthSessionEvents();
    provider = SessionSocketAuthTokenProvider(
      sessionAccessor: sessionAccessor,
      refreshCoordinator: refreshCoordinator,
      sessionEvents: sessionEvents,
    );
  });

  tearDown(() async {
    await sessionEvents.dispose();
  });

  AuthSessionModel session({String accessToken = 'access-token'}) {
    return AuthSessionModel(
      userId: 'user-1',
      email: 'tester@example.com',
      accessToken: accessToken,
      refreshToken: 'refresh-token',
      expiresAt: DateTime.utc(2026, 12, 31),
      accountStatus: ClientAccountStatus.active,
    );
  }

  group('SessionSocketAuthTokenProvider.readAccessToken', () {
    test('returns trimmed access token from session accessor', () async {
      when(() => sessionAccessor.read()).thenAnswer(
        (_) async => session(),
      );

      final token = await provider.readAccessToken();

      check(token).equals('access-token');
    });

    test('returns null when session is missing', () async {
      when(() => sessionAccessor.read()).thenAnswer((_) async => null);

      final token = await provider.readAccessToken();

      check(token).isNull();
    });

    test('returns null when access token is empty', () async {
      when(() => sessionAccessor.read()).thenAnswer(
        (_) async => session(accessToken: ''),
      );

      final token = await provider.readAccessToken();

      check(token).isNull();
    });
  });

  group('SessionSocketAuthTokenProvider.refreshAccessToken', () {
    test('delegates to AuthRefreshCoordinator', () async {
      when(() => refreshCoordinator.refreshAccessToken()).thenAnswer(
        (_) async => 'refreshed-token',
      );

      final token = await provider.refreshAccessToken();

      check(token).equals('refreshed-token');
      verify(() => refreshCoordinator.refreshAccessToken()).called(1);
    });
  });

  group('SessionSocketAuthTokenProvider.sessionInvalidations', () {
    test('emits only on invalidated session events', () async {
      final events = <void>[];
      final sub = provider.sessionInvalidations().listen(events.add);

      sessionEvents
        ..notifySessionRenewed()
        ..notifyInvalidated()
        ..notifyInvalidated();

      await Future<void>.delayed(Duration.zero);

      check(events.length).equals(2);
      await sub.cancel();
    });
  });
}
