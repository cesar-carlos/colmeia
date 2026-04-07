import 'package:checks/checks.dart';
import 'package:colmeia/features/client_agents/data/datasources/client_agents_local_datasource.dart';
import 'package:colmeia/features/client_agents/data/datasources/client_agents_remote_datasource.dart';
import 'package:colmeia/features/client_agents/data/models/agent_catalog_record_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_access_requests_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_access_status_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_accessible_agent_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_agent_address_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_approved_agents_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/online_agents_response_dto.dart';
import 'package:colmeia/features/client_agents/data/repositories/client_agents_repository_impl.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_access_request_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';
import 'package:colmeia/features/client_agents/domain/entities/pending_agent_action.dart';
import 'package:colmeia/features/client_agents/domain/entities/sync_pending_agent_actions_result.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockClientAgentsLocalDataSource extends Mock
    implements ClientAgentsLocalDataSource {}

class _MockClientAgentsRemoteDataSource extends Mock
    implements ClientAgentsRemoteDataSource {}

void main() {
  late _MockClientAgentsLocalDataSource local;
  late _MockClientAgentsRemoteDataSource remote;
  late ClientAgentsRepositoryImpl repository;
  final now = DateTime.utc(2026, 4, 4, 12);

  setUpAll(() {
    registerFallbackValue(const PaginatedQuery());
    registerFallbackValue(
      const ClientApprovedAgentsResponseDto(
        agents: [],
        agentIds: <String>{},
        count: 0,
        total: 0,
        page: 1,
        pageSize: 1,
      ),
    );
    registerFallbackValue(
      const ClientAccessRequestsResponseDto(
        requests: [],
        count: 0,
        total: 0,
        page: 1,
        pageSize: 1,
      ),
    );
    registerFallbackValue(
      const OnlineAgentsResponseDto(
        agents: [],
        count: 0,
      ),
    );
    registerFallbackValue(<PendingAgentAction>[]);
  });

  setUp(() {
    local = _MockClientAgentsLocalDataSource();
    remote = _MockClientAgentsRemoteDataSource();
    repository = ClientAgentsRepositoryImpl(
      localDataSource: local,
      remoteDataSource: remote,
    );
  });

  test('should enqueue request access without syncing immediately', () async {
    when(
      () => local.readPendingActions(userId: any(named: 'userId')),
    ).thenAnswer((_) async => const <PendingAgentAction>[]);
    when(
      () => local.readApprovedAgents(
        userId: any(named: 'userId'),
        query: any(named: 'query'),
      ),
    ).thenAnswer((_) async => null);
    when(
      () => local.savePendingActions(
        userId: any(named: 'userId'),
        actions: any(named: 'actions'),
      ),
    ).thenAnswer((_) async {});

    final result = await repository.queueRequestAccess(
      userId: 'user-1',
      agentIds: const <String>{'agent-1'},
    );

    check(result.isSuccess()).isTrue();
    verifyNever(() => remote.requestAccess(agentIds: any(named: 'agentIds')));
    verify(
      () => local.savePendingActions(
        userId: 'user-1',
        actions: any(named: 'actions'),
      ),
    ).called(1);
  });

  test('should keep only failed pending action after granular sync', () async {
    var storedActions = <PendingAgentAction>[
      PendingAgentAction(
        id: 'requestAccess_agent-1',
        agentId: 'agent-1',
        type: PendingAgentActionType.requestAccess,
        state: PendingAgentActionState.queued,
        createdAt: now,
        attemptCount: 0,
      ),
      PendingAgentAction(
        id: 'removeAccess_agent-2',
        agentId: 'agent-2',
        type: PendingAgentActionType.removeAccess,
        state: PendingAgentActionState.queued,
        createdAt: now,
        attemptCount: 0,
      ),
    ];

    when(
      () => local.readPendingActions(userId: any(named: 'userId')),
    ).thenAnswer((_) async => storedActions);
    when(
      () => local.savePendingActions(
        userId: any(named: 'userId'),
        actions: any(named: 'actions'),
      ),
    ).thenAnswer((invocation) async {
      storedActions = List<PendingAgentAction>.from(
        invocation.namedArguments[#actions]! as List<PendingAgentAction>,
      );
    });
    when(
      () => remote.requestAccess(agentIds: const <String>{'agent-1'}),
    ).thenAnswer((_) async => const <String>{'agent-1'});
    when(
      () => remote.removeAccess(agentIds: const <String>{'agent-2'}),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/client/me/agents'),
        type: DioExceptionType.connectionError,
      ),
    );
    when(
      () => remote.fetchApprovedAgents(query: any(named: 'query')),
    ).thenAnswer(
      (_) async => const ClientApprovedAgentsResponseDto(
        agents: [],
        agentIds: <String>{},
        count: 0,
        total: 0,
        page: 1,
        pageSize: 100,
      ),
    );
    when(
      () => local.saveApprovedAgents(
        userId: any(named: 'userId'),
        query: any(named: 'query'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => remote.fetchAccessRequests(query: any(named: 'query')),
    ).thenAnswer(
      (_) async => const ClientAccessRequestsResponseDto(
        requests: [],
        count: 0,
        total: 0,
        page: 1,
        pageSize: 100,
      ),
    );
    when(
      () => local.saveAccessRequests(
        userId: any(named: 'userId'),
        query: any(named: 'query'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => local.readOnlineAgents(
        userId: any(named: 'userId'),
        maxAge: any(named: 'maxAge'),
      ),
    ).thenAnswer((_) async => null);
    when(
      () => local.readOnlineAgents(
        userId: any(named: 'userId'),
      ),
    ).thenAnswer((_) async => null);
    when(() => remote.fetchOnlineAgents()).thenAnswer(
      (_) async => const OnlineAgentsResponseDto(
        agents: [],
        count: 0,
      ),
    );
    when(
      () => local.saveOnlineAgents(
        userId: any(named: 'userId'),
        payload: any(named: 'payload'),
      ),
    ).thenAnswer((_) async {});

    final result = await repository.syncPendingActions(userId: 'user-1');

    check(result.isSuccess()).isTrue();
    check(result.getOrNull()).isA<SyncPendingAgentActionsResult>();
    check(result.getOrNull()!.successfulRequestAccessAgentIds).deepEquals(
      const <String>{'agent-1'},
    );
    check(result.getOrNull()!.failedRemoveAccessAgentIds).deepEquals(
      const <String>{'agent-2'},
    );
    check(storedActions).has((it) => it.length, 'length').equals(1);
    check(storedActions.first.agentId).equals('agent-2');
    check(storedActions.first.state).equals(PendingAgentActionState.failed);
  });

  test(
    'should degrade approved agents to unknown when online endpoint fails',
    () async {
      final response = ClientApprovedAgentsResponseDto(
        agents: <ClientAccessibleAgentDto>[
          ClientAccessibleAgentDto(
            agentId: 'agent-1',
            name: 'Agent One',
            status: 'active',
            createdAt: now,
            updatedAt: now,
            address: const ClientAgentAddressDto(
              city: 'Sao Paulo',
              state: 'SP',
            ),
          ),
        ],
        agentIds: const <String>{'agent-1'},
        count: 1,
        total: 1,
        page: 1,
        pageSize: 20,
      );

      when(
        () => remote.fetchApprovedAgents(
          query: any(named: 'query'),
          search: any(named: 'search'),
          status: any(named: 'status'),
        ),
      ).thenAnswer((_) async => response);
      when(
        () => local.saveApprovedAgents(
          userId: any(named: 'userId'),
          query: any(named: 'query'),
          payload: any(named: 'payload'),
          search: any(named: 'search'),
          status: any(named: 'status'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => local.readOnlineAgents(
          userId: any(named: 'userId'),
          maxAge: any(named: 'maxAge'),
        ),
      ).thenAnswer((_) async => null);
      when(
        () => local.readOnlineAgents(
          userId: any(named: 'userId'),
        ),
      ).thenAnswer((_) async => null);
      when(() => remote.fetchOnlineAgents()).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/agents'),
          type: DioExceptionType.connectionError,
        ),
      );

      final result = await repository.loadApprovedAgents(
        userId: 'user-1',
        query: const PaginatedQuery(),
      );

      check(result.isSuccess()).isTrue();
      check(result.getOrNull()).isNotNull();
      check(result.getOrNull()!.items.single.connectionStatus).equals(
        AgentConnectionStatus.unknown,
      );
    },
  );

  test(
    'should return catalog agent by id when remote succeeds',
    () async {
      final catalogJson = <String, dynamic>{
        'agentId': 'cat-1',
        'name': 'Catalog Agent',
        'status': 'active',
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };
      when(() => remote.fetchCatalogAgentById('cat-1')).thenAnswer(
        (_) async => AgentCatalogRecordDto.fromJson(catalogJson),
      );
      when(
        () => local.readOnlineAgents(
          userId: any(named: 'userId'),
          maxAge: any(named: 'maxAge'),
        ),
      ).thenAnswer((_) async => null);
      when(
        () => local.readOnlineAgents(userId: any(named: 'userId')),
      ).thenAnswer((_) async => null);
      when(() => remote.fetchOnlineAgents()).thenAnswer(
        (_) async => const OnlineAgentsResponseDto(agents: [], count: 0),
      );
      when(
        () => local.saveOnlineAgents(
          userId: any(named: 'userId'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});

      final result = await repository.loadCatalogAgentById(
        userId: 'user-1',
        agentId: 'cat-1',
      );

      check(result.isSuccess()).isTrue();
      check(result.getOrNull()?.agent.agentId).equals('cat-1');
      check(result.getOrNull()?.agent.name).equals('Catalog Agent');
    },
  );

  test(
    'should return access status when remote succeeds',
    () async {
      when(
        () => remote.fetchClientAccessStatus(token: any(named: 'token')),
      ).thenAnswer(
        (_) async => const ClientAccessStatusResponseDto(
          statusWire: 'pending',
        ),
      );

      final result = await repository.loadClientAccessStatus(
        token: 'review-token',
      );

      check(result.isSuccess()).isTrue();
      check(result.getOrNull()?.status).equals(
        AgentAccessRequestStatus.pending,
      );
    },
  );

  test('should fail client access status when token is empty', () async {
    final result = await repository.loadClientAccessStatus(token: '   ');

    check(result.isError()).isTrue();
    verifyNever(
      () => remote.fetchClientAccessStatus(token: any(named: 'token')),
    );
  });
}
