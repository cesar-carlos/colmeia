import 'dart:math' as math;

import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_executor.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_plan_builder.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_cadastro_filial_page_use_case.dart';
import 'package:colmeia/features/agent_queries/data/orchestration/agent_query_target_resolver.dart';
import 'package:colmeia/features/agent_queries/data/repositories/cadastro_filial_across_agents_repository_impl.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_plan.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_row.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockTargetResolver extends Mock implements AgentQueryTargetResolver {}

class _MockPlanBuilder extends Mock implements AgentQueryPlanBuilder {}

class _MockLoadCadastroFilial extends Mock
    implements LoadCadastroFilialPageUseCase {}

void main() {
  late _MockTargetResolver targetResolver;
  late _MockPlanBuilder planBuilder;
  late AgentQueryExecutor<CadastroFilialRow> executor;
  late _MockLoadCadastroFilial loadCadastroFilial;
  late CadastroFilialAcrossAgentsRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(const CadastroFilialFilter());
    registerFallbackValue(
      const AgentQueryTargetResolution(
        consideredApprovedTargets: <AgentQueryTarget>[],
        missingClientTokenTargets: <AgentQueryTarget>[],
        consideredApprovedAgentCount: 0,
      ),
    );
    registerFallbackValue(AgentQueryKey.cadastroFilial);
    registerFallbackValue(AgentQueryExecutionStrategy.mergeAll);
  });

  setUp(() {
    targetResolver = _MockTargetResolver();
    planBuilder = _MockPlanBuilder();
    executor = AgentQueryExecutor<CadastroFilialRow>();
    loadCadastroFilial = _MockLoadCadastroFilial();
    repository = CadastroFilialAcrossAgentsRepositoryImpl(
      targetResolver: targetResolver,
      planBuilder: planBuilder,
      executor: executor,
      loadCadastroFilial: loadCadastroFilial,
    );
  });

  test(
    'executes paged branch registration query for planned targets',
    () async {
      final targetWithToken = _target('agent-a', clientToken: 'tok-a');
      final resolution = AgentQueryTargetResolution(
        consideredApprovedTargets: <AgentQueryTarget>[targetWithToken],
        missingClientTokenTargets: const <AgentQueryTarget>[],
        consideredApprovedAgentCount: 1,
      );
      final plan = AgentQueryPlan(
        queryKey: AgentQueryKey.cadastroFilial,
        strategy: AgentQueryExecutionStrategy.mergeAll,
        consideredApprovedAgentCount: 1,
        plannedTargets: <AgentQueryTarget>[targetWithToken],
        missingClientTokenTargets: const <AgentQueryTarget>[],
        bridgeTimeoutMs: 120000,
      );

      when(
        () => targetResolver.resolve(
          userId: any(named: 'userId'),
          selectedAgentIds: any(named: 'selectedAgentIds'),
        ),
      ).thenAnswer(
        (_) async =>
            Success<AgentQueryTargetResolution, AppFailure>(resolution),
      );
      when(
        () => planBuilder.build(
          queryKey: any(named: 'queryKey'),
          strategy: any(named: 'strategy'),
          resolution: any(named: 'resolution'),
          bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
          raceMaxSources: any(named: 'raceMaxSources'),
        ),
      ).thenReturn(Success<AgentQueryPlan, AppFailure>(plan));
      when(
        () => loadCadastroFilial(
          userId: any(named: 'userId'),
          agentId: any(named: 'agentId'),
          filter: any(named: 'filter'),
          clientToken: any(named: 'clientToken'),
          bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
          hubPresenceOnlineAgentIdsSnapshot: any(
            named: 'hubPresenceOnlineAgentIdsSnapshot',
          ),
          hubConnectedFromApprovedCatalogRow: any(
            named: 'hubConnectedFromApprovedCatalogRow',
          ),
        ),
      ).thenAnswer(
        (_) async => const Success<CadastroFilialPageResult, AppFailure>(
          CadastroFilialPageResult(
            items: <CadastroFilialRow>[
              CadastroFilialRow(
                codEmpresa: 1,
                codFilial: 2,
                nomeFilial: 'Filial',
              ),
            ],
            totalCount: 5,
          ),
        ),
      );

      const filter = CadastroFilialFilter(codEmpresa: 1, pageSize: 10);
      final result = await repository.loadPage(
        userId: 'user-1',
        filter: filter,
      );

      check(result.isSuccess()).isTrue();
      final page = result.getOrThrow();
      check(page.report.queryKey).equals(AgentQueryKey.cadastroFilial);
      check(
        page.report.mergedRows,
      ).has((rows) => rows.length, 'length').equals(1);
      check(page.totalCountByAgentId['agent-a']).equals(5);
      check(page.totalCount).equals(5);
      check(page.report.participants.single.sourceRowCount).equals(5);
      verify(
        () => loadCadastroFilial(
          userId: 'user-1',
          agentId: 'agent-a',
          filter: filter,
          clientToken: 'tok-a',
          bridgeTimeoutMs: 120000,
          hubPresenceOnlineAgentIdsSnapshot: any(
            named: 'hubPresenceOnlineAgentIdsSnapshot',
          ),
          hubConnectedFromApprovedCatalogRow: any(
            named: 'hubConnectedFromApprovedCatalogRow',
          ),
        ),
      ).called(1);
    },
  );

  test(
    'loadAll paginates each planned target until all branch rows are loaded',
    () async {
      final targetWithToken = _target('agent-a', clientToken: 'tok-a');
      final resolution = AgentQueryTargetResolution(
        consideredApprovedTargets: <AgentQueryTarget>[targetWithToken],
        missingClientTokenTargets: const <AgentQueryTarget>[],
        consideredApprovedAgentCount: 1,
      );
      final plan = AgentQueryPlan(
        queryKey: AgentQueryKey.cadastroFilial,
        strategy: AgentQueryExecutionStrategy.mergeAll,
        consideredApprovedAgentCount: 1,
        plannedTargets: <AgentQueryTarget>[targetWithToken],
        missingClientTokenTargets: const <AgentQueryTarget>[],
        bridgeTimeoutMs: 120000,
      );

      when(
        () => targetResolver.resolve(
          userId: any(named: 'userId'),
          selectedAgentIds: any(named: 'selectedAgentIds'),
        ),
      ).thenAnswer(
        (_) async =>
            Success<AgentQueryTargetResolution, AppFailure>(resolution),
      );
      when(
        () => planBuilder.build(
          queryKey: any(named: 'queryKey'),
          strategy: any(named: 'strategy'),
          resolution: any(named: 'resolution'),
          bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
          raceMaxSources: any(named: 'raceMaxSources'),
        ),
      ).thenReturn(Success<AgentQueryPlan, AppFailure>(plan));
      when(
        () => loadCadastroFilial(
          userId: any(named: 'userId'),
          agentId: any(named: 'agentId'),
          filter: any(named: 'filter'),
          clientToken: any(named: 'clientToken'),
          bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
          hubPresenceOnlineAgentIdsSnapshot: any(
            named: 'hubPresenceOnlineAgentIdsSnapshot',
          ),
          hubConnectedFromApprovedCatalogRow: any(
            named: 'hubConnectedFromApprovedCatalogRow',
          ),
        ),
      ).thenAnswer((invocation) async {
        final filter =
            invocation.namedArguments[#filter] as CadastroFilialFilter;
        const totalCount = 150;
        final start = filter.offset + 1;
        final end = math.min(filter.offset + filter.pageSize, totalCount);
        return Success<CadastroFilialPageResult, AppFailure>(
          CadastroFilialPageResult(
            items: <CadastroFilialRow>[
              for (var i = start; i <= end; i++)
                CadastroFilialRow(
                  codEmpresa: 1,
                  codFilial: i,
                  nomeFilial: 'Filial $i',
                ),
            ],
            totalCount: totalCount,
          ),
        );
      });

      final result = await repository.loadAll(
        userId: 'user-1',
        filter: const CadastroFilialFilter(),
      );

      check(result.isSuccess()).isTrue();
      final page = result.getOrThrow();
      check(page.report.mergedRows)
          .has((rows) => rows.length, 'length')
          .equals(
            150,
          );
      check(page.totalCountByAgentId['agent-a']).equals(150);
      check(page.report.participants.single.sourceRowCount).equals(150);
      final captured = verify(
        () => loadCadastroFilial(
          userId: 'user-1',
          agentId: 'agent-a',
          filter: captureAny(named: 'filter'),
          clientToken: 'tok-a',
          bridgeTimeoutMs: 120000,
          hubPresenceOnlineAgentIdsSnapshot: any(
            named: 'hubPresenceOnlineAgentIdsSnapshot',
          ),
          hubConnectedFromApprovedCatalogRow: any(
            named: 'hubConnectedFromApprovedCatalogRow',
          ),
        ),
      ).captured.cast<CadastroFilialFilter>();
      check(
        captured.map((filter) => filter.page).toList(),
      ).deepEquals(<int>[1]);
      check(captured.map((filter) => filter.pageSize).toSet()).deepEquals(
        <int>{CadastroFilialFilter.maxPageSize},
      );
    },
  );

  test(
    'loadAll stops when a repeated page adds no new branch rows',
    () async {
      final targetWithToken = _target('agent-a', clientToken: 'tok-a');
      final resolution = AgentQueryTargetResolution(
        consideredApprovedTargets: <AgentQueryTarget>[targetWithToken],
        missingClientTokenTargets: const <AgentQueryTarget>[],
        consideredApprovedAgentCount: 1,
      );
      final plan = AgentQueryPlan(
        queryKey: AgentQueryKey.cadastroFilial,
        strategy: AgentQueryExecutionStrategy.mergeAll,
        consideredApprovedAgentCount: 1,
        plannedTargets: <AgentQueryTarget>[targetWithToken],
        missingClientTokenTargets: const <AgentQueryTarget>[],
        bridgeTimeoutMs: 120000,
      );

      when(
        () => targetResolver.resolve(
          userId: any(named: 'userId'),
          selectedAgentIds: any(named: 'selectedAgentIds'),
        ),
      ).thenAnswer(
        (_) async =>
            Success<AgentQueryTargetResolution, AppFailure>(resolution),
      );
      when(
        () => planBuilder.build(
          queryKey: any(named: 'queryKey'),
          strategy: any(named: 'strategy'),
          resolution: any(named: 'resolution'),
          bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
          raceMaxSources: any(named: 'raceMaxSources'),
        ),
      ).thenReturn(Success<AgentQueryPlan, AppFailure>(plan));
      when(
        () => loadCadastroFilial(
          userId: any(named: 'userId'),
          agentId: any(named: 'agentId'),
          filter: any(named: 'filter'),
          clientToken: any(named: 'clientToken'),
          bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
          hubPresenceOnlineAgentIdsSnapshot: any(
            named: 'hubPresenceOnlineAgentIdsSnapshot',
          ),
          hubConnectedFromApprovedCatalogRow: any(
            named: 'hubConnectedFromApprovedCatalogRow',
          ),
        ),
      ).thenAnswer((invocation) async {
        const totalCount = 700;
        final rows = <CadastroFilialRow>[
          for (var i = 1; i <= CadastroFilialFilter.maxPageSize; i++)
            CadastroFilialRow(
              codEmpresa: 1,
              codFilial: i,
              nomeFilial: 'Filial $i',
            ),
        ];
        return Success<CadastroFilialPageResult, AppFailure>(
          CadastroFilialPageResult(
            items: rows,
            totalCount: totalCount,
          ),
        );
      });

      final result = await repository.loadAll(
        userId: 'user-1',
        filter: const CadastroFilialFilter(),
      );

      check(result.isSuccess()).isTrue();
      final page = result.getOrThrow();
      check(page.report.mergedRows)
          .has((rows) => rows.length, 'length')
          .equals(CadastroFilialFilter.maxPageSize);
      check(
            page.report.mergedRows.map((row) => row.codFilial).toSet(),
          )
          .has((it) => it.length, 'length')
          .equals(CadastroFilialFilter.maxPageSize);
      check(
        page.totalCountByAgentId['agent-a'],
      ).equals(CadastroFilialFilter.maxPageSize);
      check(page.report.participants.single.sourceRowCount).equals(
        CadastroFilialFilter.maxPageSize,
      );
      final captured = verify(
        () => loadCadastroFilial(
          userId: 'user-1',
          agentId: 'agent-a',
          filter: captureAny(named: 'filter'),
          clientToken: 'tok-a',
          bridgeTimeoutMs: 120000,
          hubPresenceOnlineAgentIdsSnapshot: any(
            named: 'hubPresenceOnlineAgentIdsSnapshot',
          ),
          hubConnectedFromApprovedCatalogRow: any(
            named: 'hubConnectedFromApprovedCatalogRow',
          ),
        ),
      ).captured.cast<CadastroFilialFilter>();
      check(captured.map((filter) => filter.page).toList()).deepEquals(
        <int>[1, 2],
      );
    },
  );

  test(
    'loadAll keeps paginating when the next page overlaps but still adds new rows',
    () async {
      const expectedTotalCount = 600;
      final targetWithToken = _target('agent-a', clientToken: 'tok-a');
      final resolution = AgentQueryTargetResolution(
        consideredApprovedTargets: <AgentQueryTarget>[targetWithToken],
        missingClientTokenTargets: const <AgentQueryTarget>[],
        consideredApprovedAgentCount: 1,
      );
      final plan = AgentQueryPlan(
        queryKey: AgentQueryKey.cadastroFilial,
        strategy: AgentQueryExecutionStrategy.mergeAll,
        consideredApprovedAgentCount: 1,
        plannedTargets: <AgentQueryTarget>[targetWithToken],
        missingClientTokenTargets: const <AgentQueryTarget>[],
        bridgeTimeoutMs: 120000,
      );

      when(
        () => targetResolver.resolve(
          userId: any(named: 'userId'),
          selectedAgentIds: any(named: 'selectedAgentIds'),
        ),
      ).thenAnswer(
        (_) async =>
            Success<AgentQueryTargetResolution, AppFailure>(resolution),
      );
      when(
        () => planBuilder.build(
          queryKey: any(named: 'queryKey'),
          strategy: any(named: 'strategy'),
          resolution: any(named: 'resolution'),
          bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
          raceMaxSources: any(named: 'raceMaxSources'),
        ),
      ).thenReturn(Success<AgentQueryPlan, AppFailure>(plan));
      when(
        () => loadCadastroFilial(
          userId: any(named: 'userId'),
          agentId: any(named: 'agentId'),
          filter: any(named: 'filter'),
          clientToken: any(named: 'clientToken'),
          bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
          hubPresenceOnlineAgentIdsSnapshot: any(
            named: 'hubPresenceOnlineAgentIdsSnapshot',
          ),
          hubConnectedFromApprovedCatalogRow: any(
            named: 'hubConnectedFromApprovedCatalogRow',
          ),
        ),
      ).thenAnswer((invocation) async {
        final filter =
            invocation.namedArguments[#filter] as CadastroFilialFilter;
        const totalCount = expectedTotalCount;
        if (filter.page == 1) {
          return Success<CadastroFilialPageResult, AppFailure>(
            CadastroFilialPageResult(
              items: <CadastroFilialRow>[
                for (var i = 1; i <= CadastroFilialFilter.maxPageSize; i++)
                  CadastroFilialRow(
                    codEmpresa: 1,
                    codFilial: i,
                    nomeFilial: 'Filial $i',
                  ),
              ],
              totalCount: totalCount,
            ),
          );
        }
        return Success<CadastroFilialPageResult, AppFailure>(
          CadastroFilialPageResult(
            items: <CadastroFilialRow>[
              for (var i = 251; i <= totalCount; i++)
                CadastroFilialRow(
                  codEmpresa: 1,
                  codFilial: i,
                  nomeFilial: 'Filial $i',
                ),
            ],
            totalCount: totalCount,
          ),
        );
      });

      final result = await repository.loadAll(
        userId: 'user-1',
        filter: const CadastroFilialFilter(),
      );

      check(result.isSuccess()).isTrue();
      final page = result.getOrThrow();
      check(page.report.mergedRows)
          .has((rows) => rows.length, 'length')
          .equals(
            expectedTotalCount,
          );
      check(
        page.report.mergedRows.map((row) => row.codFilial).toSet(),
      ).has((it) => it.length, 'length').equals(expectedTotalCount);
      check(page.totalCountByAgentId['agent-a']).equals(expectedTotalCount);
      check(page.report.participants.single.sourceRowCount).equals(
        expectedTotalCount,
      );
      final captured = verify(
        () => loadCadastroFilial(
          userId: 'user-1',
          agentId: 'agent-a',
          filter: captureAny(named: 'filter'),
          clientToken: 'tok-a',
          bridgeTimeoutMs: 120000,
          hubPresenceOnlineAgentIdsSnapshot: any(
            named: 'hubPresenceOnlineAgentIdsSnapshot',
          ),
          hubConnectedFromApprovedCatalogRow: any(
            named: 'hubConnectedFromApprovedCatalogRow',
          ),
        ),
      ).captured.cast<CadastroFilialFilter>();
      check(captured.map((filter) => filter.page).toList()).deepEquals(
        <int>[1, 2],
      );
    },
  );

  test(
    'debounces repeated pagination-stalled warnings for the same agent and scope',
    () async {
      final previousSink = AppLogger.sink;
      final previousLevel = AppLogger.minimumLevel;
      final sink = _RecordingAppLogSink();
      var now = DateTime(2026, 5, 19, 10);
      AppLogger.sink = sink;
      AppLogger.minimumLevel = Level.off;
      addTearDown(() {
        AppLogger.sink = previousSink;
        AppLogger.minimumLevel = previousLevel;
      });

      final targetWithToken = _target('agent-a', clientToken: 'tok-a');
      final resolution = AgentQueryTargetResolution(
        consideredApprovedTargets: <AgentQueryTarget>[targetWithToken],
        missingClientTokenTargets: const <AgentQueryTarget>[],
        consideredApprovedAgentCount: 1,
      );
      final plan = AgentQueryPlan(
        queryKey: AgentQueryKey.cadastroFilial,
        strategy: AgentQueryExecutionStrategy.mergeAll,
        consideredApprovedAgentCount: 1,
        plannedTargets: <AgentQueryTarget>[targetWithToken],
        missingClientTokenTargets: const <AgentQueryTarget>[],
        bridgeTimeoutMs: 120000,
      );
      repository = CadastroFilialAcrossAgentsRepositoryImpl(
        targetResolver: targetResolver,
        planBuilder: planBuilder,
        executor: executor,
        loadCadastroFilial: loadCadastroFilial,
        now: () => now,
      );

      when(
        () => targetResolver.resolve(
          userId: any(named: 'userId'),
          selectedAgentIds: any(named: 'selectedAgentIds'),
        ),
      ).thenAnswer(
        (_) async =>
            Success<AgentQueryTargetResolution, AppFailure>(resolution),
      );
      when(
        () => planBuilder.build(
          queryKey: any(named: 'queryKey'),
          strategy: any(named: 'strategy'),
          resolution: any(named: 'resolution'),
          bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
          raceMaxSources: any(named: 'raceMaxSources'),
        ),
      ).thenReturn(Success<AgentQueryPlan, AppFailure>(plan));
      when(
        () => loadCadastroFilial(
          userId: any(named: 'userId'),
          agentId: any(named: 'agentId'),
          filter: any(named: 'filter'),
          clientToken: any(named: 'clientToken'),
          bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
          hubPresenceOnlineAgentIdsSnapshot: any(
            named: 'hubPresenceOnlineAgentIdsSnapshot',
          ),
          hubConnectedFromApprovedCatalogRow: any(
            named: 'hubConnectedFromApprovedCatalogRow',
          ),
        ),
      ).thenAnswer((invocation) async {
        final filter =
            invocation.namedArguments[#filter] as CadastroFilialFilter;
        if (filter.page == 1) {
          return Success<CadastroFilialPageResult, AppFailure>(
            CadastroFilialPageResult(
              items: <CadastroFilialRow>[
                for (var i = 1; i <= CadastroFilialFilter.maxPageSize; i++)
                  CadastroFilialRow(
                    codEmpresa: 1,
                    codFilial: i,
                    nomeFilial: 'Filial $i',
                  ),
              ],
              totalCount: 700,
            ),
          );
        }
        return Success<CadastroFilialPageResult, AppFailure>(
          CadastroFilialPageResult(
            items: <CadastroFilialRow>[
              for (var i = 1; i <= CadastroFilialFilter.maxPageSize; i++)
                CadastroFilialRow(
                  codEmpresa: 1,
                  codFilial: i,
                  nomeFilial: 'Filial $i',
                ),
            ],
            totalCount: 700,
          ),
        );
      });

      await repository.loadAll(
        userId: 'user-1',
        filter: const CadastroFilialFilter(),
      );
      await repository.loadAll(
        userId: 'user-1',
        filter: const CadastroFilialFilter(),
      );

      check(
        sink.events
            .where(
              (event) =>
                  event.level == AppLogLevel.warning &&
                  event.message ==
                      'Cadastro filial pagination stalled without new rows',
            )
            .length,
      ).equals(1);

      now = now.add(const Duration(minutes: 16));
      await repository.loadAll(
        userId: 'user-1',
        filter: const CadastroFilialFilter(),
      );

      check(
        sink.events
            .where(
              (event) =>
                  event.level == AppLogLevel.warning &&
                  event.message ==
                      'Cadastro filial pagination stalled without new rows',
            )
            .length,
      ).equals(2);
    },
  );
}

AgentQueryTarget _target(String agentId, {String? clientToken = 'token'}) {
  return AgentQueryTarget(
    agentId: agentId,
    displayName: agentId,
    connectionStatus: AgentConnectionStatus.online,
    clientToken: clientToken,
  );
}

class _RecordingAppLogSink implements AppLogSink {
  final List<_RecordedLogEvent> events = <_RecordedLogEvent>[];

  @override
  void onLog({
    required AppLogLevel level,
    required String message,
    required Map<String, Object?> context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    events.add(
      _RecordedLogEvent(level: level, message: message, context: context),
    );
  }
}

class _RecordedLogEvent {
  const _RecordedLogEvent({
    required this.level,
    required this.message,
    required this.context,
  });

  final AppLogLevel level;
  final String message;
  final Map<String, Object?> context;
}
