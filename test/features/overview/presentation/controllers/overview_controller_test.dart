import 'dart:async';

import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/errors/retry_after_gate.dart';
import 'package:colmeia/core/preferences/app_user_preferences_store.dart';
import 'package:colmeia/features/agent_meta/application/agent_rpc_capabilities_registry.dart';
import 'package:colmeia/features/agent_meta/application/usecases/discover_agent_rpc_methods_use_case.dart';
import 'package:colmeia/features/agent_meta/domain/entities/agent_profile_snapshot.dart';
import 'package:colmeia/features/agent_meta/domain/entities/agent_rpc_descriptor.dart';
import 'package:colmeia/features/agent_meta/domain/entities/client_token_policy.dart';
import 'package:colmeia/features/agent_meta/domain/repositories/agent_meta_repository.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';
import 'package:colmeia/features/overview/application/usecases/load_overview_online_agent_ids_use_case.dart';
import 'package:colmeia/features/overview/application/usecases/load_overview_use_case.dart';
import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_ranking.dart';
import 'package:colmeia/features/overview/domain/entities/overview_load_labels.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_kpis.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_method_breakdown.dart';
import 'package:colmeia/features/overview/domain/entities/overview_progressive_snapshot.dart';
import 'package:colmeia/features/overview/domain/entities/overview_user_ranking.dart';
import 'package:colmeia/features/overview/domain/repositories/overview_repository.dart';
import 'package:colmeia/features/overview/presentation/controllers/overview_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockClientAgentsRepository extends Mock
    implements ClientAgentsRepository {}

