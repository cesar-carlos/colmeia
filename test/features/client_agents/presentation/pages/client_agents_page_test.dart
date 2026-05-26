import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/value_objects/email_address.dart';
import 'package:colmeia/features/auth/domain/entities/auth_session.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/client_agents/application/client_agent_token_draft_store.dart';
import 'package:colmeia/features/client_agents/application/client_agents_page_session_service.dart';
import 'package:colmeia/features/client_agents/application/usecases/approve_owner_access_request_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/discard_queued_client_agent_request_access_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/get_client_agent_token_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_access_requests_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_access_status_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_agent_detail_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_approved_agents_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_managed_agents_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_owner_access_requests_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_owner_approved_clients_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/probe_client_approved_agent_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/queue_client_agent_remove_access_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/queue_client_agent_request_access_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/read_pending_client_agent_actions_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/reject_owner_access_request_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/retry_client_access_request_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/revoke_owner_client_access_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/save_client_agent_token_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/sync_pending_client_agent_actions_use_case.dart';
import 'package:colmeia/features/client_agents/data/storage/local_agent_client_token_store.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_access_request.dart';
import 'package:colmeia/features/client_agents/domain/entities/owner_client_access_request.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_result.dart';
import 'package:colmeia/features/client_agents/domain/entities/pending_agent_action.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agents_controller.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agents_owner_controller.dart';
import 'package:colmeia/features/client_agents/presentation/pages/client_agents_page.dart';
import 'package:colmeia/features/user_context/domain/entities/access/store_scope.dart';
import 'package:colmeia/features/user_context/domain/entities/current_user_scope.dart';
import 'package:colmeia/features/user_context/domain/entities/user_access_scope.dart';
import 'package:colmeia/features/user_context/domain/entities/user_permission.dart';
import 'package:colmeia/features/user_context/domain/entities/user_profile.dart';
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';
import 'package:colmeia/l10n/app_localizations_pt.dart';
import 'package:colmeia/shared/identity/client_account_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:result_dart/result_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../support/localized_test_app.dart';

class _MockAuthController extends Mock implements AuthController {}

class _MockLocalAgentClientTokenStore extends Mock
    implements LocalAgentClientTokenStore {}

class _MockLoadClientApprovedAgentsUseCase extends Mock
    implements LoadClientApprovedAgentsUseCase {}

class _MockLoadClientAccessRequestsUseCase extends Mock
    implements LoadClientAccessRequestsUseCase {}

class _MockLoadClientAccessStatusUseCase extends Mock
    implements LoadClientAccessStatusUseCase {}

class _MockLoadClientAgentDetailUseCase extends Mock
    implements LoadClientAgentDetailUseCase {}

class _MockQueueClientAgentRequestAccessUseCase extends Mock
    implements QueueClientAgentRequestAccessUseCase {}

class _MockQueueClientAgentRemoveAccessUseCase extends Mock
    implements QueueClientAgentRemoveAccessUseCase {}

class _MockProbeClientApprovedAgentUseCase extends Mock
    implements ProbeClientApprovedAgentUseCase {}

class _MockDiscardQueuedClientAgentRequestAccessUseCase extends Mock
    implements DiscardQueuedClientAgentRequestAccessUseCase {}

class _MockReadPendingClientAgentActionsUseCase extends Mock
    implements ReadPendingClientAgentActionsUseCase {}

class _MockSyncPendingClientAgentActionsUseCase extends Mock
    implements SyncPendingClientAgentActionsUseCase {}

class _MockGetClientAgentTokenUseCase extends Mock
    implements GetClientAgentTokenUseCase {}

class _MockSaveClientAgentTokenUseCase extends Mock
    implements SaveClientAgentTokenUseCase {}

class _MockRetryClientAccessRequestUseCase extends Mock
    implements RetryClientAccessRequestUseCase {}

class _MockLoadManagedAgentsUseCase extends Mock
    implements LoadManagedAgentsUseCase {}

