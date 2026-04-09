import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/value_objects/email_address.dart';
import 'package:colmeia/features/auth/domain/entities/auth_session.dart';
import 'package:colmeia/features/auth/domain/entities/client_account_status.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_agent_detail_use_case.dart';
import 'package:colmeia/features/client_agents/data/storage/local_agent_client_token_store.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_catalog_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agent_detail_controller.dart';
import 'package:colmeia/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockAuthController extends Mock implements AuthController {}

class _MockLoadClientAgentDetailUseCase extends Mock
    implements LoadClientAgentDetailUseCase {}

class _MockLocalAgentClientTokenStore extends Mock
    implements LocalAgentClientTokenStore {}

void main() {
  late _MockAuthController auth;
  late _MockLoadClientAgentDetailUseCase loadDetail;
  late _MockLocalAgentClientTokenStore tokenStore;
  late ClientAgentDetailController controller;

  const agentId = '11111111-1111-1111-8111-111111111111';
  final agent = ClientAgent(
    agentId: agentId,
    name: 'Agent',
    catalogStatus: AgentCatalogStatus.active,
    connectionStatus: AgentConnectionStatus.online,
    createdAt: DateTime(2026, 4, 4),
    updatedAt: DateTime(2026, 4, 4),
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
    tokenStore = _MockLocalAgentClientTokenStore();
    controller = ClientAgentDetailController(
      authController: auth,
      clientTokenStore: tokenStore,
      loadClientAgentDetailUseCase: loadDetail,
    )..activeLocalizations = AppLocalizationsEn();
    when(() => auth.session).thenReturn(session);
  });

  tearDown(() {
    controller.dispose();
  });

  test('saveLocalClientToken writes trimmed token and updates field', () async {
    when(
      () => tokenStore.write(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        clientToken: any(named: 'clientToken'),
      ),
    ).thenAnswer((_) async {});

    await controller.saveLocalClientToken(
      agentId: agentId,
      rawToken: '  tok  ',
    );

    verify(
      () => tokenStore.write(
        userId: 'client-1',
        agentId: agentId,
        clientToken: 'tok',
      ),
    ).called(1);
    expect(controller.persistedLocalClientTokenForField, 'tok');
    expect(controller.localClientTokenFeedback, isNotNull);
  });

  test('saveLocalClientToken with blank token deletes storage', () async {
    when(
      () => tokenStore.delete(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
      ),
    ).thenAnswer((_) async {});

    await controller.saveLocalClientToken(agentId: agentId, rawToken: '   ');

    verify(
      () => tokenStore.delete(userId: 'client-1', agentId: agentId),
    ).called(1);
    expect(controller.persistedLocalClientTokenForField, '');
  });

  test('removeLocalClientToken deletes storage', () async {
    when(
      () => tokenStore.delete(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
      ),
    ).thenAnswer((_) async {});

    await controller.removeLocalClientToken(agentId: agentId);

    verify(
      () => tokenStore.delete(userId: 'client-1', agentId: agentId),
    ).called(1);
    expect(controller.persistedLocalClientTokenForField, '');
  });

  test('saveLocalClientToken without session does not call store', () async {
    when(() => auth.session).thenReturn(null);

    await controller.saveLocalClientToken(agentId: agentId, rawToken: 'x');

    verifyNever(
      () => tokenStore.write(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        clientToken: any(named: 'clientToken'),
      ),
    );
    expect(controller.localClientTokenFeedback, isNotNull);
  });

  test('load success refreshes persisted token from store', () async {
    when(
      () => loadDetail(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
      ),
    ).thenAnswer((_) async => Success<ClientAgent, AppFailure>(agent));
    when(
      () => tokenStore.read(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
      ),
    ).thenAnswer((_) async => 'stored-token');

    await controller.load(agentId);

    verify(
      () => tokenStore.read(userId: 'client-1', agentId: agentId),
    ).called(1);
    expect(
      controller.persistedLocalClientTokenForField,
      'stored-token',
    );
    expect(controller.agent?.agentId, agentId);
  });
}