void main() {
  late _MockClientAgentsRepository clientAgentsRepository;

  setUp(() {
    clientAgentsRepository = _MockClientAgentsRepository();
    when(
      () => clientAgentsRepository.loadOnlineAgentIds(
        userId: any(named: 'userId'),
      ),
    ).thenAnswer((_) async => null);
  });

  group('OverviewController', () {
    test('should load overview from use case', () async {
      final repository = _QueuedOverviewRepository(
        <Future<AppResult<Overview>>>[
          Future<AppResult<Overview>>.value(
            Success<Overview, AppFailure>(_overview('Pix')),
          ),
        ],
      );
      final controller = OverviewController(
        LoadOverviewUseCase(repository),
        LoadOverviewOnlineAgentIdsUseCase(clientAgentsRepository),
      );

      await controller.loadOverview(userId: 'demo-user');

      check(controller.overview).isNotNull();
      check(controller.overview!.paymentMethods.single.code).equals('Pix');
      check(controller.errorMessage).isNull();
      check(controller.hasContent).isTrue();
      check(controller.isLoadingInitial).isFalse();
      check(controller.isRefreshing).isFalse();
      check(repository.requestedPolicies.single).equals(
        OverviewLoadPolicy.defaultLoad,
      );
    });

    test(
      'should keep content visible and expose refresh state '
      'during manual refresh',
      () async {
        final refreshCompleter = Completer<AppResult<Overview>>();
        final repository = _QueuedOverviewRepository(
          <Future<AppResult<Overview>>>[
            Future<AppResult<Overview>>.value(
              Success<Overview, AppFailure>(_overview('Pix')),
            ),
            refreshCompleter.future,
          ],
        );
        final controller = OverviewController(
          LoadOverviewUseCase(repository),
          LoadOverviewOnlineAgentIdsUseCase(clientAgentsRepository),
        );

        await controller.loadOverview(userId: 'demo-user');

        final refreshFuture = controller.refreshOverview(userId: 'demo-user');

        await Future<void>.delayed(Duration.zero);

        check(controller.isRefreshing).isTrue();
        check(controller.isLoadingInitial).isFalse();
        check(controller.overview).isNotNull();
        check(controller.overview!.paymentMethods.single.code).equals('Pix');

        refreshCompleter.complete(
          const Failure<Overview, AppFailure>(
            UnknownFailure(
              message: 'Refresh failed',
              userMessage: 'Could not refresh the overview.',
            ),
          ),
        );

        await refreshFuture;

        check(controller.isRefreshing).isFalse();
        check(controller.overview).isNotNull();
        check(controller.overview!.paymentMethods.single.code).equals('Pix');
        check(controller.errorMessage).equals(
          'Could not refresh the overview.',
        );
        check(repository.requestedPolicies).deepEquals(<OverviewLoadPolicy>[
          OverviewLoadPolicy.defaultLoad,
          OverviewLoadPolicy.forceRefresh,
        ]);
      },
    );

    test('should clear stale content when a second load starts', () async {
      final secondLoadCompleter = Completer<AppResult<Overview>>();
      final repository = _QueuedOverviewRepository(
        <Future<AppResult<Overview>>>[
          Future<AppResult<Overview>>.value(
            Success<Overview, AppFailure>(_overview('Pix')),
          ),
          secondLoadCompleter.future,
        ],
      );
      final controller = OverviewController(
        LoadOverviewUseCase(repository),
        LoadOverviewOnlineAgentIdsUseCase(clientAgentsRepository),
      );

      await controller.loadOverview(userId: 'demo-user');

      final secondLoadFuture = controller.loadOverview(userId: 'demo-user');

      await Future<void>.delayed(Duration.zero);

      check(controller.overview).isNull();
      check(controller.hasContent).isFalse();
      check(controller.isLoadingInitial).isTrue();
      check(controller.isRefreshing).isFalse();

      secondLoadCompleter.complete(
        Success<Overview, AppFailure>(_overview('Credito')),
      );

      await secondLoadFuture;

      check(controller.overview).isNotNull();
      check(controller.overview!.paymentMethods.single.code).equals('Credito');
    });

    test('should ignore stale responses when a newer request wins', () async {
      final firstLoadCompleter = Completer<AppResult<Overview>>();
      final secondLoadCompleter = Completer<AppResult<Overview>>();
      final repository = _QueuedOverviewRepository(
        <Future<AppResult<Overview>>>[
          firstLoadCompleter.future,
          secondLoadCompleter.future,
        ],
      );
      final controller = OverviewController(
        LoadOverviewUseCase(repository),
        LoadOverviewOnlineAgentIdsUseCase(clientAgentsRepository),
      );

      final firstLoadFuture = controller.loadOverview(userId: 'demo-user');
      final secondLoadFuture = controller.loadOverview(userId: 'demo-user');

      firstLoadCompleter.complete(
        Success<Overview, AppFailure>(_overview('Pix')),
      );
      await firstLoadFuture;

      check(controller.overview).isNull();
      check(controller.isLoadingInitial).isTrue();

      secondLoadCompleter.complete(
        Success<Overview, AppFailure>(_overview('Credito')),
      );

      await secondLoadFuture;

      check(controller.overview).isNotNull();
      check(controller.overview!.paymentMethods.single.code).equals('Credito');
      check(controller.isLoadingInitial).isFalse();
    });

    test(
      'should arm RetryAfterGate when failure carries a retry hint and '
      'short-circuit refreshOverview while the window is open',
      () async {
        final initialFailure = Future<AppResult<Overview>>.value(
          const Failure<Overview, AppFailure>(
            // Hub propagated `-32013 client_token_*_rate_limited` (or
            // bridge overload) — the AgentSql failure mapper now
            // forwards `retry_after_ms` to RpcFailure.retryAfter.
            RpcFailure(
              message: 'Rate limited',
              userMessage: 'O servidor pediu para aguardar.',
              rpcCode: -32013,
              retryable: true,
              retryAfter: Duration(seconds: 10),
            ),
          ),
        );
        final repository = _QueuedOverviewRepository(
          <Future<AppResult<Overview>>>[initialFailure],
        );
        final controller = OverviewController(
          LoadOverviewUseCase(repository),
          LoadOverviewOnlineAgentIdsUseCase(clientAgentsRepository),
          // Speed up the ticker so the test does not depend on wall
          // clock seconds while still exercising the same code path.
          retryAfterGate: RetryAfterGate(
            tickInterval: const Duration(milliseconds: 5),
          ),
        );

        await controller.loadOverview(userId: 'demo-user');

        check(controller.errorMessage).isNotNull();
        check(controller.isOnRetryCooldown).isTrue();
        check(controller.retryAfterGate.remaining).isNotNull();

        // refreshOverview MUST be a no-op while the gate is closed. We
        // assert no second hit on the repository (queue is empty —
        // attempting to consume would throw a RangeError, which would
        // surface as a test failure).
        await controller.refreshOverview(userId: 'demo-user');
        await controller.retryOverview(userId: 'demo-user');

        check(repository.requestedPolicies).deepEquals(
          <OverviewLoadPolicy>[OverviewLoadPolicy.defaultLoad],
        );
      },
    );

    test(
      'should prefetch agent RPC capabilities for every available agent '
      'after a successful overview load',
      () async {
        final repository = _QueuedOverviewRepository(
          <Future<AppResult<Overview>>>[
            Future<AppResult<Overview>>.value(
              Success<Overview, AppFailure>(_overview('Pix')),
            ),
          ],
        );
        final discoverRepository = _RecordingDiscoverRepository();
        final registry = AgentRpcCapabilitiesRegistry(
          discoverAgentRpcMethodsUseCase: DiscoverAgentRpcMethodsUseCase(
            discoverRepository,
          ),
        );

        final controller = OverviewController(
          LoadOverviewUseCase(repository),
          LoadOverviewOnlineAgentIdsUseCase(clientAgentsRepository),
          agentRpcCapabilitiesRegistry: registry,
        );

        await controller.loadOverview(userId: 'demo-user');

        // The fixture overview exposes agent `a1` as the only ranked
        // agent — registry should pick it up and discover exactly once.
        await Future<void>.delayed(Duration.zero);

        check(discoverRepository.requestedAgentIds).deepEquals(<String>['a1']);
        check(
          registry.descriptorFor('a1')!.supportsMethod('sql.execute'),
        ).isTrue();
      },
    );

    test(
      'should NOT prefetch RPC capabilities for agents missing the local '
      'client token (would otherwise spam 404s from the bridge)',
      () async {
        // The bridge returns 404 for `agents/commands` against an
        // agent the caller has no token for — there is no
        // `(client, agent)` binding to route through. Prefetching
        // those would just fill Sentry with non-actionable
        // NetworkFailure breadcrumbs.
        final repository = _QueuedOverviewRepository(
          <Future<AppResult<Overview>>>[
            Future<AppResult<Overview>>.value(
              Success<Overview, AppFailure>(
                _overview(
                  'Pix',
                  agentIdsMissingClientToken: const <String>['a1'],
                ),
              ),
            ),
          ],
        );
        final discoverRepository = _RecordingDiscoverRepository();
        final registry = AgentRpcCapabilitiesRegistry(
          discoverAgentRpcMethodsUseCase: DiscoverAgentRpcMethodsUseCase(
            discoverRepository,
          ),
        );

        final controller = OverviewController(
          LoadOverviewUseCase(repository),
          LoadOverviewOnlineAgentIdsUseCase(clientAgentsRepository),
          agentRpcCapabilitiesRegistry: registry,
        );

        await controller.loadOverview(userId: 'demo-user');
        await Future<void>.delayed(Duration.zero);

        // a1 was the only ranked agent and it is missing the token,
        // so the prefetch must do exactly zero discover calls.
        check(discoverRepository.requestedAgentIds).isEmpty();
      },
    );

    test('should ignore late use case completion after dispose', () async {
      final completer = Completer<AppResult<Overview>>();
      final controller = OverviewController(
        LoadOverviewUseCase(
          _PendingOverviewRepository(completer.future),
        ),
        LoadOverviewOnlineAgentIdsUseCase(clientAgentsRepository),
      );

      final loadFuture = controller.loadOverview(userId: 'demo-user');

      await Future<void>.delayed(Duration.zero);
      controller.dispose();

      completer.complete(
        Success<Overview, AppFailure>(_overview('Pix')),
      );

      await loadFuture;
    });

    test(
      'should ignore stale available-agent hydration from older load',
      () async {
        final firstOnlineIds = Completer<Set<String>?>();
        final secondOnlineIds = Completer<Set<String>?>();
        final onlineIdLoads = <Future<Set<String>?>>[
          firstOnlineIds.future,
          secondOnlineIds.future,
        ];
        when(
          () => clientAgentsRepository.loadOnlineAgentIds(
            userId: any(named: 'userId'),
          ),
        ).thenAnswer((_) => onlineIdLoads.removeAt(0));

        final repository = _QueuedOverviewRepository(
          <Future<AppResult<Overview>>>[
            Future<AppResult<Overview>>.value(
              Success<Overview, AppFailure>(
                _overviewWithAgent('old-agent', 'Old Agent'),
              ),
            ),
            Future<AppResult<Overview>>.value(
              Success<Overview, AppFailure>(
                _overviewWithAgent('new-agent', 'New Agent'),
              ),
            ),
          ],
        );
        final controller = OverviewController(
          LoadOverviewUseCase(repository),
          LoadOverviewOnlineAgentIdsUseCase(clientAgentsRepository),
        );

        final firstLoad = controller.loadOverview(
          userId: 'demo-user',
          loadingMode: OverviewLoadingMode.complete,
        );
        await Future<void>.delayed(Duration.zero);

        final secondLoad = controller.loadOverview(
          userId: 'demo-user',
          loadingMode: OverviewLoadingMode.complete,
        );
        await Future<void>.delayed(Duration.zero);

        firstOnlineIds.complete(const <String>{'old-agent'});
        await firstLoad;

        check(controller.availableAgents).isEmpty();

        secondOnlineIds.complete(const <String>{'new-agent'});
        await secondLoad;

        check(
          controller.availableAgents.map((o) => o.agentId).toList(),
        ).deepEquals(<String>['new-agent']);
        check(controller.availableAgents.single.name).equals('New Agent');
      },
    );

    test(
      'skippedDueToHubPresenceAgentNamesNormalized exposes a sorted, '
      'deduped, trimmed view of the names from the loaded overview',
      () async {
        // Acceptance for the new "agentes offline" banner: the
        // controller must hand the widget a normalized list (same
        // contract as the existing missing-token / partial-failure
        // helpers) so the banner can render predictably without each
        // call site re-doing the cleanup.
        final repository = _QueuedOverviewRepository(
          <Future<AppResult<Overview>>>[
            Future<AppResult<Overview>>.value(
              Success<Overview, AppFailure>(
                _overview(
                  'Pix',
                  agentNamesSkippedDueToHubPresence: const <String>[
                    '  Bravo  ',
                    'Alpha',
                    'bravo',
                  ],
                ),
              ),
            ),
          ],
        );
        final controller = OverviewController(
          LoadOverviewUseCase(repository),
          LoadOverviewOnlineAgentIdsUseCase(clientAgentsRepository),
        );

        await controller.loadOverview(userId: 'demo-user');

        check(
          controller.skippedDueToHubPresenceAgentNamesNormalized,
        ).deepEquals(<String>['Alpha', 'Bravo']);
      },
    );

    test(
      'clears isLoadingInitial after summary progressive snapshot before isFinal',
      () async {
        final secondStage = Completer<void>();
        final repository = _GatedProgressiveOverviewRepository(secondStage);
        final controller = OverviewController(
          LoadOverviewUseCase(repository),
          LoadOverviewOnlineAgentIdsUseCase(clientAgentsRepository),
        );

        final loadFuture = controller.loadOverview(userId: 'demo-user');
        await Future<void>.delayed(const Duration(milliseconds: 20));
        check(controller.isLoadingInitial).isFalse();
        check(controller.overview).isNotNull();

        secondStage.complete();
        await loadFuture;
        check(controller.isLoadingInitial).isFalse();
        check(controller.hasContent).isTrue();
      },
    );
  });
}

