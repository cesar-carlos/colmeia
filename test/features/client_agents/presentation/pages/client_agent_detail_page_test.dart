import 'dart:async';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/value_objects/email_address.dart';
import 'package:colmeia/features/agent_meta/application/usecases/discover_agent_rpc_methods_use_case.dart';
import 'package:colmeia/features/agent_meta/application/usecases/load_client_token_policy_use_case.dart';
import 'package:colmeia/features/agent_meta/application/usecases/refresh_agent_profile_use_case.dart';
import 'package:colmeia/features/agent_meta/domain/entities/agent_profile_snapshot.dart';
import 'package:colmeia/features/agent_meta/domain/entities/agent_rpc_descriptor.dart';
import 'package:colmeia/features/auth/domain/entities/auth_session.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/client_agents/application/usecases/get_client_agent_token_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_agent_detail_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/persist_client_agent_profile_snapshot_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/remove_client_agent_token_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/save_client_agent_token_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/update_client_agent_profile_use_case.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_catalog_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_token_snapshot.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agent_detail_controller.dart';
import 'package:colmeia/features/client_agents/presentation/pages/client_agent_detail_page.dart';
import 'package:colmeia/l10n/app_localizations_pt.dart';
import 'package:colmeia/shared/identity/client_account_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

import '../../../../support/localized_test_app.dart';

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

class _MockPersistClientAgentProfileSnapshotUseCase extends Mock
    implements PersistClientAgentProfileSnapshotUseCase {}

