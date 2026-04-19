import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/value_objects/email_address.dart';
import 'package:colmeia/features/auth/domain/entities/auth_session.dart';
import 'package:colmeia/features/auth/domain/entities/client_account_status.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/client_agents/application/usecases/get_client_agent_token_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_agent_detail_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/remove_client_agent_token_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/save_client_agent_token_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/update_client_agent_profile_use_case.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_catalog_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_token_snapshot.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agent_detail_controller.dart';
import 'package:colmeia/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockAuthController extends Mock implements AuthController {}

class _MockLoadClientAgentDetailUseCase extends Mock
    implements LoadClientAgentDetailUseCase {}

class _MockUpdateClientAgentProfileUseCase extends Mock
    implements UpdateClientAgentProfileUseCase {}

class _MockGetClientAgentTokenUseCase extends Mock
    implements GetClientAgentTokenUseCase {}

class _MockSaveClientAgentTokenUseCase extends Mock
    implements SaveClientAgentTokenUseCase {}

class _MockRemoveClientAgentTokenUseCase extends Mock
    implements RemoveClientAgentTokenUseCase {}

void main() {
  late _MockAuthController auth;
  late _MockLoadClientAgentDetailUseCase loadDetail;
  late _MockUpdateClientAgentProfileUseCase updateProfile;
  late _MockGetClientAgentTokenUseCase getToken;
  late _MockSaveClientAgentTokenUseCase saveToken;
  late _MockRemoveClientAgentTokenUseCase removeToken;
  late ClientAgentDetailController controller;

  const agentId = '11111111-1111-1111-8111-111111111111';
  final agent = ClientAgent(
    agentId: agentId,
    name: 'Agent',
    catalogStatus: AgentCatalogStatus.active,
    connectionStatus: AgentConnectionStatus.online,
    createdAt: DateTime(2026, 4, 4),
    updatedAt: DateTime(2026, 4, 4),
    hasServerClientToken: false,
  );

  final session = AuthSession(
    userId: 'client-1',
    email: EmailAddress('client@example.com'),
    accessToken: 't',
    refreshToken: 'r',
    expiresAt: DateTime(2099),
    accountStatus: ClientAccountStatus.active,
  );

  setUp(() {
    auth = _MockAuthController();
    loadDetail = _MockLoadClientAgentDetailUseCase();
    updateProfile = _MockUpdateClientAgentProfileUseCase();
    getToken = _MockGetClientAgentTokenUseCase();
    saveToken = _MockSaveClientAgentTokenUseCase();
    removeToken = _MockRemoveClientAgentTokenUseCase();
    controller = ClientAgentDetailController(
      authController: auth,
      loadClientAgentDetailUseCase: loadDetail,
      updateClientAgentProfileUseCase: updateProfile,
      getClientAgentTokenUseCase: getToken,
      saveClientAgentTokenUseCase: saveToken,
      removeClientAgentTokenUseCase: removeToken,
    )..activeLocalizations = AppLocalizationsEn();
    when(() => auth.session).thenReturn(session);

    // Default token GET returns "no token configured" so save/remove tests
    // do not need to override it.
    when(
      () => getToken(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
      ),
    ).thenAnswer(
      (_) async => const Success<ClientAgentTokenSnapshot, AppFailure>(
        ClientAgentTokenSnapshot.empty(),
      ),
    );
  });

  tearDown(() {
    controller.dispose();
  });

  group('saveClientAgentToken', () {
    test('persists token via use case and updates field/status', () async {
      when(
        () => saveToken(
          userId: any(named: 'userId'),
          agentId: any(named: 'agentId'),
          clientToken: any(named: 'clientToken'),
        ),
      ).thenAnswer(
        (_) async => const Success<ClientAgentTokenSnapshot, AppFailure>(
          ClientAgentTokenSnapshot(token: 'tok'),
        ),
      );

      await controller.saveClientAgentToken(
        agentId: agentId,
        rawToken: '  tok  ',
      );

      verify(
        () => saveToken(
          userId: 'client-1',
          agentId: agentId,
          clientToken: '  tok  ',
        ),
      ).called(1);
      expect(controller.persistedClientTokenForField, 'tok');
      expect(controller.clientTokenStatus, ClientAgentTokenStatus.configured);
      expect(controller.clientTokenFeedback, isNotNull);
      expect(controller.clientTokenError, isNull);
    });

    test('blank token clears state and reports remove feedback', () async {
      when(
        () => saveToken(
          userId: any(named: 'userId'),
          agentId: any(named: 'agentId'),
          clientToken: any(named: 'clientToken'),
        ),
      ).thenAnswer(
        (_) async => const Success<ClientAgentTokenSnapshot, AppFailure>(
          ClientAgentTokenSnapshot.empty(),
        ),
      );

      await controller.saveClientAgentToken(agentId: agentId, rawToken: '   ');

      expect(controller.persistedClientTokenForField, '');
      expect(controller.clientTokenStatus, ClientAgentTokenStatus.missing);
      expect(controller.clientTokenFeedback, isNotNull);
    });

    test('failure surfaces localized error and keeps previous value', () async {
      when(
        () => saveToken(
          userId: any(named: 'userId'),
          agentId: any(named: 'agentId'),
          clientToken: any(named: 'clientToken'),
        ),
      ).thenAnswer(
        (_) async => const Failure<ClientAgentTokenSnapshot, AppFailure>(
          NetworkFailure(message: 'timeout', userMessage: 'sem rede'),
        ),
      );

      await controller.saveClientAgentToken(agentId: agentId, rawToken: 'x');

      expect(controller.clientTokenError, isNotNull);
      expect(controller.clientTokenFeedback, isNull);
    });
  });

  group('removeClientAgentToken', () {
    test('clears local state and reports feedback on success', () async {
      when(
        () => removeToken(
          userId: any(named: 'userId'),
          agentId: any(named: 'agentId'),
        ),
      ).thenAnswer((_) async => const Success<Unit, AppFailure>(unit));

      await controller.removeClientAgentToken(agentId: agentId);

      expect(controller.persistedClientTokenForField, '');
      expect(controller.clientTokenStatus, ClientAgentTokenStatus.missing);
      expect(controller.clientTokenFeedback, isNotNull);
    });

    test('failure surfaces localized error', () async {
      when(
        () => removeToken(
          userId: any(named: 'userId'),
          agentId: any(named: 'agentId'),
        ),
      ).thenAnswer(
        (_) async => const Failure<Unit, AppFailure>(
          AuthorizationFailure(message: 'forbidden', userMessage: 'no'),
        ),
      );

      await controller.removeClientAgentToken(agentId: agentId);

      expect(controller.clientTokenError, isNotNull);
      expect(controller.clientTokenFeedback, isNull);
    });
  });

  test('saveClientAgentToken without session does not call use case',
      () async {
    when(() => auth.session).thenReturn(null);

    await controller.saveClientAgentToken(agentId: agentId, rawToken: 'x');

    verifyNever(
      () => saveToken(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        clientToken: any(named: 'clientToken'),
      ),
    );
    expect(controller.clientTokenError, isNotNull);
  });

  test('load success refreshes persisted token from server', () async {
    when(
      () => loadDetail(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
      ),
    ).thenAnswer((_) async => Success<ClientAgent, AppFailure>(agent));
    when(
      () => getToken(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
      ),
    ).thenAnswer(
      (_) async => const Success<ClientAgentTokenSnapshot, AppFailure>(
        ClientAgentTokenSnapshot(token: 'stored-token'),
      ),
    );

    await controller.load(agentId);

    // Async refresh of token state happens via unawaited inside load().
    // Wait one microtask so the controller picks up the token snapshot.
    await Future<void>.delayed(Duration.zero);

    verify(() => getToken(userId: 'client-1', agentId: agentId)).called(1);
    expect(controller.persistedClientTokenForField, 'stored-token');
    expect(controller.clientTokenStatus, ClientAgentTokenStatus.configured);
    expect(controller.agent?.agentId, agentId);
  });

  test('clearClientTokenFeedback drops both feedback and error', () async {
    when(
      () => saveToken(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        clientToken: any(named: 'clientToken'),
      ),
    ).thenAnswer(
      (_) async => const Failure<ClientAgentTokenSnapshot, AppFailure>(
        NetworkFailure(message: 'x', userMessage: 'y'),
      ),
    );
    await controller.saveClientAgentToken(agentId: agentId, rawToken: 'x');
    expect(controller.clientTokenError, isNotNull);

    controller.clearClientTokenFeedback();

    expect(controller.clientTokenFeedback, isNull);
    expect(controller.clientTokenError, isNull);
  });
}