Overview _overviewWithAgent(String agentId, String displayName) {
  return _overview('Pix').copyWith(
    agentRankings: <OverviewAgentRanking>[
      OverviewAgentRanking(
        agentId: agentId,
        displayName: displayName,
        totalSalesCount: 100,
        totalAmount: 9000,
      ),
    ],
  );
}

class _GatedProgressiveOverviewRepository implements OverviewRepository {
  _GatedProgressiveOverviewRepository(this._secondStage);

  final Completer<void> _secondStage;

  @override
  Future<AppResult<Overview>> loadOverview({
    required String userId,
    OverviewLoadPolicy policy = OverviewLoadPolicy.defaultLoad,
    DashboardFilter filter = const DashboardFilter(),
    OverviewLoadLabels? rowLabels,
    AgentQueriesCancelScope? cancelScope,
  }) {
    throw UnsupportedError('use loadOverviewProgressively');
  }

  @override
  Stream<AppResult<OverviewProgressiveSnapshot>> loadOverviewProgressively({
    required String userId,
    OverviewLoadPolicy policy = OverviewLoadPolicy.defaultLoad,
    DashboardFilter filter = const DashboardFilter(),
    OverviewLoadLabels? rowLabels,
    AgentQueriesCancelScope? cancelScope,
  }) async* {
    final overview = _overview('Pix');
    final allSections = OverviewProgressiveSection.values.toSet();
    yield Success<OverviewProgressiveSnapshot, AppFailure>(
      OverviewProgressiveSnapshot(
        overview: overview,
        completedSections: {OverviewProgressiveSection.summary},
        pendingSections: allSections.difference({
          OverviewProgressiveSection.summary,
        }),
        isFinal: false,
      ),
    );
    await _secondStage.future;
    yield Success<OverviewProgressiveSnapshot, AppFailure>(
      OverviewProgressiveSnapshot(
        overview: overview,
        completedSections: allSections,
        pendingSections: const <OverviewProgressiveSection>{},
        isFinal: true,
      ),
    );
  }
}

