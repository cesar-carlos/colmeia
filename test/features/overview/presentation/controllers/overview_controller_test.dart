import 'dart:async';

import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/errors/retry_after_gate.dart';
import 'package:colmeia/features/agent_meta/application/agent_rpc_capabilities_registry.dart';
import 'package:colmeia/features/agent_meta/application/usecases/discover_agent_rpc_methods_use_case.dart';
import 'package:colmeia/features/agent_meta/domain/entities/agent_profile_snapshot.dart';
import 'package:colmeia/features/agent_meta/domain/entities/agent_rpc_descriptor.dart';
import 'package:colmeia/features/agent_meta/domain/entities/client_token_policy.dart';
import 'package:colmeia/features/agent_meta/domain/repositories/agent_meta_repository.dart';
import 'package:colmeia/features/client_agents/domain/repositories/client_agents_repository.dart';
import 'package:colmeia/features/overview/application/usecases/load_overview_use_case.dart';
import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_ranking.dart';
import 'package:colmeia/features/overview/domain/entities/overview_load_labels.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_kpis.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_method_breakdown.dart';
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
        clientAgentsRepository,
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
          clientAgentsRepository,
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
        clientAgentsRepository,
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
        clientAgentsRepository,
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
          clientAgentsRepository,
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
          clientAgentsRepository,
          agentRpcCapabilitiesRegistry: registry,
        );

        await controller.loadOverview(userId: 'demo-user');

        // The fixture overview exposes agent `a1` as the only ranked
        // agent — registry should pick it up and discover exactly once.
        await Future<void>.delayed(Duration.zero);

        check(discoverRepository.requestedAgentIds).deepEquals(<String>['a1']);
        check(registry.descriptorFor('a1')!.supportsMethod('sql.execute'))
            .isTrue();
      },
    );

    test('should ignore late use case completion after dispose', () async {
      final completer = Completer<AppResult<Overview>>();
      final controller = OverviewController(
        LoadOverviewUseCase(
          _PendingOverviewRepository(completer.future),
        ),
        clientAgentsRepository,
      );

      final loadFuture = controller.loadOverview(userId: 'demo-user');

      await Future<void>.delayed(Duration.zero);
      controller.dispose();

      completer.complete(
        Success<Overview, AppFailure>(_overview('Pix')),
      );

      await loadFuture;
    });
  });
}

class _PendingOverviewRepository implements OverviewRepository {
  _PendingOverviewRepository(this._resultFuture);

  final Future<AppResult<Overview>> _resultFuture;

  @override
  Future<AppResult<Overview>> loadOverview({
    required String userId,
    OverviewLoadPolicy policy = OverviewLoadPolicy.defaultLoad,
    OverviewFilter filter = const OverviewFilter(),
    OverviewLoadLabels? rowLabels,
  }) {
    return _resultFuture;
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
    OverviewFilter filter = const OverviewFilter(),
    OverviewLoadLabels? rowLabels,
  }) {
    requestedPolicies.add(policy);
    return _results[_index++];
  }
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

Overview _overview(String paymentMethodCode) {
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