class _MockLoadOwnerAccessRequestsUseCase extends Mock
    implements LoadOwnerAccessRequestsUseCase {}

class _MockApproveOwnerAccessRequestUseCase extends Mock
    implements ApproveOwnerAccessRequestUseCase {}

class _MockRejectOwnerAccessRequestUseCase extends Mock
    implements RejectOwnerAccessRequestUseCase {}

class _MockLoadOwnerApprovedClientsUseCase extends Mock
    implements LoadOwnerApprovedClientsUseCase {}

class _MockRevokeOwnerClientAccessUseCase extends Mock
    implements RevokeOwnerClientAccessUseCase {}

CurrentUserScope _buildUserScope({
  required String name,
  required Set<UserPermission> permissions,
}) {
  return CurrentUserScope(
    profile: UserProfile(id: 'u1', name: name, roleLabel: name),
    access: UserAccessScope(
      allowedStores: <StoreScope>[const StoreScope(id: '1', name: 'Store')],
      permissions: permissions,
    ),
  );
}

class _MutableCurrentUserContextController
    extends CurrentUserContextController {
  _MutableCurrentUserContextController({
    required String name,
    required Set<UserPermission> permissions,
  }) : _permissions = permissions,
       super.testing(
         userScope: _buildUserScope(name: name, permissions: permissions),
         activeStoreId: '1',
       );

  Set<UserPermission> _permissions;

  @override
  Set<UserPermission> get permissions => _permissions;

  @override
  bool hasPermission(UserPermission permission) {
    return _permissions.contains(permission);
  }

  void setPermissions(Set<UserPermission> permissions) {
    _permissions = permissions;
    notifyListeners();
  }
}

AuthSession _buildSession() {
  return AuthSession(
    userId: 'u1',
    email: EmailAddress('client@example.com'),
    accessToken: 'token',
    refreshToken: 'refresh',
    expiresAt: DateTime(2099),
    accountStatus: ClientAccountStatus.active,
  );
}