class _PendingOverviewRepository implements OverviewRepository {
  _PendingOverviewRepository(this._resultFuture);

  final Future<AppResult<Overview>> _resultFuture;

  @override
  Future<AppResult<Overview>> loadOverview({
    required String userId,
    OverviewLoadPolicy policy = OverviewLoadPolicy.defaultLoad,
    DashboardFilter filter = const DashboardFilter(),
    OverviewLoadLabels? rowLabels,
    AgentQueriesCancelScope? cancelScope,
  }) {
    return _resultFuture;
  }

  @override
  Stream<AppResult<OverviewProgressiveSnapshot>> loadOverviewProgressively({
    required String userId,
    OverviewLoadPolicy policy = OverviewLoadPolicy.defaultLoad,
    DashboardFilter filter = const DashboardFilter(),
    OverviewLoadLabels? rowLabels,
    AgentQueriesCancelScope? cancelScope,
  }) async* {
    yield _asSnapshot(
      await loadOverview(
        userId: userId,
        policy: policy,
        filter: filter,
        rowLabels: rowLabels,
        cancelScope: cancelScope,
      ),
    );
  }
}

class _QueuedOverviewRepository implements OverviewRepository {
  _QueuedOverviewRepository(this._results);

  final List<Future<AppResult<Overview>>> _results;
  final List<OverviewLoadPolicy> requestedPolicies = <OverviewLoadPolicy>[];
  int _index = 0;

