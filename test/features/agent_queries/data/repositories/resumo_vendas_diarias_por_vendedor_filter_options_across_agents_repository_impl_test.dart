import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_executor.dart';
import 'package:colmeia/features/agent_queries/application/orchestration/agent_query_plan_builder.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_bairro_options_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_municipio_options_use_case.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_vendas_diarias_por_vendedor_vendedor_options_use_case.dart';
import 'package:colmeia/features/agent_queries/data/orchestration/agent_query_target_resolver.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_vendas_diarias_por_vendedor_filter_options_across_agents_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/resumo_vendas_diarias_suggestion_sql_params.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_plan.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target_resolution.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_text_option.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_vendedor_option.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockTargetResolver extends Mock implements AgentQueryTargetResolver {}

class _MockPlanBuilder extends Mock implements AgentQueryPlanBuilder {}

class _MockLoadVendedorOptions extends Mock
    implements LoadResumoVendasDiariasPorVendedorVendedorOptionsUseCase {}

class _MockLoadBairroOptions extends Mock
    implements LoadResumoVendasDiariasPorVendedorBairroOptionsUseCase {}

class _MockLoadMunicipioOptions extends Mock
    implements LoadResumoVendasDiariasPorVendedorMunicipioOptionsUseCase {}

void main() {
  late _MockTargetResolver targetResolver;
  late _MockPlanBuilder planBuilder;
  late AgentQueryExecutor<ResumoVendasDiariasPorVendedorVendedorOption>
  vendedorExecutor;
  late AgentQueryExecutor<ResumoVendasDiariasPorVendedorTextOption>
  textExecutor;
  late _MockLoadVendedorOptions loadVendedorOptions;
  late _MockLoadBairroOptions loadBairroOptions;
  late _MockLoadMunicipioOptions loadMunicipioOptions;
  late ResumoVendasDiariasPorVendedorFilterOptionsAcrossAgentsRepositoryImpl
  repository;

  final dataInicio = DateTime.utc(2026, 4);
  final dataFim = DateTime.utc(2026, 4, 30);

  setUpAll(() {
    registerFallbackValue(
      const AgentQueryTargetResolution(
        consideredApprovedTargets: <AgentQueryTarget>[],
        missingClientTokenTargets: <AgentQueryTarget>[],
        consideredApprovedAgentCount: 0,
      ),
    );
    registerFallbackValue(AgentQueryKey.resumoVendasDiariasOptsVendedor);
    registerFallbackValue(AgentQueryExecutionStrategy.mergeAll);
  });

  setUp(() {
    targetResolver = _MockTargetResolver();
    planBuilder = _MockPlanBuilder();
    vendedorExecutor =
        AgentQueryExecutor<ResumoVendasDiariasPorVendedorVendedorOption>();
    textExecutor =
        AgentQueryExecutor<ResumoVendasDiariasPorVendedorTextOption>();
    loadVendedorOptions = _MockLoadVendedorOptions();
    loadBairroOptions = _MockLoadBairroOptions();
    loadMunicipioOptions = _MockLoadMunicipioOptions();
    repository =
        ResumoVendasDiariasPorVendedorFilterOptionsAcrossAgentsRepositoryImpl(
          targetResolver: targetResolver,
          planBuilder: planBuilder,
          vendedorExecutor: vendedorExecutor,
          textExecutor: textExecutor,
          loadVendedorOptions: loadVendedorOptions,
          loadBairroOptions: loadBairroOptions,
          loadMunicipioOptions: loadMunicipioOptions,
        );
  });

  group('date range validation', () {
    test('should reject inverted range without resolving targets', () async {
      final result = await repository.loadVendedorOptions(
        userId: 'user-1',
        dataVendaInicio: dataFim,
        dataVendaFim: dataInicio,
      );

      check(result.isError()).isTrue();
      check(result.exceptionOrNull()).isA<ValidationFailure>();
      verifyNever(
        () => targetResolver.resolve(
          userId: any(named: 'userId'),
          selectedAgentIds: any(named: 'selectedAgentIds'),
        ),
      );
    });
  });

  group('vendedor options', () {
    test(
      'should dedupe by codVendedor and prefer lowest nome lexicographically',
      () async {
        final targetA = _target('agent-a', clientToken: 'tok-a');
        final targetB = _target('agent-b', clientToken: 'tok-b');
        final resolution = AgentQueryTargetResolution(
          consideredApprovedTargets: <AgentQueryTarget>[targetA, targetB],
          missingClientTokenTargets: const <AgentQueryTarget>[],
          consideredApprovedAgentCount: 2,
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
        ).thenAnswer((invocation) {
          final key = invocation.namedArguments[#queryKey] as AgentQueryKey;
          final strategy =
              invocation.namedArguments[#strategy]
                  as AgentQueryExecutionStrategy;
          final res =
              invocation.namedArguments[#resolution]
                  as AgentQueryTargetResolution;
          final timeout = invocation.namedArguments[#bridgeTimeoutMs] as int?;
          return Success<AgentQueryPlan, AppFailure>(
            AgentQueryPlan(
              queryKey: key,
              strategy: strategy,
              consideredApprovedAgentCount: res.consideredApprovedAgentCount,
              plannedTargets: <AgentQueryTarget>[targetA, targetB],
              missingClientTokenTargets: const <AgentQueryTarget>[],
              bridgeTimeoutMs: timeout ?? 120000,
            ),
          );
        });

        when(
          () => loadVendedorOptions(
            agentId: any(named: 'agentId'),
            dataVendaInicio: any(named: 'dataVendaInicio'),
            dataVendaFim: any(named: 'dataVendaFim'),
            searchTerm: any(named: 'searchTerm'),
            limit: any(named: 'limit'),
            clientToken: any(named: 'clientToken'),
            bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
          ),
        ).thenAnswer((invocation) async {
          final agentId = invocation.namedArguments[#agentId] as String;
          if (agentId == 'agent-a') {
            return const Success<
              List<ResumoVendasDiariasPorVendedorVendedorOption>,
              AppFailure
            >(
              <ResumoVendasDiariasPorVendedorVendedorOption>[
                ResumoVendasDiariasPorVendedorVendedorOption(
                  codVendedor: 1,
                  nomeVendedor: 'Beto',
                ),
              ],
            );
          }
          return const Success<
            List<ResumoVendasDiariasPorVendedorVendedorOption>,
            AppFailure
          >(
            <ResumoVendasDiariasPorVendedorVendedorOption>[
              ResumoVendasDiariasPorVendedorVendedorOption(
                codVendedor: 1,
                nomeVendedor: 'Anna',
              ),
            ],
          );
        });

        final result = await repository.loadVendedorOptions(
          userId: 'user-1',
          dataVendaInicio: dataInicio,
          dataVendaFim: dataFim,
        );

        check(result.isSuccess()).isTrue();
        final options = result.getOrThrow();
        check(options).length.equals(1);
        check(options.single.codVendedor).equals(1);
        check(options.single.nomeVendedor).equals('Anna');
        verify(
          () => planBuilder.build(
            queryKey: AgentQueryKey.resumoVendasDiariasOptsVendedor,
            strategy: any(named: 'strategy'),
            resolution: any(named: 'resolution'),
            bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
            raceMaxSources: any(named: 'raceMaxSources'),
          ),
        ).called(1);
      },
    );

    test(
      'uses scaled per-agent fetch limit when multiple targets are planned',
      () async {
        final targetA = _target('agent-a', clientToken: 'tok-a');
        final targetB = _target('agent-b', clientToken: 'tok-b');
        final resolution = AgentQueryTargetResolution(
          consideredApprovedTargets: <AgentQueryTarget>[targetA, targetB],
          missingClientTokenTargets: const <AgentQueryTarget>[],
          consideredApprovedAgentCount: 2,
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
        ).thenAnswer((invocation) {
          final key = invocation.namedArguments[#queryKey] as AgentQueryKey;
          final strategy =
              invocation.namedArguments[#strategy]
                  as AgentQueryExecutionStrategy;
          final res =
              invocation.namedArguments[#resolution]
                  as AgentQueryTargetResolution;
          final timeout = invocation.namedArguments[#bridgeTimeoutMs] as int?;
          return Success<AgentQueryPlan, AppFailure>(
            AgentQueryPlan(
              queryKey: key,
              strategy: strategy,
              consideredApprovedAgentCount: res.consideredApprovedAgentCount,
              plannedTargets: <AgentQueryTarget>[targetA, targetB],
              missingClientTokenTargets: const <AgentQueryTarget>[],
              bridgeTimeoutMs: timeout ?? 120000,
            ),
          );
        });

        when(
          () => loadVendedorOptions(
            agentId: any(named: 'agentId'),
            dataVendaInicio: any(named: 'dataVendaInicio'),
            dataVendaFim: any(named: 'dataVendaFim'),
            searchTerm: any(named: 'searchTerm'),
            limit: any(named: 'limit'),
            clientToken: any(named: 'clientToken'),
            bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
          ),
        ).thenAnswer(
          (_) async => const Success<
            List<ResumoVendasDiariasPorVendedorVendedorOption>,
            AppFailure
          >(<ResumoVendasDiariasPorVendedorVendedorOption>[]),
        );

        final expectedPerAgent =
            ResumoVendasDiariasSuggestionSqlParams.perAgentSuggestionFetchLimit(
              mergeResultLimit:
                  ResumoVendasDiariasSuggestionSqlParams.defaultLimit,
              plannedTargetCount: 2,
            );

        await repository.loadVendedorOptions(
          userId: 'user-1',
          dataVendaInicio: dataInicio,
          dataVendaFim: dataFim,
        );

        check(expectedPerAgent).equals(40);
        verify(
          () => loadVendedorOptions(
            agentId: 'agent-a',
            dataVendaInicio: dataInicio,
            dataVendaFim: dataFim,
            limit: 40,
            clientToken: 'tok-a',
            bridgeTimeoutMs: 120000,
          ),
        ).called(1);
        verify(
          () => loadVendedorOptions(
            agentId: 'agent-b',
            dataVendaInicio: dataInicio,
            dataVendaFim: dataFim,
            limit: 40,
            clientToken: 'tok-b',
            bridgeTimeoutMs: 120000,
          ),
        ).called(1);
      },
    );

    test('should apply limit after deterministic merge', () async {
      final targetA = _target('agent-a');
      final targetB = _target('agent-b');
      final resolution = AgentQueryTargetResolution(
        consideredApprovedTargets: <AgentQueryTarget>[targetA, targetB],
        missingClientTokenTargets: const <AgentQueryTarget>[],
        consideredApprovedAgentCount: 2,
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
      ).thenAnswer((invocation) {
        final key = invocation.namedArguments[#queryKey] as AgentQueryKey;
        final strategy =
            invocation.namedArguments[#strategy] as AgentQueryExecutionStrategy;
        final res =
            invocation.namedArguments[#resolution]
                as AgentQueryTargetResolution;
        final timeout = invocation.namedArguments[#bridgeTimeoutMs] as int?;
        return Success<AgentQueryPlan, AppFailure>(
          AgentQueryPlan(
            queryKey: key,
            strategy: strategy,
            consideredApprovedAgentCount: res.consideredApprovedAgentCount,
            plannedTargets: <AgentQueryTarget>[targetA, targetB],
            missingClientTokenTargets: const <AgentQueryTarget>[],
            bridgeTimeoutMs: timeout ?? 120000,
          ),
        );
      });

      when(
        () => loadVendedorOptions(
          agentId: any(named: 'agentId'),
          dataVendaInicio: any(named: 'dataVendaInicio'),
          dataVendaFim: any(named: 'dataVendaFim'),
          searchTerm: any(named: 'searchTerm'),
          limit: any(named: 'limit'),
          clientToken: any(named: 'clientToken'),
          bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
        ),
      ).thenAnswer((invocation) async {
        final agentId = invocation.namedArguments[#agentId] as String;
        if (agentId == 'agent-a') {
          return const Success<
            List<ResumoVendasDiariasPorVendedorVendedorOption>,
            AppFailure
          >(
            <ResumoVendasDiariasPorVendedorVendedorOption>[
              ResumoVendasDiariasPorVendedorVendedorOption(
                codVendedor: 1,
                nomeVendedor: 'Zed',
              ),
              ResumoVendasDiariasPorVendedorVendedorOption(
                codVendedor: 2,
                nomeVendedor: 'Amy',
              ),
            ],
          );
        }
        return const Success<
          List<ResumoVendasDiariasPorVendedorVendedorOption>,
          AppFailure
        >(
          <ResumoVendasDiariasPorVendedorVendedorOption>[
            ResumoVendasDiariasPorVendedorVendedorOption(
              codVendedor: 1,
              nomeVendedor: 'Other',
            ),
          ],
        );
      });

      final result = await repository.loadVendedorOptions(
        userId: 'user-1',
        dataVendaInicio: dataInicio,
        dataVendaFim: dataFim,
        limit: 1,
      );

      check(result.isSuccess()).isTrue();
      final options = result.getOrThrow();
      check(options).length.equals(1);
      check(options.single.nomeVendedor).equals('Amy');
    });

    test(
      'should preserve source agent ids when all targets fail',
      () async {
        final targetA = _target('agent-b');
        final targetB = _target('agent-a');
        final resolution = AgentQueryTargetResolution(
          consideredApprovedTargets: <AgentQueryTarget>[targetA, targetB],
          missingClientTokenTargets: const <AgentQueryTarget>[],
          consideredApprovedAgentCount: 2,
        );
        final plan = AgentQueryPlan(
          queryKey: AgentQueryKey.resumoVendasDiariasOptsVendedor,
          strategy: AgentQueryExecutionStrategy.mergeAll,
          consideredApprovedAgentCount: 2,
          plannedTargets: <AgentQueryTarget>[targetA, targetB],
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
          () => loadVendedorOptions(
            agentId: any(named: 'agentId'),
            dataVendaInicio: any(named: 'dataVendaInicio'),
            dataVendaFim: any(named: 'dataVendaFim'),
            searchTerm: any(named: 'searchTerm'),
            limit: any(named: 'limit'),
            clientToken: any(named: 'clientToken'),
            bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
          ),
        ).thenAnswer(
          (_) async =>
              const Failure<
                List<ResumoVendasDiariasPorVendedorVendedorOption>,
                AppFailure
              >(
                NetworkFailure(message: 'failed', userMessage: 'failed'),
              ),
        );

        final result = await repository.loadVendedorOptions(
          userId: 'user-1',
          dataVendaInicio: dataInicio,
          dataVendaFim: dataFim,
        );

        check(result.isError()).isTrue();
        final failure = result.exceptionOrNull()!;
        check(
          failure.context['sourceAgentIds']! as List<String>,
        ).deepEquals(const <String>['agent-a', 'agent-b']);
      },
    );

    test(
      'should return merged options when one target fails and another succeeds',
      () async {
        final targetA = _target('agent-a');
        final targetB = _target('agent-b');
        final resolution = AgentQueryTargetResolution(
          consideredApprovedTargets: <AgentQueryTarget>[targetA, targetB],
          missingClientTokenTargets: const <AgentQueryTarget>[],
          consideredApprovedAgentCount: 2,
        );
        final plan = AgentQueryPlan(
          queryKey: AgentQueryKey.resumoVendasDiariasOptsVendedor,
          strategy: AgentQueryExecutionStrategy.mergeAll,
          consideredApprovedAgentCount: 2,
          plannedTargets: <AgentQueryTarget>[targetA, targetB],
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
          () => loadVendedorOptions(
            agentId: any(named: 'agentId'),
            dataVendaInicio: any(named: 'dataVendaInicio'),
            dataVendaFim: any(named: 'dataVendaFim'),
            searchTerm: any(named: 'searchTerm'),
            limit: any(named: 'limit'),
            clientToken: any(named: 'clientToken'),
            bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
          ),
        ).thenAnswer((invocation) async {
          final id = invocation.namedArguments[#agentId] as String;
          if (id == 'agent-a') {
            return const Failure<
              List<ResumoVendasDiariasPorVendedorVendedorOption>,
              AppFailure
            >(
              NetworkFailure(message: 'down', userMessage: 'down'),
            );
          }
          return const Success<
            List<ResumoVendasDiariasPorVendedorVendedorOption>,
            AppFailure
          >(
            <ResumoVendasDiariasPorVendedorVendedorOption>[
              ResumoVendasDiariasPorVendedorVendedorOption(
                codVendedor: 9,
                nomeVendedor: 'Zoe',
              ),
            ],
          );
        });

        final result = await repository.loadVendedorOptions(
          userId: 'user-1',
          dataVendaInicio: dataInicio,
          dataVendaFim: dataFim,
        );

        check(result.isSuccess()).isTrue();
        final options = result.getOrThrow();
        check(options).length.equals(1);
        check(options.single.codVendedor).equals(9);
      },
    );
  });

  group('bairro options', () {
    test('should call plan builder with bairro query key', () async {
      final target = _target('agent-a');
      final resolution = AgentQueryTargetResolution(
        consideredApprovedTargets: <AgentQueryTarget>[target],
        missingClientTokenTargets: const <AgentQueryTarget>[],
        consideredApprovedAgentCount: 1,
      );
      final plan = AgentQueryPlan(
        queryKey: AgentQueryKey.resumoVendasDiariasOptsBairro,
        strategy: AgentQueryExecutionStrategy.mergeAll,
        consideredApprovedAgentCount: 1,
        plannedTargets: <AgentQueryTarget>[target],
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
        () => loadBairroOptions(
          agentId: any(named: 'agentId'),
          dataVendaInicio: any(named: 'dataVendaInicio'),
          dataVendaFim: any(named: 'dataVendaFim'),
          searchTerm: any(named: 'searchTerm'),
          limit: any(named: 'limit'),
          clientToken: any(named: 'clientToken'),
          bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
        ),
      ).thenAnswer(
        (_) async =>
            const Success<
              List<ResumoVendasDiariasPorVendedorTextOption>,
              AppFailure
            >(
              <ResumoVendasDiariasPorVendedorTextOption>[
                ResumoVendasDiariasPorVendedorTextOption(value: 'Centro'),
              ],
            ),
      );

      await repository.loadBairroOptions(
        userId: 'user-1',
        dataVendaInicio: dataInicio,
        dataVendaFim: dataFim,
        selectedAgentIds: {'agent-a'},
      );

      verify(
        () => planBuilder.build(
          queryKey: AgentQueryKey.resumoVendasDiariasOptsBairro,
          strategy: any(named: 'strategy'),
          resolution: any(named: 'resolution'),
          bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
          raceMaxSources: any(named: 'raceMaxSources'),
        ),
      ).called(1);
      verify(
        () => targetResolver.resolve(
          userId: 'user-1',
          selectedAgentIds: {'agent-a'},
        ),
      ).called(1);
    });
  });

  group('municipio options', () {
    test(
      'should forward dates and search term to single-agent loader',
      () async {
        final target = _target('agent-x', clientToken: 'tok-x');
        final resolution = AgentQueryTargetResolution(
          consideredApprovedTargets: <AgentQueryTarget>[target],
          missingClientTokenTargets: const <AgentQueryTarget>[],
          consideredApprovedAgentCount: 1,
        );
        final plan = AgentQueryPlan(
          queryKey: AgentQueryKey.resumoVendasDiariasOptsMunicipio,
          strategy: AgentQueryExecutionStrategy.mergeAll,
          consideredApprovedAgentCount: 1,
          plannedTargets: <AgentQueryTarget>[target],
          missingClientTokenTargets: const <AgentQueryTarget>[],
          bridgeTimeoutMs: 90000,
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
          () => loadMunicipioOptions(
            agentId: any(named: 'agentId'),
            dataVendaInicio: any(named: 'dataVendaInicio'),
            dataVendaFim: any(named: 'dataVendaFim'),
            searchTerm: any(named: 'searchTerm'),
            limit: any(named: 'limit'),
            clientToken: any(named: 'clientToken'),
            bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
          ),
        ).thenAnswer(
          (_) async =>
              const Success<
                List<ResumoVendasDiariasPorVendedorTextOption>,
                AppFailure
              >(
                <ResumoVendasDiariasPorVendedorTextOption>[],
              ),
        );

        await repository.loadMunicipioOptions(
          userId: 'user-1',
          dataVendaInicio: dataInicio,
          dataVendaFim: dataFim,
          searchTerm: '  Rio  ',
          limit: 15,
        );

        verify(
          () => loadMunicipioOptions(
            agentId: 'agent-x',
            dataVendaInicio: dataInicio,
            dataVendaFim: dataFim,
            searchTerm: '  Rio  ',
            limit: 15,
            clientToken: 'tok-x',
            bridgeTimeoutMs: 90000,
          ),
        ).called(1);
      },
    );
  });
}

AgentQueryTarget _target(String agentId, {String? clientToken = 'token'}) {
  return AgentQueryTarget(
    agentId: agentId,
    displayName: agentId,
    connectionStatus: AgentConnectionStatus.online,
    clientToken: clientToken,
  );
}
