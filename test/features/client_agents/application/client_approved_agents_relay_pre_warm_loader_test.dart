import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/network/auth_session_accessor.dart';
import 'package:colmeia/features/auth/data/models/auth_session_model.dart';
import 'package:colmeia/features/client_agents/application/client_approved_agents_relay_pre_warm_loader.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_approved_agents_use_case.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_catalog_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_result.dart';
import 'package:colmeia/shared/identity/client_account_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockSessionAccessor extends Mock implements AuthSessionAccessor {}

class _MockLoadApprovedAgentsUseCase extends Mock
    implements LoadClientApprovedAgentsUseCase {}

ClientAgent _agent(String id) {
  return ClientAgent(
    agentId: id,
    name: 'Agent $id',
    catalogStatus: AgentCatalogStatus.active,
    connectionStatus: AgentConnectionStatus.offline,
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
  );
}

PaginatedResult<ClientAgent> _page(List<ClientAgent> items) {
  return PaginatedResult<ClientAgent>(
    items: items,
    count: items.length,
    total: items.length,
    page: 1,
    pageSize: items.length,
  );
}

AuthSessionModel _session({required String userId}) {
  return AuthSessionModel(
    userId: userId,
    email: 'tester@example.com',
    accessToken: 'access',
    refreshToken: 'refresh',
    expiresAt: DateTime.utc(2026, 12, 31),
    accountStatus: ClientAccountStatus.active,
  );
}

void main() {
  late _MockSessionAccessor sessionAccessor;
  late _MockLoadApprovedAgentsUseCase loadApprovedAgentsUseCase;

  setUpAll(() {
    registerFallbackValue(const PaginatedQuery());
  });

  setUp(() {
    sessionAccessor = _MockSessionAccessor();
    loadApprovedAgentsUseCase = _MockLoadApprovedAgentsUseCase();
  });

  ClientApprovedAgentsRelayPreWarmLoader build({int? pageSize}) {
    return ClientApprovedAgentsRelayPreWarmLoader(
      sessionAccessor: sessionAccessor,
      loadApprovedAgentsUseCase: loadApprovedAgentsUseCase,
      pageSize:
          pageSize ?? ClientApprovedAgentsRelayPreWarmLoader.defaultPageSize,
    );
  }

  test(
    'returns the agent ids on the first page using the configured page size',
    () async {
      when(() => sessionAccessor.read())
          .thenAnswer((_) async => _session(userId: 'u1'));
      when(
        () => loadApprovedAgentsUseCase(
          userId: any(named: 'userId'),
          query: any(named: 'query'),
          includeOnlineStatus: any(named: 'includeOnlineStatus'),
          loadAllPages: any(named: 'loadAllPages'),
        ),
      ).thenAnswer(
        (_) async => Success<PaginatedResult<ClientAgent>, AppFailure>(
          _page(<ClientAgent>[_agent('a'), _agent('b'), _agent('c')]),
        ),
      );

      final loader = build(pageSize: 5);
      final ids = await loader.loadApprovedAgentIds();

      check(ids).deepEquals(<String>['a', 'b', 'c']);
      final captured = verify(
        () => loadApprovedAgentsUseCase(
          userId: 'u1',
          query: captureAny(named: 'query'),
          includeOnlineStatus: false,
          loadAllPages: false,
        ),
      ).captured.single as PaginatedQuery;
      check(captured.pageSize).equals(5);
      check(captured.page).equals(1);
    },
  );

  test('returns empty when there is no active session', () async {
    when(() => sessionAccessor.read()).thenAnswer((_) async => null);

    final ids = await build().loadApprovedAgentIds();

    check(ids).isEmpty();
    verifyNever(
      () => loadApprovedAgentsUseCase(
        userId: any(named: 'userId'),
        query: any(named: 'query'),
        includeOnlineStatus: any(named: 'includeOnlineStatus'),
        loadAllPages: any(named: 'loadAllPages'),
      ),
    );
  });

  test('returns empty when the session userId is blank', () async {
    when(() => sessionAccessor.read())
        .thenAnswer((_) async => _session(userId: ''));

    final ids = await build().loadApprovedAgentIds();

    check(ids).isEmpty();
    verifyNever(
      () => loadApprovedAgentsUseCase(
        userId: any(named: 'userId'),
        query: any(named: 'query'),
        includeOnlineStatus: any(named: 'includeOnlineStatus'),
        loadAllPages: any(named: 'loadAllPages'),
      ),
    );
  });

  test('returns empty when the use case fails', () async {
    when(() => sessionAccessor.read())
        .thenAnswer((_) async => _session(userId: 'u1'));
    when(
      () => loadApprovedAgentsUseCase(
        userId: any(named: 'userId'),
        query: any(named: 'query'),
        includeOnlineStatus: any(named: 'includeOnlineStatus'),
        loadAllPages: any(named: 'loadAllPages'),
      ),
    ).thenAnswer(
      (_) async => const Failure<PaginatedResult<ClientAgent>, AppFailure>(
        NetworkFailure(message: 'boom', userMessage: 'boom'),
      ),
    );

    final ids = await build().loadApprovedAgentIds();

    check(ids).isEmpty();
  });

  test('returns empty when the approved page is empty', () async {
    when(() => sessionAccessor.read())
        .thenAnswer((_) async => _session(userId: 'u1'));
    when(
      () => loadApprovedAgentsUseCase(
        userId: any(named: 'userId'),
        query: any(named: 'query'),
        includeOnlineStatus: any(named: 'includeOnlineStatus'),
        loadAllPages: any(named: 'loadAllPages'),
      ),
    ).thenAnswer(
      (_) async => Success<PaginatedResult<ClientAgent>, AppFailure>(
        _page(const <ClientAgent>[]),
      ),
    );

    final ids = await build().loadApprovedAgentIds();

    check(ids).isEmpty();
  });

  test(
    'requests pre-warm without presence enrichment to skip the online probe',
    () async {
      when(() => sessionAccessor.read())
          .thenAnswer((_) async => _session(userId: 'u1'));
      when(
        () => loadApprovedAgentsUseCase(
          userId: any(named: 'userId'),
          query: any(named: 'query'),
          includeOnlineStatus: any(named: 'includeOnlineStatus'),
          loadAllPages: any(named: 'loadAllPages'),
        ),
      ).thenAnswer(
        (_) async => Success<PaginatedResult<ClientAgent>, AppFailure>(
          _page(<ClientAgent>[_agent('a')]),
        ),
      );

      await build().loadApprovedAgentIds();

      verify(
        () => loadApprovedAgentsUseCase(
          userId: 'u1',
          query: any(named: 'query'),
          includeOnlineStatus: false,
          loadAllPages: false,
        ),
      ).called(1);
    },
  );

  test('returns a non-growable list so callers cannot mutate the result',
      () async {
    when(() => sessionAccessor.read())
        .thenAnswer((_) async => _session(userId: 'u1'));
    when(
      () => loadApprovedAgentsUseCase(
        userId: any(named: 'userId'),
        query: any(named: 'query'),
        includeOnlineStatus: any(named: 'includeOnlineStatus'),
        loadAllPages: any(named: 'loadAllPages'),
      ),
    ).thenAnswer(
      (_) async => Success<PaginatedResult<ClientAgent>, AppFailure>(
        _page(<ClientAgent>[_agent('a'), _agent('b')]),
      ),
    );

    final ids = await build().loadApprovedAgentIds();

    check(() => ids.add('c')).throws<UnsupportedError>();
  });

  test('defaults the page size to 8', () {
    check(ClientApprovedAgentsRelayPreWarmLoader.defaultPageSize).equals(8);
  });
}