  @override
  Future<AppResult<Overview>> loadOverview({
    required String userId,
    OverviewLoadPolicy policy = OverviewLoadPolicy.defaultLoad,
    DashboardFilter filter = const DashboardFilter(),
    OverviewLoadLabels? rowLabels,
    AgentQueriesCancelScope? cancelScope,
  }) {
    requestedPolicies.add(policy);
    return _results[_index++];
  }

  @override
  Stream<AppResult<OverviewProgressiveSnapshot>> loadOverviewProgressively({
    required String userId,
    OverviewLoadPolicy policy = OverviewLoadPolicy.defaultLoad,
    DashboardFilter filter = const DashboardFilter(),
    OverviewLoadLabels? rowLabels,
    AgentQueriesCancelScope? cancelScope,
  }) async* {
    yield _asSnapshot(
      await loadOverview(
        userId: userId,
        policy: policy,
        filter: filter,
        rowLabels: rowLabels,
        cancelScope: cancelScope,
      ),
    );
  }
}

AppResult<OverviewProgressiveSnapshot> _asSnapshot(
  AppResult<Overview> result,
) {
  return result.fold(
    (overview) => Success<OverviewProgressiveSnapshot, AppFailure>(
      OverviewProgressiveSnapshot(
        overview: overview,
        completedSections: Set<OverviewProgressiveSection>.of(
          OverviewProgressiveSection.values,
        ),
        pendingSections: const <OverviewProgressiveSection>{},
        isFinal: true,
      ),
    ),
    Failure<OverviewProgressiveSnapshot, AppFailure>.new,
  );
}