PaginatedResult<T> _emptyPage<T>() {
  return PaginatedResult<T>(
    items: <T>[],
    count: 0,
    total: 0,
    page: 1,
    pageSize: 20,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(const PaginatedQuery());
  });

  testWidgets('localizes typed controller errors on the main page', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final authController = _MockAuthController();
    when(() => authController.session).thenReturn(null);

    final controller = ClientAgentsController(
      authController: authController,
      clientTokenDraftStore: ClientAgentTokenDraftStore(
        _MockLocalAgentClientTokenStore(),
      ),
      loadApprovedAgentsUseCase: _MockLoadClientApprovedAgentsUseCase(),
      loadAccessRequestsUseCase: _MockLoadClientAccessRequestsUseCase(),
      loadClientAccessStatusUseCase: _MockLoadClientAccessStatusUseCase(),
      loadClientAgentDetailUseCase: _MockLoadClientAgentDetailUseCase(),
      queueRequestAccessUseCase: _MockQueueClientAgentRequestAccessUseCase(),
      queueRemoveAccessUseCase: _MockQueueClientAgentRemoveAccessUseCase(),
      probeClientApprovedAgentUseCase: _MockProbeClientApprovedAgentUseCase(),
      discardQueuedClientAgentRequestAccessUseCase:
          _MockDiscardQueuedClientAgentRequestAccessUseCase(),
      readPendingActionsUseCase: _MockReadPendingClientAgentActionsUseCase(),
      syncPendingActionsUseCase: _MockSyncPendingClientAgentActionsUseCase(),
      getClientAgentTokenUseCase: _MockGetClientAgentTokenUseCase(),
      saveClientAgentTokenUseCase: _MockSaveClientAgentTokenUseCase(),
      retryClientAccessRequestUseCase: _MockRetryClientAccessRequestUseCase(),
    );

    final ownerController = ClientAgentsOwnerController(
      authController: authController,
      loadManagedAgentsUseCase: _MockLoadManagedAgentsUseCase(),
      loadOwnerAccessRequestsUseCase: _MockLoadOwnerAccessRequestsUseCase(),
      approveOwnerAccessRequestUseCase: _MockApproveOwnerAccessRequestUseCase(),
      rejectOwnerAccessRequestUseCase: _MockRejectOwnerAccessRequestUseCase(),
      loadOwnerApprovedClientsUseCase: _MockLoadOwnerApprovedClientsUseCase(),
      revokeOwnerClientAccessUseCase: _MockRevokeOwnerClientAccessUseCase(),
    );

    final currentUserContextController = CurrentUserContextController.testing(
      userScope: _buildUserScope(
        name: 'Client',
        permissions: const <UserPermission>{},
      ),
      activeStoreId: '1',
    );
    addTearDown(currentUserContextController.dispose);

    await tester.pumpWidget(
      LocalizedTestApp(
        child: ChangeNotifierProvider<CurrentUserContextController>.value(
          value: currentUserContextController,
          child: ClientAgentsPage(
            controller: controller,
            ownerController: ownerController,
            pageSessionService: ClientAgentsPageSessionService(prefs),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(AppLocalizationsPt().clientAgentsSessionUnavailableLoad),
      findsOneWidget,
    );
  });

  testWidgets('localizes typed owner errors on the owner requests tab', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final pageSessionService = ClientAgentsPageSessionService(prefs);
    await pageSessionService.persistSelectedTabIndex(3);

    final authController = _MockAuthController();
    when(() => authController.session).thenReturn(_buildSession());

    final loadApprovedAgents = _MockLoadClientApprovedAgentsUseCase();
    when(
      () => loadApprovedAgents(
        userId: any(named: 'userId'),
        query: any(named: 'query'),
        refresh: any(named: 'refresh'),
      ),
    ).thenAnswer(
      (_) async =>
          Success<PaginatedResult<ClientAgent>, AppFailure>(_emptyPage()),
    );

    final loadAccessRequests = _MockLoadClientAccessRequestsUseCase();
    when(
      () => loadAccessRequests(
        userId: any(named: 'userId'),
        query: any(named: 'query'),
      ),
    ).thenAnswer(
      (_) async =>
          Success<PaginatedResult<ClientAgentAccessRequest>, AppFailure>(
            _emptyPage(),
          ),
    );

    final readPendingActions = _MockReadPendingClientAgentActionsUseCase();
    when(
      () => readPendingActions(userId: any(named: 'userId')),
    ).thenAnswer(
      (_) async => const Success<List<PendingAgentAction>, AppFailure>(
        <PendingAgentAction>[],
      ),
    );

    final controller = ClientAgentsController(
      authController: authController,
      clientTokenDraftStore: ClientAgentTokenDraftStore(
        _MockLocalAgentClientTokenStore(),
      ),
      loadApprovedAgentsUseCase: loadApprovedAgents,
      loadAccessRequestsUseCase: loadAccessRequests,
      loadClientAccessStatusUseCase: _MockLoadClientAccessStatusUseCase(),
      loadClientAgentDetailUseCase: _MockLoadClientAgentDetailUseCase(),
      queueRequestAccessUseCase: _MockQueueClientAgentRequestAccessUseCase(),
      queueRemoveAccessUseCase: _MockQueueClientAgentRemoveAccessUseCase(),
      probeClientApprovedAgentUseCase: _MockProbeClientApprovedAgentUseCase(),
      discardQueuedClientAgentRequestAccessUseCase:
          _MockDiscardQueuedClientAgentRequestAccessUseCase(),
      readPendingActionsUseCase: readPendingActions,
      syncPendingActionsUseCase: _MockSyncPendingClientAgentActionsUseCase(),
      getClientAgentTokenUseCase: _MockGetClientAgentTokenUseCase(),
      saveClientAgentTokenUseCase: _MockSaveClientAgentTokenUseCase(),
      retryClientAccessRequestUseCase: _MockRetryClientAccessRequestUseCase(),
    );

    final loadManagedAgents = _MockLoadManagedAgentsUseCase();
    when(
      () => loadManagedAgents(userId: any(named: 'userId')),
    ).thenAnswer(
      (_) async => const Success<List<ClientAgent>, AppFailure>(
        <ClientAgent>[],
      ),
    );

    final loadOwnerAccessRequests = _MockLoadOwnerAccessRequestsUseCase();
    when(
      () => loadOwnerAccessRequests(userId: any(named: 'userId')),
    ).thenAnswer(
      (_) async => const Failure<List<OwnerClientAccessRequest>, AppFailure>(
        ValidationFailure(
          message: 'owner_requests_failed',
          userMessage: 'Falha ao carregar solicitacoes do owner.',
        ),
      ),
    );

    final ownerController = ClientAgentsOwnerController(
      authController: authController,
      loadManagedAgentsUseCase: loadManagedAgents,
      loadOwnerAccessRequestsUseCase: loadOwnerAccessRequests,
      approveOwnerAccessRequestUseCase: _MockApproveOwnerAccessRequestUseCase(),
      rejectOwnerAccessRequestUseCase: _MockRejectOwnerAccessRequestUseCase(),
      loadOwnerApprovedClientsUseCase: _MockLoadOwnerApprovedClientsUseCase(),
      revokeOwnerClientAccessUseCase: _MockRevokeOwnerClientAccessUseCase(),
    );

    final currentUserContextController = CurrentUserContextController.testing(
      userScope: _buildUserScope(
        name: 'Owner',
        permissions: const <UserPermission>{UserPermission.manageAgents},
      ),
      activeStoreId: '1',
    );
    addTearDown(currentUserContextController.dispose);

    await tester.pumpWidget(
      LocalizedTestApp(
        child: ChangeNotifierProvider<CurrentUserContextController>.value(
          value: currentUserContextController,
          child: ClientAgentsPage(
            controller: controller,
            ownerController: ownerController,
            pageSessionService: pageSessionService,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Falha ao carregar solicitacoes do owner.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'loads owner data when manageAgents permission appears after mount',
    (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final authController = _MockAuthController();
      when(() => authController.session).thenReturn(_buildSession());

      final loadApprovedAgents = _MockLoadClientApprovedAgentsUseCase();
      when(
        () => loadApprovedAgents(
          userId: any(named: 'userId'),
          query: any(named: 'query'),
          refresh: any(named: 'refresh'),
        ),
      ).thenAnswer(
        (_) async =>
            Success<PaginatedResult<ClientAgent>, AppFailure>(_emptyPage()),
      );

      final loadAccessRequests = _MockLoadClientAccessRequestsUseCase();
      when(
        () => loadAccessRequests(
          userId: any(named: 'userId'),
          query: any(named: 'query'),
        ),
      ).thenAnswer(
        (_) async =>
            Success<PaginatedResult<ClientAgentAccessRequest>, AppFailure>(
              _emptyPage(),
            ),
      );

      final readPendingActions = _MockReadPendingClientAgentActionsUseCase();
      when(
        () => readPendingActions(userId: any(named: 'userId')),
      ).thenAnswer(
        (_) async => const Success<List<PendingAgentAction>, AppFailure>(
          <PendingAgentAction>[],
        ),
      );

      final loadManagedAgents = _MockLoadManagedAgentsUseCase();
      when(
        () => loadManagedAgents(userId: any(named: 'userId')),
      ).thenAnswer(
        (_) async =>
            const Success<List<ClientAgent>, AppFailure>(<ClientAgent>[]),
      );

      final loadOwnerAccessRequests = _MockLoadOwnerAccessRequestsUseCase();
      when(
        () => loadOwnerAccessRequests(userId: any(named: 'userId')),
      ).thenAnswer(
        (_) async => const Success<List<OwnerClientAccessRequest>, AppFailure>(
          <OwnerClientAccessRequest>[],
        ),
      );

      final controller = ClientAgentsController(
        authController: authController,
        clientTokenDraftStore: ClientAgentTokenDraftStore(
          _MockLocalAgentClientTokenStore(),
        ),
        loadApprovedAgentsUseCase: loadApprovedAgents,
        loadAccessRequestsUseCase: loadAccessRequests,
        loadClientAccessStatusUseCase: _MockLoadClientAccessStatusUseCase(),
        loadClientAgentDetailUseCase: _MockLoadClientAgentDetailUseCase(),
        queueRequestAccessUseCase: _MockQueueClientAgentRequestAccessUseCase(),
        queueRemoveAccessUseCase: _MockQueueClientAgentRemoveAccessUseCase(),
        probeClientApprovedAgentUseCase: _MockProbeClientApprovedAgentUseCase(),
        discardQueuedClientAgentRequestAccessUseCase:
            _MockDiscardQueuedClientAgentRequestAccessUseCase(),
        readPendingActionsUseCase: readPendingActions,
        syncPendingActionsUseCase: _MockSyncPendingClientAgentActionsUseCase(),
        getClientAgentTokenUseCase: _MockGetClientAgentTokenUseCase(),
        saveClientAgentTokenUseCase: _MockSaveClientAgentTokenUseCase(),
        retryClientAccessRequestUseCase: _MockRetryClientAccessRequestUseCase(),
      );

      final ownerController = ClientAgentsOwnerController(
        authController: authController,
        loadManagedAgentsUseCase: loadManagedAgents,
        loadOwnerAccessRequestsUseCase: loadOwnerAccessRequests,
        approveOwnerAccessRequestUseCase:
            _MockApproveOwnerAccessRequestUseCase(),
        rejectOwnerAccessRequestUseCase: _MockRejectOwnerAccessRequestUseCase(),
        loadOwnerApprovedClientsUseCase: _MockLoadOwnerApprovedClientsUseCase(),
        revokeOwnerClientAccessUseCase: _MockRevokeOwnerClientAccessUseCase(),
      );

      final currentUserContextController = _MutableCurrentUserContextController(
        name: 'Client',
        permissions: const <UserPermission>{},
      );
      addTearDown(currentUserContextController.dispose);

      await tester.pumpWidget(
        LocalizedTestApp(
          child: ChangeNotifierProvider<CurrentUserContextController>.value(
            value: currentUserContextController,
            child: ClientAgentsPage(
              controller: controller,
              ownerController: ownerController,
              pageSessionService: ClientAgentsPageSessionService(prefs),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      verifyNever(() => loadManagedAgents(userId: any(named: 'userId')));

      currentUserContextController.setPermissions(
        const <UserPermission>{UserPermission.manageAgents},
      );
      await tester.pump();
      await tester.pumpAndSettle();

      verify(() => loadManagedAgents(userId: 'u1')).called(1);
    },
  );

  testWidgets(
    'shows managed agents error instead of the false empty owner state',
    (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final pageSessionService = ClientAgentsPageSessionService(prefs);
      await pageSessionService.persistSelectedTabIndex(4);

      final authController = _MockAuthController();
      when(() => authController.session).thenReturn(_buildSession());

      final loadApprovedAgents = _MockLoadClientApprovedAgentsUseCase();
      when(
        () => loadApprovedAgents(
          userId: any(named: 'userId'),
          query: any(named: 'query'),
          refresh: any(named: 'refresh'),
        ),
      ).thenAnswer(
        (_) async =>
            Success<PaginatedResult<ClientAgent>, AppFailure>(_emptyPage()),
      );

      final loadAccessRequests = _MockLoadClientAccessRequestsUseCase();
      when(
        () => loadAccessRequests(
          userId: any(named: 'userId'),
          query: any(named: 'query'),
        ),
      ).thenAnswer(
        (_) async =>
            Success<PaginatedResult<ClientAgentAccessRequest>, AppFailure>(
              _emptyPage(),
            ),
      );

      final readPendingActions = _MockReadPendingClientAgentActionsUseCase();
      when(
        () => readPendingActions(userId: any(named: 'userId')),
      ).thenAnswer(
        (_) async => const Success<List<PendingAgentAction>, AppFailure>(
          <PendingAgentAction>[],
        ),
      );

      final loadManagedAgents = _MockLoadManagedAgentsUseCase();
      when(
        () => loadManagedAgents(userId: any(named: 'userId')),
      ).thenAnswer(
        (_) async => const Failure<List<ClientAgent>, AppFailure>(
          ValidationFailure(
            message: 'managed_agents_failed',
            userMessage: 'Falha ao carregar agentes administrados.',
          ),
        ),
      );

      final loadOwnerAccessRequests = _MockLoadOwnerAccessRequestsUseCase();
      when(
        () => loadOwnerAccessRequests(userId: any(named: 'userId')),
      ).thenAnswer(
        (_) async => const Success<List<OwnerClientAccessRequest>, AppFailure>(
          <OwnerClientAccessRequest>[],
        ),
      );

      final controller = ClientAgentsController(
        authController: authController,
        clientTokenDraftStore: ClientAgentTokenDraftStore(
          _MockLocalAgentClientTokenStore(),
        ),
        loadApprovedAgentsUseCase: loadApprovedAgents,
        loadAccessRequestsUseCase: loadAccessRequests,
        loadClientAccessStatusUseCase: _MockLoadClientAccessStatusUseCase(),
        loadClientAgentDetailUseCase: _MockLoadClientAgentDetailUseCase(),
        queueRequestAccessUseCase: _MockQueueClientAgentRequestAccessUseCase(),
        queueRemoveAccessUseCase: _MockQueueClientAgentRemoveAccessUseCase(),
        probeClientApprovedAgentUseCase: _MockProbeClientApprovedAgentUseCase(),
        discardQueuedClientAgentRequestAccessUseCase:
            _MockDiscardQueuedClientAgentRequestAccessUseCase(),
        readPendingActionsUseCase: readPendingActions,
        syncPendingActionsUseCase: _MockSyncPendingClientAgentActionsUseCase(),
        getClientAgentTokenUseCase: _MockGetClientAgentTokenUseCase(),
        saveClientAgentTokenUseCase: _MockSaveClientAgentTokenUseCase(),
        retryClientAccessRequestUseCase: _MockRetryClientAccessRequestUseCase(),
      );

      final ownerController = ClientAgentsOwnerController(
        authController: authController,
        loadManagedAgentsUseCase: loadManagedAgents,
        loadOwnerAccessRequestsUseCase: loadOwnerAccessRequests,
        approveOwnerAccessRequestUseCase:
            _MockApproveOwnerAccessRequestUseCase(),
        rejectOwnerAccessRequestUseCase: _MockRejectOwnerAccessRequestUseCase(),
        loadOwnerApprovedClientsUseCase: _MockLoadOwnerApprovedClientsUseCase(),
        revokeOwnerClientAccessUseCase: _MockRevokeOwnerClientAccessUseCase(),
      );

      final currentUserContextController = CurrentUserContextController.testing(
        userScope: _buildUserScope(
          name: 'Owner',
          permissions: const <UserPermission>{UserPermission.manageAgents},
        ),
        activeStoreId: '1',
      );
      addTearDown(currentUserContextController.dispose);

      await tester.pumpWidget(
        LocalizedTestApp(
          child: ChangeNotifierProvider<CurrentUserContextController>.value(
            value: currentUserContextController,
            child: ClientAgentsPage(
              controller: controller,
              ownerController: ownerController,
              pageSessionService: pageSessionService,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Falha ao carregar agentes administrados.'),
        findsOneWidget,
      );
      expect(
        find.text(AppLocalizationsPt().clientAgentsOwnerClientsEmptyAgents),
        findsNothing,
      );
    },
  );
}