ClientAgent _agent(String agentId) {
  return ClientAgent(
    agentId: agentId,
    name: 'Agent $agentId',
    catalogStatus: AgentCatalogStatus.active,
    connectionStatus: AgentConnectionStatus.online,
    createdAt: DateTime.utc(2026, 4, 4),
    updatedAt: DateTime.utc(2026, 4, 4),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const AgentProfileSnapshot(
        agentId: 'fallback-agent',
        name: 'Fallback',
        profileVersion: 1,
      ),
    );
  });

  testWidgets('localizes typed controller errors on the detail page', (
    tester,
  ) async {
    final authController = _MockAuthController();
    when(() => authController.session).thenReturn(null);
    final persistSnapshot = _MockPersistClientAgentProfileSnapshotUseCase();
    when(
      () => persistSnapshot(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        snapshot: any(named: 'snapshot'),
      ),
    ).thenAnswer((_) async => const Success<Unit, AppFailure>(unit));

    final controller = ClientAgentDetailController(
      authController: authController,
      loadClientAgentDetailUseCase: _MockLoadClientAgentDetailUseCase(),
      updateClientAgentProfileUseCase: _MockUpdateClientAgentProfileUseCase(),
      getClientAgentTokenUseCase: _MockGetClientAgentTokenUseCase(),
      saveClientAgentTokenUseCase: _MockSaveClientAgentTokenUseCase(),
      removeClientAgentTokenUseCase: _MockRemoveClientAgentTokenUseCase(),
      persistClientAgentProfileSnapshotUseCase: persistSnapshot,
      refreshAgentProfileUseCase: _MockRefreshAgentProfileUseCase(),
      loadClientTokenPolicyUseCase: _MockLoadClientTokenPolicyUseCase(),
      discoverAgentRpcMethodsUseCase: _MockDiscoverAgentRpcMethodsUseCase(),
    );

    await tester.pumpWidget(
      LocalizedTestApp(
        child: ClientAgentDetailPage(
          agentId: '11111111-1111-1111-8111-111111111111',
          controller: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(AppLocalizationsPt().clientAgentDetailSessionUnavailable),
      findsOneWidget,
    );
  });

  testWidgets(
    'preserves token field typing while the async token load finishes',
    (tester) async {
      final authController = _MockAuthController();
      final loadDetail = _MockLoadClientAgentDetailUseCase();
      final getToken = _MockGetClientAgentTokenUseCase();
      final tokenCompleter = Completer<AppResult<ClientAgentTokenSnapshot>>();
      const agentId = '11111111-1111-1111-8111-111111111111';

      when(
        () => authController.session,
      ).thenReturn(
        AuthSession(
          userId: 'client-1',
          email: EmailAddress('client@example.com'),
          accessToken: 'token',
          refreshToken: 'refresh',
          expiresAt: DateTime(2099),
          accountStatus: ClientAccountStatus.active,
        ),
      );
      when(
        () => loadDetail(
          userId: any(named: 'userId'),
          agentId: any(named: 'agentId'),
        ),
      ).thenAnswer(
        (_) async => Success<ClientAgent, AppFailure>(_agent(agentId)),
      );
      when(
        () => getToken(
          userId: any(named: 'userId'),
          agentId: any(named: 'agentId'),
        ),
      ).thenAnswer((_) => tokenCompleter.future);
      final discover = _MockDiscoverAgentRpcMethodsUseCase();
      final persistSnapshot = _MockPersistClientAgentProfileSnapshotUseCase();
      when(() => discover(agentId: any(named: 'agentId'))).thenAnswer(
        (_) async => const Success<AgentRpcDescriptor, AppFailure>(
          AgentRpcDescriptor.empty(),
        ),
      );
      when(
        () => persistSnapshot(
          userId: any(named: 'userId'),
          agentId: any(named: 'agentId'),
          snapshot: any(named: 'snapshot'),
        ),
      ).thenAnswer((_) async => const Success<Unit, AppFailure>(unit));

      final controller = ClientAgentDetailController(
        authController: authController,
        loadClientAgentDetailUseCase: loadDetail,
        updateClientAgentProfileUseCase: _MockUpdateClientAgentProfileUseCase(),
        getClientAgentTokenUseCase: getToken,
        saveClientAgentTokenUseCase: _MockSaveClientAgentTokenUseCase(),
        removeClientAgentTokenUseCase: _MockRemoveClientAgentTokenUseCase(),
        persistClientAgentProfileSnapshotUseCase: persistSnapshot,
        refreshAgentProfileUseCase: _MockRefreshAgentProfileUseCase(),
        loadClientTokenPolicyUseCase: _MockLoadClientTokenPolicyUseCase(),
        discoverAgentRpcMethodsUseCase: discover,
      );

      await tester.pumpWidget(
        LocalizedTestApp(
          child: ClientAgentDetailPage(
            agentId: agentId,
            controller: controller,
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      final tokenField = find.byType(TextFormField).last;
      await tester.enterText(tokenField, 'local-typing');
      await tester.pump();

      tokenCompleter.complete(
        const Success<ClientAgentTokenSnapshot, AppFailure>(
          ClientAgentTokenSnapshot(token: 'server-token'),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('local-typing'), findsOneWidget);
      expect(find.text('server-token'), findsNothing);
    },
  );

  testWidgets('renders refresh-from-agent success feedback on the page', (
    tester,
  ) async {
    final authController = _MockAuthController();
    final loadDetail = _MockLoadClientAgentDetailUseCase();
    final getToken = _MockGetClientAgentTokenUseCase();
    final refreshFromAgent = _MockRefreshAgentProfileUseCase();
    final discover = _MockDiscoverAgentRpcMethodsUseCase();
    final persistSnapshot = _MockPersistClientAgentProfileSnapshotUseCase();
    const agentId = '11111111-1111-1111-8111-111111111111';

    when(
      () => authController.session,
    ).thenReturn(
      AuthSession(
        userId: 'client-1',
        email: EmailAddress('client@example.com'),
        accessToken: 'token',
        refreshToken: 'refresh',
        expiresAt: DateTime(2099),
        accountStatus: ClientAccountStatus.active,
      ),
    );
    when(
      () => loadDetail(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
      ),
    ).thenAnswer(
      (_) async => Success<ClientAgent, AppFailure>(_agent(agentId)),
    );
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
    when(() => discover(agentId: any(named: 'agentId'))).thenAnswer(
      (_) async => const Success<AgentRpcDescriptor, AppFailure>(
        AgentRpcDescriptor(methods: <String>{'agent.getProfile'}),
      ),
    );
    when(
      () => refreshFromAgent(
        agentId: any(named: 'agentId'),
        clientToken: any(named: 'clientToken'),
      ),
    ).thenAnswer(
      (_) async => const Success<AgentProfileSnapshot, AppFailure>(
        AgentProfileSnapshot(
          agentId: agentId,
          name: 'Fresh Agent',
          profileVersion: 5,
        ),
      ),
    );
    when(
      () => persistSnapshot(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        snapshot: any(named: 'snapshot'),
      ),
    ).thenAnswer((_) async => const Success<Unit, AppFailure>(unit));

    final controller = ClientAgentDetailController(
      authController: authController,
      loadClientAgentDetailUseCase: loadDetail,
      updateClientAgentProfileUseCase: _MockUpdateClientAgentProfileUseCase(),
      getClientAgentTokenUseCase: getToken,
      saveClientAgentTokenUseCase: _MockSaveClientAgentTokenUseCase(),
      removeClientAgentTokenUseCase: _MockRemoveClientAgentTokenUseCase(),
      persistClientAgentProfileSnapshotUseCase: persistSnapshot,
      refreshAgentProfileUseCase: refreshFromAgent,
      loadClientTokenPolicyUseCase: _MockLoadClientTokenPolicyUseCase(),
      discoverAgentRpcMethodsUseCase: discover,
    );

    await tester.pumpWidget(
      LocalizedTestApp(
        child: ClientAgentDetailPage(agentId: agentId, controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.text(AppLocalizationsPt().clientAgentDetailRefreshFromAgent),
    );
    await tester.pump();
    await tester.pump();

    expect(
      find.text(AppLocalizationsPt().clientAgentDetailRefreshFromAgentSuccess),
      findsOneWidget,
    );
  });
}
