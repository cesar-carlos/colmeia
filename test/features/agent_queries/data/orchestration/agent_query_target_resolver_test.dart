import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/data/orchestration/agent_query_target_resolver.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_catalog_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_result.dart';
import 'package:colmeia/features/client_agents/domain/repositories/agent_client_token_reader.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockClientAgentsRepository extends Mock
    implements ClientAgentsRepository {}

class _MockAgentClientTokenReader extends Mock
    implements AgentClientTokenReader {}

void main() {
  late _MockClientAgentsRepository agentsRepository;
  late _MockAgentClientTokenReader tokenStore;
  late AgentQueryTargetResolver resolver;

  setUpAll(() {
    registerFallbackValue(const PaginatedQuery(pageSize: 1));
    registerFallbackValue(false);
  });

  setUp(() {
    agentsRepository = _MockClientAgentsRepository();
    tokenStore = _MockAgentClientTokenReader();
    resolver = AgentQueryTargetResolver(
      clientAgentsRepository: agentsRepository,
      clientTokenReader: tokenStore,
    );
    when(
      () => tokenStore.readMany(
        userId: any(named: 'userId'),
        agentIds: any(named: 'agentIds'),
      ),
    ).thenAnswer((_) async => <String, String>{});
    when(
      () => agentsRepository.loadOnlineAgentIds(
        userId: any(named: 'userId'),
      ),
    ).thenAnswer((_) async => null);
  });

  test('should fail when no approved agents exist', () async {
    when(
      () => agentsRepository.loadApprovedAgents(
        userId: any(named: 'userId'),
        query: any(named: 'query'),
        search: any(named: 'search'),
        status: any(named: 'status'),
        includeOnlineStatus: any(named: 'includeOnlineStatus'),
        refresh: any(named: 'refresh'),
      ),
    ).thenAnswer(
      (_) async => const Success<PaginatedResult<ClientAgent>, AppFailure>(
        PaginatedResult<ClientAgent>(
          items: <ClientAgent>[],
          count: 0,
          total: 0,
          page: 1,
          pageSize: 50,
        ),
      ),
    );

    final result = await resolver.resolve(userId: 'user-1');

    check(result.isError()).isTrue();
    check(result.exceptionOrNull()).isA<ValidationFailure>();
  });

  test(
    'should return success with no targets when selection matches none',
    () async {
      when(
        () => agentsRepository.loadApprovedAgents(
          userId: any(named: 'userId'),
          query: any(named: 'query'),
          search: any(named: 'search'),
          status: any(named: 'status'),
          includeOnlineStatus: any(named: 'includeOnlineStatus'),
          refresh: any(named: 'refresh'),
        ),
      ).thenAnswer(
        (_) async => Success<PaginatedResult<ClientAgent>, AppFailure>(
          PaginatedResult<ClientAgent>(
            items: <ClientAgent>[_agent('agent-a')],
            count: 1,
            total: 1,
            page: 1,
            pageSize: 50,
          ),
        ),
      );

      final result = await resolver.resolve(
        userId: 'user-1',
        selectedAgentIds: {'agent-missing'},
      );

      check(result.isSuccess()).isTrue();
      final resolution = result.getOrThrow();
      check(resolution.consideredApprovedTargets).isEmpty();
      check(resolution.consideredApprovedAgentCount).equals(0);
      verify(
        () => tokenStore.readMany(
          userId: 'user-1',
          agentIds: any(named: 'agentIds'),
        ),
      ).called(1);
    },
  );

  test(
    'should return success with no targets when selection is explicitly empty',
    () async {
      final result = await resolver.resolve(
        userId: 'user-1',
        selectedAgentIds: <String>{},
      );

      check(result.isSuccess()).isTrue();
      final resolution = result.getOrThrow();
      check(resolution.consideredApprovedTargets).isEmpty();
      check(resolution.consideredApprovedAgentCount).equals(0);
      check(resolution.selectedAgentIds).isNotNull();
      check(resolution.selectedAgentIds!.isEmpty).isTrue();
      verifyNever(
        () => agentsRepository.loadApprovedAgents(
          userId: any(named: 'userId'),
          query: any(named: 'query'),
          search: any(named: 'search'),
          status: any(named: 'status'),
          includeOnlineStatus: any(named: 'includeOnlineStatus'),
          refresh: any(named: 'refresh'),
        ),
      );
    },
  );

  test('should sort agents and split missing client token targets', () async {
    when(
      () => agentsRepository.loadApprovedAgents(
        userId: any(named: 'userId'),
        query: any(named: 'query'),
        search: any(named: 'search'),
        status: any(named: 'status'),
        includeOnlineStatus: any(named: 'includeOnlineStatus'),
        refresh: any(named: 'refresh'),
      ),
    ).thenAnswer(
      (_) async => Success<PaginatedResult<ClientAgent>, AppFailure>(
        PaginatedResult<ClientAgent>(
          items: <ClientAgent>[
            _agent('agent-b', name: 'Agente B'),
            _agent('agent-a', name: 'Agente A'),
          ],
          count: 2,
          total: 2,
          page: 1,
          pageSize: 50,
        ),
      ),
    );
    when(
      () => tokenStore.readMany(
        userId: any(named: 'userId'),
        agentIds: any(named: 'agentIds'),
      ),
    ).thenAnswer(
      (_) async => <String, String>{'agent-b': 'token-b'},
    );

    final result = await resolver.resolve(userId: 'user-1');

    check(result.isSuccess()).isTrue();
    final resolution = result.getOrThrow();
    check(
      resolution.consideredApprovedTargets.map((target) => target.agentId),
    ).deepEquals(const <String>['agent-a', 'agent-b']);
    check(
      resolution.missingClientTokenTargets.map((target) => target.agentId),
    ).deepEquals(const <String>['agent-a']);
    check(resolution.consideredApprovedTargets.first.displayName).equals(
      'Agente A',
    );
  });

  test(
    'should reuse recent all-target resolution for selected calls',
    () async {
      var current = DateTime.utc(2026, 5, 14, 10);
      resolver = AgentQueryTargetResolver(
        clientAgentsRepository: agentsRepository,
        clientTokenReader: tokenStore,
        now: () => current,
      );
      when(
        () => agentsRepository.loadApprovedAgents(
          userId: any(named: 'userId'),
          query: any(named: 'query'),
          search: any(named: 'search'),
          status: any(named: 'status'),
          includeOnlineStatus: any(named: 'includeOnlineStatus'),
          refresh: any(named: 'refresh'),
        ),
      ).thenAnswer(
        (_) async => Success<PaginatedResult<ClientAgent>, AppFailure>(
          PaginatedResult<ClientAgent>(
            items: <ClientAgent>[_agent('agent-a'), _agent('agent-b')],
            count: 2,
            total: 2,
            page: 1,
            pageSize: 50,
          ),
        ),
      );
      when(
        () => tokenStore.readMany(
          userId: any(named: 'userId'),
          agentIds: any(named: 'agentIds'),
        ),
      ).thenAnswer(
        (_) async => <String, String>{
          'agent-a': 'token-a',
          'agent-b': 'token-b',
        },
      );

      final allResult = await resolver.resolve(userId: 'user-1');
      current = current.add(const Duration(seconds: 2));
      final selectedResult = await resolver.resolve(
        userId: 'user-1',
        selectedAgentIds: <String>{'agent-a'},
      );

      check(allResult.isSuccess()).isTrue();
      check(selectedResult.isSuccess()).isTrue();
      check(
        selectedResult.getOrThrow().consideredApprovedTargets.map(
          (target) => target.agentId,
        ),
      ).deepEquals(const <String>['agent-a']);
      verify(
        () => agentsRepository.loadApprovedAgents(
          userId: 'user-1',
          query: any(named: 'query'),
          search: any(named: 'search'),
          status: any(named: 'status'),
          includeOnlineStatus: false,
          refresh: any(named: 'refresh'),
        ),
      ).called(1);
      verify(
        () => tokenStore.readMany(
          userId: 'user-1',
          agentIds: any(named: 'agentIds'),
        ),
      ).called(1);
    },
  );

  test('invalidate clears cached resolution for the user', () async {
    var current = DateTime.utc(2026, 5, 14, 10);
    resolver = AgentQueryTargetResolver(
      clientAgentsRepository: agentsRepository,
      clientTokenReader: tokenStore,
      now: () => current,
    );
    when(
      () => agentsRepository.loadApprovedAgents(
        userId: any(named: 'userId'),
        query: any(named: 'query'),
        search: any(named: 'search'),
        status: any(named: 'status'),
        includeOnlineStatus: any(named: 'includeOnlineStatus'),
        refresh: any(named: 'refresh'),
      ),
    ).thenAnswer(
      (_) async => Success<PaginatedResult<ClientAgent>, AppFailure>(
        PaginatedResult<ClientAgent>(
          items: <ClientAgent>[_agent('agent-a')],
          count: 1,
          total: 1,
          page: 1,
          pageSize: 50,
        ),
      ),
    );
    when(
      () => tokenStore.readMany(
        userId: any(named: 'userId'),
        agentIds: any(named: 'agentIds'),
      ),
    ).thenAnswer((_) async => <String, String>{'agent-a': 'token-a'});

    final first = await resolver.resolve(userId: 'user-1');
    resolver.invalidate(userId: 'user-1');
    current = current.add(const Duration(seconds: 2));
    final second = await resolver.resolve(userId: 'user-1');

    check(first.isSuccess()).isTrue();
    check(second.isSuccess()).isTrue();
    verify(
      () => agentsRepository.loadApprovedAgents(
        userId: 'user-1',
        query: any(named: 'query'),
        search: any(named: 'search'),
        status: any(named: 'status'),
        includeOnlineStatus: false,
        refresh: any(named: 'refresh'),
      ),
    ).called(2);
  });

  test('should load approved agents with online status disabled', () async {
    when(
      () => agentsRepository.loadApprovedAgents(
        userId: any(named: 'userId'),
        query: any(named: 'query'),
        search: any(named: 'search'),
        status: any(named: 'status'),
        includeOnlineStatus: any(named: 'includeOnlineStatus'),
        refresh: any(named: 'refresh'),
      ),
    ).thenAnswer(
      (_) async => Success<PaginatedResult<ClientAgent>, AppFailure>(
        PaginatedResult<ClientAgent>(
          items: <ClientAgent>[_agent('agent-a')],
          count: 1,
          total: 1,
          page: 1,
          pageSize: 50,
        ),
      ),
    );

    await resolver.resolve(userId: 'user-1');

    verify(
      () => agentsRepository.loadApprovedAgents(
        userId: 'user-1',
        query: any(named: 'query'),
        search: any(named: 'search'),
        status: any(named: 'status'),
        includeOnlineStatus: false,
      ),
    ).called(1);
    verify(
      () => agentsRepository.loadOnlineAgentIds(userId: 'user-1'),
    ).called(1);
  });

  test(
    'marks token-ready agents offline when presence snapshot exists and '
    'agent is not in online set',
    () async {
      when(
        () => agentsRepository.loadApprovedAgents(
          userId: any(named: 'userId'),
          query: any(named: 'query'),
          search: any(named: 'search'),
          status: any(named: 'status'),
          includeOnlineStatus: any(named: 'includeOnlineStatus'),
          refresh: any(named: 'refresh'),
        ),
      ).thenAnswer(
        (_) async => Success<PaginatedResult<ClientAgent>, AppFailure>(
          PaginatedResult<ClientAgent>(
            items: <ClientAgent>[
              _agent(
                'agent-x',
                connectionStatus: AgentConnectionStatus.unknown,
              ),
            ],
            count: 1,
            total: 1,
            page: 1,
            pageSize: 50,
          ),
        ),
      );
      when(
        () => agentsRepository.loadOnlineAgentIds(
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async => <String>{});
      when(
        () => tokenStore.readMany(
          userId: any(named: 'userId'),
          agentIds: any(named: 'agentIds'),
        ),
      ).thenAnswer((_) async => <String, String>{'agent-x': 'tok-x'});

      final result = await resolver.resolve(userId: 'user-1');

      check(result.isSuccess()).isTrue();
      final resolution = result.getOrThrow();
      check(resolution.hubPresenceOnlineAgentIdsSnapshot).isNotNull();
      check(resolution.hubPresenceOnlineAgentIdsSnapshot!.length).equals(0);
      check(
        resolution.consideredApprovedTargets.single.connectionStatus,
      ).equals(AgentConnectionStatus.offline);
      check(resolution.skippedDueToHubPresenceTargets.length).equals(1);
      check(
        resolution.skippedDueToHubPresenceTargets.single.agentId,
      ).equals('agent-x');
    },
  );
}

ClientAgent _agent(
  String id, {
  String name = 'Agente Teste',
  AgentConnectionStatus connectionStatus = AgentConnectionStatus.online,
}) {
  return ClientAgent(
    agentId: id,
    name: name,
    catalogStatus: AgentCatalogStatus.active,
    connectionStatus: connectionStatus,
    createdAt: DateTime(2025),
    updatedAt: DateTime(2025),
  );
}
