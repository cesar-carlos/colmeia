import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/client_agents/data/datasources/client_agents_local_datasource.dart';
import 'package:colmeia/features/client_agents/data/datasources/client_agents_remote_datasource.dart';
import 'package:colmeia/features/client_agents/data/models/agent_catalog_record_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_access_requests_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_access_status_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_accessible_agent_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_agent_address_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_approved_agent_detail_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_approved_agents_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_request_access_response_dto.dart';
import 'package:colmeia/features/client_agents/data/models/online_agents_response_dto.dart';
import 'package:colmeia/features/client_agents/data/repositories/client_agents_repository_impl.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_access_request_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_profile_update_request.dart';
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
      AgentCatalogRecordDto.fromJson(<String, dynamic>{
        'agentId': 'fallback',
        'name': 'Fallback',
        'status': 'active',
        'createdAt': '2020-01-01T00:00:00.000Z',
        'updatedAt': '2020-01-01T00:00:00.000Z',
      }),
    );
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
    registerFallbackValue(
      const AgentProfileUpdateRequest(name: 'fallback'),
    );
    registerFallbackValue(
      ClientApprovedAgentDetailResponseDto(
        agent: ClientAccessibleAgentDto.fromJson(<String, dynamic>{
          'agentId': 'fallback-agent',
          'name': 'Fallback',
          'status': 'active',
          'createdAt': '2020-01-01T00:00:00.000Z',
          'updatedAt': '2020-01-01T00:00:00.000Z',
        }),
      ),
    );
    registerFallbackValue(
      const ClientRequestAccessResponseDto(requested: <String>['fb']),
    );
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

  test('should enqueue remove access even when the approved snapshot is missing locally', () async {
    when(
      () => local.readPendingActions(userId: any(named: 'userId')),
    ).thenAnswer((_) async => const <PendingAgentAction>[]);
    when(
      () => local.savePendingActions(
        userId: any(named: 'userId'),
        actions: any(named: 'actions'),
      ),
    ).thenAnswer((_) async {});

    final result = await repository.queueRemoveAccess(
      userId: 'user-1',
      agentIds: const <String>{'agent-2'},
    );

    check(result.isSuccess()).isTrue();
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
    ).thenAnswer(
      (_) async => const ClientRequestAccessResponseDto(
        requested: <String>['agent-1'],
      ),
    );
    when(
      () => remote.removeApprovedAgentById('agent-2'),
    ).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/client/me/agents/agent-2'),
        type: DioExceptionType.connectionError,
      ),
    );
    when(
      () => remote.fetchApprovedAgents(
        query: any(named: 'query'),
        search: any(named: 'search'),
        status: any(named: 'status'),
        refresh: any(named: 'refresh'),
      ),
    ).thenAnswer(
      (_) async => const ClientApprovedAgentsResponseDto(
        agents: [],
        agentIds: <String>{},
        count: 0,
        total: 0,
        page: 1,
        pageSize: 50,
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
        pageSize: 50,
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

    final result = await repository.syncPendingActions(userId: 'user-1');

    check(result.isSuccess()).isTrue();
    check(result.getOrNull()).isA<SyncPendingAgentActionsResult>();
    check(result.getOrNull()!.successfulRequestAccessAgentIds).deepEquals(
      const <String>{'agent-1'},
    );
    check(result.getOrNull()!.failedRemoveAccessAgentIds).deepEquals(
      const <String>{'agent-2'},
    );
    check(result.getOrNull()!.requestAccessPollAgentIds).deepEquals(
      const <String>{'agent-1'},
    );
    check(storedActions).has((it) => it.length, 'length').equals(1);
    check(storedActions.first.agentId).equals('agent-2');
    check(storedActions.first.state).equals(PendingAgentActionState.failed);
    verify(() => remote.removeApprovedAgentById('agent-2')).called(1);
    verifyNever(
      () => remote.fetchOnlineAgents(logUserId: any(named: 'logUserId')),
    );
  });

  test('successful remove sync clears the cached approved-agent detail', () async {
    var storedActions = <PendingAgentAction>[
      PendingAgentAction(
        id: 'removeAccess_agent-9',
        agentId: 'agent-9',
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
    when(() => remote.removeApprovedAgentById('agent-9')).thenAnswer((_) async {});
    when(
      () => local.clearApprovedAgentDetail(
        userId: 'user-1',
        agentId: 'agent-9',
      ),
    ).thenAnswer((_) async {});
    when(
      () => remote.fetchApprovedAgents(
        query: any(named: 'query'),
        search: any(named: 'search'),
        status: any(named: 'status'),
        refresh: any(named: 'refresh'),
      ),
    ).thenAnswer(
      (_) async => const ClientApprovedAgentsResponseDto(
        agents: [],
        agentIds: <String>{},
        count: 0,
        total: 0,
        page: 1,
        pageSize: 50,
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
        pageSize: 50,
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

    final result = await repository.syncPendingActions(userId: 'user-1');

    check(result.isSuccess()).isTrue();
    check(storedActions).isEmpty();
    verify(
      () => local.clearApprovedAgentDetail(
        userId: 'user-1',
        agentId: 'agent-9',
      ),
    ).called(1);
  });

  test('recovers orphaned syncing pending actions before syncing', () async {
    var storedActions = <PendingAgentAction>[
      PendingAgentAction(
        id: 'requestAccess_agent-x',
        agentId: 'agent-x',
        type: PendingAgentActionType.requestAccess,
        state: PendingAgentActionState.syncing,
        createdAt: now,
        attemptCount: 1,
        lastAttemptAt: now,
        errorMessage: 'stale',
      ),
    ];
    var saveCount = 0;

    when(
      () => local.readPendingActions(userId: any(named: 'userId')),
    ).thenAnswer((_) async => storedActions);
    when(
      () => local.savePendingActions(
        userId: any(named: 'userId'),
        actions: any(named: 'actions'),
      ),
    ).thenAnswer((invocation) async {
      final next = List<PendingAgentAction>.from(
        invocation.namedArguments[#actions]! as List<PendingAgentAction>,
      );
      if (saveCount == 0) {
        check(next.single.state).equals(PendingAgentActionState.queued);
        check(next.single.errorMessage).isNull();
      }
      saveCount++;
      storedActions = next;
    });
    when(
      () => remote.requestAccess(agentIds: const <String>{'agent-x'}),
    ).thenAnswer(
      (_) async => const ClientRequestAccessResponseDto(
        requested: <String>['agent-x'],
      ),
    );
    when(
      () => remote.fetchApprovedAgents(
        query: any(named: 'query'),
        search: any(named: 'search'),
        status: any(named: 'status'),
        refresh: any(named: 'refresh'),
      ),
    ).thenAnswer(
      (_) async => const ClientApprovedAgentsResponseDto(
        agents: [],
        agentIds: <String>{},
        count: 0,
        total: 0,
        page: 1,
        pageSize: 50,
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
        pageSize: 50,
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

    final result = await repository.syncPendingActions(userId: 'user-1');

    check(result.isSuccess()).isTrue();
    verify(
      () => remote.requestAccess(agentIds: const <String>{'agent-x'}),
    ).called(1);
  });

  test('sync batches multiple requestAccess actions into one POST', () async {
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
        id: 'requestAccess_agent-2',
        agentId: 'agent-2',
        type: PendingAgentActionType.requestAccess,
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
      () => remote.requestAccess(agentIds: any(named: 'agentIds')),
    ).thenAnswer(
      (invocation) async {
        final ids = invocation.namedArguments[#agentIds]! as Set<String>;
        check(ids).deepEquals(const <String>{'agent-1', 'agent-2'});
        return ClientRequestAccessResponseDto(
          newRequests: ids.toList(growable: false),
        );
      },
    );
    when(
      () => remote.fetchApprovedAgents(
        query: any(named: 'query'),
        search: any(named: 'search'),
        status: any(named: 'status'),
        refresh: any(named: 'refresh'),
      ),
    ).thenAnswer(
      (_) async => const ClientApprovedAgentsResponseDto(
        agents: [],
        agentIds: <String>{},
        count: 0,
        total: 0,
        page: 1,
        pageSize: 50,
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
        pageSize: 50,
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

    final result = await repository.syncPendingActions(userId: 'user-1');

    check(result.isSuccess()).isTrue();
    verify(
      () => remote.requestAccess(
        agentIds: const <String>{'agent-1', 'agent-2'},
      ),
    ).called(1);
    check(result.getOrNull()!.requestAccessPollAgentIds).deepEquals(
      const <String>{'agent-1', 'agent-2'},
    );
    check(result.getOrNull()!.requestAccessNewRequestsAgentIds).deepEquals(
      const <String>{'agent-1', 'agent-2'},
    );
    check(storedActions).isEmpty();
  });

  test(
    'sync maps alreadyApproved POST response to empty poll ids',
    () async {
      var storedActions = <PendingAgentAction>[
        PendingAgentAction(
          id: 'requestAccess_already',
          agentId: 'agent-appr',
          type: PendingAgentActionType.requestAccess,
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
        () => remote.requestAccess(agentIds: const <String>{'agent-appr'}),
      ).thenAnswer(
        (_) async => const ClientRequestAccessResponseDto(
          alreadyApproved: <String>['agent-appr'],
        ),
      );
      when(
        () => remote.fetchApprovedAgents(
          query: any(named: 'query'),
          search: any(named: 'search'),
          status: any(named: 'status'),
          refresh: any(named: 'refresh'),
        ),
      ).thenAnswer(
        (_) async => const ClientApprovedAgentsResponseDto(
          agents: [],
          agentIds: <String>{},
          count: 0,
          total: 0,
          page: 1,
          pageSize: 50,
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
          pageSize: 50,
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

      final result = await repository.syncPendingActions(userId: 'user-1');

      check(result.isSuccess()).isTrue();
      check(result.getOrNull()!.requestAccessPollAgentIds).isEmpty();
      check(
        result.getOrNull()!.successfulRequestAccessAgentIds,
      ).deepEquals(const <String>{'agent-appr'});
      check(
        result.getOrNull()!.requestAccessAlreadyApprovedAgentIds,
      ).deepEquals(const <String>{'agent-appr'});
      check(storedActions).has((it) => it.length, 'length').equals(0);
    },
  );

  test(
    'should map approved agents to unknown when no hub field '
    'and no online cache',
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
          refresh: any(named: 'refresh'),
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

      final result = await repository.loadApprovedAgents(
        userId: 'user-1',
        query: const PaginatedQuery(),
      );

      check(result.isSuccess()).isTrue();
      check(result.getOrNull()).isNotNull();
      check(result.getOrNull()!.items.single.connectionStatus).equals(
        AgentConnectionStatus.unknown,
      );
      verifyNever(
        () => remote.fetchOnlineAgents(logUserId: any(named: 'logUserId')),
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
      when(
        () => local.saveCatalogAgentById(
          userId: any(named: 'userId'),
          agentId: any(named: 'agentId'),
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
      verify(
        () => local.saveCatalogAgentById(
          userId: 'user-1',
          agentId: 'cat-1',
          payload: any(named: 'payload'),
        ),
      ).called(1);
      verifyNever(
        () => remote.fetchOnlineAgents(logUserId: any(named: 'logUserId')),
      );
    },
  );

  test(
    'loadCatalogAgentById returns cached catalog agent when remote fails',
    () async {
      final catalogJson = <String, dynamic>{
        'agentId': 'cat-1',
        'name': 'Cached Catalog Agent',
        'status': 'active',
        'createdAt': now.toIso8601String(),
        'updatedAt': now.toIso8601String(),
      };
      final cached = AgentCatalogRecordDto.fromJson(catalogJson);
      when(() => remote.fetchCatalogAgentById(any())).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/catalog/cat-1'),
          type: DioExceptionType.connectionError,
        ),
      );
      when(
        () => local.readCatalogAgentById(
          userId: any(named: 'userId'),
          agentId: any(named: 'agentId'),
        ),
      ).thenAnswer((_) async => cached);
      when(
        () => local.readOnlineAgents(
          userId: any(named: 'userId'),
          maxAge: any(named: 'maxAge'),
        ),
      ).thenAnswer((_) async => null);

      final result = await repository.loadCatalogAgentById(
        userId: 'user-1',
        agentId: 'cat-1',
      );

      check(result.isSuccess()).isTrue();
      check(result.getOrNull()?.agent.name).equals('Cached Catalog Agent');
      verifyNever(
        () => local.saveCatalogAgentById(
          userId: any(named: 'userId'),
          agentId: any(named: 'agentId'),
          payload: any(named: 'payload'),
        ),
      );
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

  test(
    'loadApprovedAgents does not return cached snapshot on HTTP 403',
    () async {
      when(
        () => remote.fetchApprovedAgents(
          query: any(named: 'query'),
          search: any(named: 'search'),
          status: any(named: 'status'),
          refresh: any(named: 'refresh'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/client/me/agents'),
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: '/client/me/agents'),
            statusCode: 403,
            data: <String, dynamic>{'message': 'Forbidden'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final result = await repository.loadApprovedAgents(
        userId: 'user-1',
        query: const PaginatedQuery(),
      );

      check(result.isError()).isTrue();
      check(result.exceptionOrNull()).isA<AuthorizationFailure>();
      verifyNever(
        () => local.readApprovedAgents(
          userId: any(named: 'userId'),
          query: any(named: 'query'),
          search: any(named: 'search'),
          status: any(named: 'status'),
        ),
      );
    },
  );

  test(
    'loadApprovedAgents skips online status when includeOnlineStatus is false',
    () async {
      when(
        () => remote.fetchApprovedAgents(
          query: any(named: 'query'),
          search: any(named: 'search'),
          status: any(named: 'status'),
          refresh: any(named: 'refresh'),
        ),
      ).thenAnswer(
        (_) async => const ClientApprovedAgentsResponseDto(
          agents: [],
          agentIds: <String>{},
          count: 0,
          total: 0,
          page: 1,
          pageSize: 20,
        ),
      );
      when(
        () => local.saveApprovedAgents(
          userId: any(named: 'userId'),
          query: any(named: 'query'),
          payload: any(named: 'payload'),
          search: any(named: 'search'),
          status: any(named: 'status'),
        ),
      ).thenAnswer((_) async {});

      await repository.loadApprovedAgents(
        userId: 'user-1',
        query: const PaginatedQuery(),
        includeOnlineStatus: false,
      );

      verifyNever(
        () => local.readOnlineAgents(
          userId: any(named: 'userId'),
          maxAge: any(named: 'maxAge'),
        ),
      );
      verifyNever(() => local.readOnlineAgents(userId: any(named: 'userId')));
      verifyNever(
        () => remote.fetchOnlineAgents(logUserId: any(named: 'logUserId')),
      );
    },
  );

  test(
    'updateCatalogAgentProfile saves payload and returns mapped agent',
    () async {
      final dto = AgentCatalogRecordDto.fromJson(<String, dynamic>{
        'agentId': 'agent-patch-1',
        'name': 'Patched Name',
        'status': 'active',
        'createdAt': '2020-01-01T00:00:00.000Z',
        'updatedAt': '2020-01-02T00:00:00.000Z',
      });
      when(
        () => remote.patchAgentProfile(
          agentId: any(named: 'agentId'),
          body: any(named: 'body'),
        ),
      ).thenAnswer((_) async => dto);
      when(
        () => local.saveCatalogAgentById(
          userId: any(named: 'userId'),
          agentId: any(named: 'agentId'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => local.readOnlineAgents(
          userId: any(named: 'userId'),
          maxAge: any(named: 'maxAge'),
        ),
      ).thenAnswer(
        (_) async => const OnlineAgentsResponseDto(agents: [], count: 0),
      );

      final result = await repository.updateCatalogAgentProfile(
        userId: 'user-1',
        agentId: 'agent-patch-1',
        request: const AgentProfileUpdateRequest(name: 'Patched Name'),
      );

      check(result.isSuccess()).isTrue();
      check(result.getOrNull()?.name).equals('Patched Name');
      verify(
        () => local.saveCatalogAgentById(
          userId: 'user-1',
          agentId: 'agent-patch-1',
          payload: dto,
        ),
      ).called(1);
    },
  );

  test(
    'updateCatalogAgentProfile maps 409 AGENT_DOCUMENT_CONFLICT to validation',
    () async {
      when(
        () => remote.patchAgentProfile(
          agentId: any(named: 'agentId'),
          body: any(named: 'body'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/agents/x/profile'),
          response: Response<dynamic>(
            requestOptions: RequestOptions(path: '/agents/x/profile'),
            statusCode: 409,
            data: <String, dynamic>{'code': 'AGENT_DOCUMENT_CONFLICT'},
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      final result = await repository.updateCatalogAgentProfile(
        userId: 'user-1',
        agentId: 'agent-patch-1',
        request: const AgentProfileUpdateRequest(name: 'X'),
      );

      check(result.isError()).isTrue();
      final failure = result.exceptionOrNull()!;
      check(failure).isA<ValidationFailure>();
      check(failure.displayMessage).equals('Agent document conflict');
      verifyNever(
        () => local.saveCatalogAgentById(
          userId: any(named: 'userId'),
          agentId: any(named: 'agentId'),
          payload: any(named: 'payload'),
        ),
      );
    },
  );

  test(
    'probeApprovedAgentLink clears cached detail when remote returns not found',
    () async {
      const agentId = 'aaaaaaaa-aaaa-aaaa-8aaa-aaaaaaaaaaaa';
      when(() => remote.fetchApprovedAgentDetailOrNull(agentId)).thenAnswer(
        (_) async => null,
      );
      when(
        () => local.clearApprovedAgentDetail(
          userId: 'user-1',
          agentId: agentId,
        ),
      ).thenAnswer((_) async {});

      final result = await repository.probeApprovedAgentLink(
        userId: 'user-1',
        agentId: agentId,
      );

      check(result.isSuccess()).isTrue();
      check(result.getOrNull()!.isLinked).isFalse();
      verify(
        () => local.clearApprovedAgentDetail(
          userId: 'user-1',
          agentId: agentId,
        ),
      ).called(1);
    },
  );

  test(
    'probeApprovedAgentLink persists detail when remote returns a profile',
    () async {
      const agentId = 'bbbbbbbb-bbbb-bbbb-8bbb-bbbbbbbbbbbb';
      final detail = ClientApprovedAgentDetailResponseDto(
        agent: ClientAccessibleAgentDto.fromJson(<String, dynamic>{
          'agentId': agentId,
          'name': 'On Server',
          'status': 'active',
          'createdAt': '2020-01-01T00:00:00.000Z',
          'updatedAt': '2020-01-01T00:00:00.000Z',
        }),
      );
      when(() => remote.fetchApprovedAgentDetailOrNull(agentId)).thenAnswer(
        (_) async => detail,
      );
      when(
        () => local.saveApprovedAgentDetail(
          userId: any(named: 'userId'),
          agentId: any(named: 'agentId'),
          payload: any(named: 'payload'),
        ),
      ).thenAnswer((_) async {});
      when(
        () => local.readOnlineAgents(
          userId: 'user-1',
          maxAge: any(named: 'maxAge'),
        ),
      ).thenAnswer((_) async => null);
      when(
        () => local.readOnlineAgents(userId: 'user-1'),
      ).thenAnswer((_) async => null);

      final result = await repository.probeApprovedAgentLink(
        userId: 'user-1',
        agentId: agentId,
      );

      check(result.isSuccess()).isTrue();
      check(result.getOrNull()!.isLinked).isTrue();
      check(result.getOrNull()!.agent!.agentId).equals(agentId);
      verify(
        () => local.saveApprovedAgentDetail(
          userId: 'user-1',
          agentId: agentId,
          payload: detail,
        ),
      ).called(1);
    },
  );
}