class _RecordingDiscoverRepository implements AgentMetaRepository {
  final List<String> requestedAgentIds = <String>[];

  @override
  Future<AppResult<AgentRpcDescriptor>> discoverAgentRpc({
    required String agentId,
  }) {
    requestedAgentIds.add(agentId);
    return Future<AppResult<AgentRpcDescriptor>>.value(
      const Success<AgentRpcDescriptor, AppFailure>(
        AgentRpcDescriptor(methods: <String>{'sql.execute'}),
      ),
    );
  }

  @override
  Future<AppResult<AgentProfileSnapshot>> getAgentProfile({
    required String agentId,
    String? clientToken,
  }) => throw UnimplementedError();

  @override
  Future<AppResult<ClientTokenPolicySnapshot>> getClientTokenPolicy({
    required String agentId,
    required String clientToken,
  }) => throw UnimplementedError();
}

Overview _overview(
  String paymentMethodCode, {
  List<String> agentIdsMissingClientToken = const <String>[],
  List<String> agentNamesSkippedDueToHubPresence = const <String>[],
}) {
  return Overview(
    periodStart: DateTime(2026, 3, 9),
    periodEnd: DateTime(2026, 4, 7),
    kpis: const OverviewPaymentKpis(
      totalSalesCount: 100,
      totalAmount: 9000,
      averageTicket: 90,
      paymentMethodCount: 1,
    ),
    paymentMethods: <OverviewPaymentMethodBreakdown>[
      OverviewPaymentMethodBreakdown(
        code: paymentMethodCode,
        label: paymentMethodCode,
        totalSalesCount: 100,
        totalAmount: 9000,
        averageTicket: 90,
        sharePercent: 100,
      ),
    ],
    agentIdsMissingClientToken: agentIdsMissingClientToken,
    agentNamesSkippedDueToHubPresence: agentNamesSkippedDueToHubPresence,
    agentIdsSkippedDueToHubPresence: agentNamesSkippedDueToHubPresence
        .map((n) => n.trim().toLowerCase())
        .toSet()
        .toList(),
    agentRankings: const <OverviewAgentRanking>[
      OverviewAgentRanking(
        agentId: 'a1',
        displayName: 'Agente 1',
        totalSalesCount: 100,
        totalAmount: 9000,
      ),
    ],
    userRankings: const <OverviewUserRanking>[
      OverviewUserRanking(
        userName: 'Caixa 01',
        totalSalesCount: 100,
        totalAmount: 9000,
        averageTicket: 90,
      ),
    ],
  );
}
