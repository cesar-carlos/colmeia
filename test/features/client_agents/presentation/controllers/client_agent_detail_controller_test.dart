import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/retry_after_gate.dart';
import 'package:colmeia/core/value_objects/email_address.dart';
import 'package:colmeia/features/agent_meta/application/usecases/discover_agent_rpc_methods_use_case.dart';
import 'package:colmeia/features/agent_meta/application/usecases/load_client_token_policy_use_case.dart';
import 'package:colmeia/features/agent_meta/application/usecases/refresh_agent_profile_use_case.dart';
import 'package:colmeia/features/agent_meta/domain/entities/agent_rpc_descriptor.dart';
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

class _MockRefreshAgentProfileUseCase extends Mock
    implements RefreshAgentProfileUseCase {}

class _MockLoadClientTokenPolicyUseCase extends Mock
    implements LoadClientTokenPolicyUseCase {}

class _MockDiscoverAgentRpcMethodsUseCase extends Mock
    implements DiscoverAgentRpcMethodsUseCase {}

void main() {
  late _MockAuthController auth;
  late _MockLoadClientAgentDetailUseCase loadDetail;
  late _MockUpdateClientAgentProfileUseCase updateProfile;
  late _MockGetClientAgentTokenUseCase getToken;
  late _MockSaveClientAgentTokenUseCase saveToken;
  late _MockRemoveClientAgentTokenUseCase removeToken;
  late _MockRefreshAgentProfileUseCase refreshFromAgent;
  late _MockLoadClientTokenPolicyUseCase loadPolicy;
  late _MockDiscoverAgentRpcMethodsUseCase discoverRpc;
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
    refreshFromAgent = _MockRefreshAgentProfileUseCase();
    loadPolicy = _MockLoadClientTokenPolicyUseCase();
    discoverRpc = _MockDiscoverAgentRpcMethodsUseCase();
    when(() => discoverRpc(agentId: any(named: 'agentId'))).thenAnswer(
      (_) async => const Success<AgentRpcDescriptor, AppFailure>(
        AgentRpcDescriptor.empty(),
      ),
    );
    controller = ClientAgentDetailController(
      authController: auth,
      loadClientAgentDetailUseCase: loadDetail,
      updateClientAgentProfileUseCase: updateProfile,
      getClientAgentTokenUseCase: getToken,
      saveClientAgentTokenUseCase: saveToken,
      removeClientAgentTokenUseCase: removeToken,
      refreshAgentProfileUseCase: refreshFromAgent,
      loadClientTokenPolicyUseCase: loadPolicy,
      discoverAgentRpcMethodsUseCase: discoverRpc,
    );
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

  test('saveClientAgentToken without session does not call use case', () async {
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

  group('agent_meta integration', () {
    test('agentSupportsRpcMethod is permissive when descriptor is empty', () {
      // Default state: no descriptor loaded yet -> hide nothing.
      expect(controller.agentSupportsRpcMethod('agent.getProfile'), isTrue);
      expect(
        controller.agentSupportsRpcMethod('client_token.getPolicy'),
        isTrue,
      );
    });

    test(
      'refreshFromAgent surfaces unsupported error when method is missing '
      'from rpc.discover',
      () async {
        when(() => discoverRpc(agentId: any(named: 'agentId'))).thenAnswer(
          (_) async => const Success<AgentRpcDescriptor, AppFailure>(
            AgentRpcDescriptor(methods: <String>{'sql.execute'}),
          ),
        );
        when(
          () => loadDetail(
            userId: any(named: 'userId'),
            agentId: any(named: 'agentId'),
          ),
        ).thenAnswer((_) async => Success<ClientAgent, AppFailure>(agent));

        await controller.load(agentId);
        // Wait for the unawaited discover.
        await Future<void>.delayed(Duration.zero);

        await controller.refreshFromAgent(agentId: agentId);

        expect(controller.refreshFromAgentError, isNotNull);
        verifyNever(
          () => refreshFromAgent(
            agentId: any(named: 'agentId'),
            clientToken: any(named: 'clientToken'),
          ),
        );
      },
    );

    test(
      'loadClientTokenPolicy is short-circuited when agent does not '
      'advertise client_token.getPolicy',
      () async {
        when(() => discoverRpc(agentId: any(named: 'agentId'))).thenAnswer(
          (_) async => const Success<AgentRpcDescriptor, AppFailure>(
            AgentRpcDescriptor(methods: <String>{'sql.execute'}),
          ),
        );
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
            ClientAgentTokenSnapshot(token: 'tok'),
          ),
        );

        await controller.load(agentId);
        await Future<void>.delayed(Duration.zero);

        await controller.loadClientTokenPolicy(agentId: agentId);

        expect(controller.clientTokenPolicyUnsupported, isTrue);
        expect(controller.clientTokenPolicy, isNull);
        verifyNever(
          () => loadPolicy(
            agentId: any(named: 'agentId'),
            clientToken: any(named: 'clientToken'),
          ),
        );
      },
    );
  });

  group('Retry-After integration', () {
    test(
      'failure carrying NetworkFailure.retryAfter arms the cool-down gate',
      () async {
        when(
          () => saveToken(
            userId: any(named: 'userId'),
            agentId: any(named: 'agentId'),
            clientToken: any(named: 'clientToken'),
          ),
        ).thenAnswer(
          (_) async => const Failure<ClientAgentTokenSnapshot, AppFailure>(
            NetworkFailure(
              message: 'rate limited',
              userMessage: 'devagar',
              retryAfter: Duration(seconds: 7),
            ),
          ),
        );

        expect(controller.isOnRetryCooldown, isFalse);

        await controller.saveClientAgentToken(agentId: agentId, rawToken: 'x');

        expect(controller.isOnRetryCooldown, isTrue);
        expect(
          controller.retryAfterGate.remaining?.inSeconds,
          greaterThanOrEqualTo(6),
        );
      },
    );

    test(
      'failure without retryAfter leaves the gate open',
      () async {
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

        expect(controller.isOnRetryCooldown, isFalse);
        expect(controller.retryAfterGate.remaining, isNull);
      },
    );

    test(
      'gate forwards listener notifications through the controller',
      () async {
        var notifyCount = 0;
        controller.addListener(() => notifyCount++);

        // Inject the gate manually via a fresh controller so we can drive
        // it without going through a failure path.
        final dedicatedGate = RetryAfterGate(
          tickInterval: const Duration(milliseconds: 50),
        );
        final dedicatedController = ClientAgentDetailController(
          authController: auth,
          loadClientAgentDetailUseCase: loadDetail,
          updateClientAgentProfileUseCase: updateProfile,
          getClientAgentTokenUseCase: getToken,
          saveClientAgentTokenUseCase: saveToken,
          removeClientAgentTokenUseCase: removeToken,
          refreshAgentProfileUseCase: refreshFromAgent,
          loadClientTokenPolicyUseCase: loadPolicy,
          discoverAgentRpcMethodsUseCase: discoverRpc,
          retryAfterGate: dedicatedGate,
        );
        addTearDown(dedicatedController.dispose);

        var dedicatedNotifyCount = 0;
        dedicatedController.addListener(() => dedicatedNotifyCount++);

        dedicatedGate.arm(const Duration(seconds: 2));
        expect(dedicatedNotifyCount, greaterThanOrEqualTo(1));
        expect(dedicatedController.isOnRetryCooldown, isTrue);

        // The original `controller` (with its own gate) is untouched.
        expect(notifyCount, 0);
      },
    );
  });
}
