import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/queries/ranking_produtos_faturamento_sql.dart';
import 'package:colmeia/features/agent_queries/data/repositories/ranking_produtos_faturamento_repository_impl.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/ranking_produtos_faturamento_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/ranking_produtos_faturamento_load_result.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockAgentQueriesRepository extends Mock
    implements AgentQueriesRepository {}

void main() {
  late _MockAgentQueriesRepository agentQueriesRepository;
  late RankingProdutosFaturamentoRepositoryImpl repository;

  final periodStart = DateTime(2026, 3, 10);
  final periodEnd = DateTime(2026, 4, 8);

  final filterTop3 = RankingProdutosFaturamentoFilter(
    dataVendaInicio: periodStart,
    dataVendaFim: periodEnd,
    quantidadeProdutos: 3,
  );

  setUpAll(() {
    registerFallbackValue(
      const AgentSqlExecuteRequest(
        agentId: 'fallback-agent',
        sql: 'SELECT 1',
      ),
    );
  });

  setUp(() {
    agentQueriesRepository = _MockAgentQueriesRepository();
    repository = RankingProdutosFaturamentoRepositoryImpl(
      agentQueriesRepository,
    );
  });

  test('returns validation failure when filter dates are invalid', () async {
    final result = await repository.load(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: RankingProdutosFaturamentoFilter(
        dataVendaInicio: periodEnd,
        dataVendaFim: periodStart,
        quantidadeProdutos: 15,
      ),
    );

    check(result.isError()).isTrue();
    check(result.exceptionOrNull()).isA<ValidationFailure>();
    verifyNever(() => agentQueriesRepository.executeSql(any()));
  });

  test('returns validation failure when quantidadeProdutos is zero', () async {
    final result = await repository.load(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: RankingProdutosFaturamentoFilter(
        dataVendaInicio: periodStart,
        dataVendaFim: periodEnd,
        quantidadeProdutos: 0,
      ),
    );

    check(result.isError()).isTrue();
    check(result.exceptionOrNull()).isA<ValidationFailure>();
    verifyNever(() => agentQueriesRepository.executeSql(any()));
  });

  test(
    'returns validation failure when quantidadeProdutos exceeds max',
    () async {
      final result = await repository.load(
        userId: 'user-1',
        agentId: 'agent-1',
        filter: RankingProdutosFaturamentoFilter(
          dataVendaInicio: periodStart,
          dataVendaFim: periodEnd,
          quantidadeProdutos:
              RankingProdutosFaturamentoFilter.maxQuantidadeProdutos + 1,
        ),
      );

      check(result.isError()).isTrue();
      check(result.exceptionOrNull()).isA<ValidationFailure>();
      verifyNever(() => agentQueriesRepository.executeSql(any()));
    },
  );

  test('returns empty load result when agent returns no rows', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(rows: <Map<String, dynamic>>[], rowCount: 0),
      ),
    );

    final result = await repository.load(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: filterTop3,
    );

    check(result.isSuccess()).isTrue();
    check(result.getOrThrow()).isA<RankingProdutosFaturamentoLoadResult>();
    check(result.getOrThrow().rows).isEmpty();
  });

  test(
    'execute sends SQL, dates, quantidadeProdutos, origem, skipTransportCache, maxRows',
    () async {
      when(
        () => agentQueriesRepository.executeSql(any()),
      ).thenAnswer(
        (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
          AgentSqlExecutionResult(rows: <Map<String, dynamic>>[], rowCount: 0),
        ),
      );

      await repository.load(
        userId: 'user-1',
        agentId: 'agent-1',
        filter: filterTop3,
      );

      final captured =
          verify(
                () => agentQueriesRepository.executeSql(captureAny()),
              ).captured.single
              as AgentSqlExecuteRequest;

      check(captured.sql).equals(
        RankingProdutosFaturamentoSql.buildQuery(
          restrictToSingleBranch: false,
          origem: 'FrenteLoja',
          preVenda: 'N',
        ),
      );
      check(captured.namedParams['dataVendaInicio']).equals('2026-03-10');
      check(captured.namedParams['dataVendaFim']).equals('2026-04-08');
      check(captured.namedParams['quantidadeProdutos']).equals(3);
      check(captured.namedParams['origem']).equals('FrenteLoja');
      check(captured.namedParams['preVenda']).equals('N');
      check(captured.skipTransportCache).isTrue();
      check(captured.executeOptions?.maxRows).equals(
        RankingProdutosFaturamentoRepositoryImpl.maxRowsForFilter(filterTop3),
      );
      check(captured.executeOptions?.maxRows).equals(400);
      check(captured.useRelay).isTrue();
      check(captured.sql).contains('r.Posicao > :quantidadeProdutos');
    },
  );

  test('sends codEmpresa and codFilial when filter restricts branch', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(rows: <Map<String, dynamic>>[], rowCount: 0),
      ),
    );

    await repository.load(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: RankingProdutosFaturamentoFilter(
        dataVendaInicio: periodStart,
        dataVendaFim: periodEnd,
        quantidadeProdutos: 10,
        codEmpresa: 2,
        codFilial: 3,
      ),
    );

    final captured =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.single
            as AgentSqlExecuteRequest;

    check(captured.namedParams['codEmpresa']).equals(2);
    check(captured.namedParams['codFilial']).equals(3);
    check(captured.namedParams.containsKey('origem')).isFalse();
    check(captured.namedParams.length).equals(5);
    check(captured.sql).contains(':codEmpresa');
  });

  test('maxRowsForFilter caps at bounded constant for large N', () {
    final largeFilter = RankingProdutosFaturamentoFilter(
      dataVendaInicio: periodStart,
      dataVendaFim: periodEnd,
      quantidadeProdutos: 100,
    );

    check(
      RankingProdutosFaturamentoRepositoryImpl.maxRowsForFilter(largeFilter),
    ).equals(AgentQueriesBoundedResultMaxRows.rankingProdutosFaturamento);
  });

  test('maps rows with posicao and per-branch percentual sum', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(
          rows: <Map<String, dynamic>>[
            <String, dynamic>{
              'CodEmpresa': 1,
              'CodFilial': 1,
              'CodProduto': 100,
              'NomeProduto': 'PROD A',
              'CodUnidadeMedida': 'UN',
              'CodGrupoProduto': 1,
              'NomeGrupoProduto': 'GRUPO',
              'ValorVenda': 1000.0,
              'Percentual': 10.0,
              'Posicao': 1,
            },
            <String, dynamic>{
              'CodEmpresa': 1,
              'CodFilial': 1,
              'CodProduto': 200,
              'NomeProduto': 'PROD B',
              'CodUnidadeMedida': 'UN',
              'CodGrupoProduto': 1,
              'NomeGrupoProduto': 'GRUPO',
              'ValorVenda': 2000.0,
              'Percentual': 20.0,
              'Posicao': 2,
            },
            <String, dynamic>{
              'CodEmpresa': 1,
              'CodFilial': 1,
              'CodProduto': 0,
              'NomeProduto': 'DIVERSOS',
              'CodUnidadeMedida': null,
              'CodGrupoProduto': null,
              'NomeGrupoProduto': null,
              'ValorVenda': 7000.0,
              'Percentual': 70.0,
              'Posicao': null,
            },
            <String, dynamic>{
              'CodEmpresa': 2,
              'CodFilial': 1,
              'CodProduto': 300,
              'NomeProduto': 'PROD C',
              'CodUnidadeMedida': 'UN',
              'CodGrupoProduto': 1,
              'NomeGrupoProduto': 'GRUPO',
              'ValorVenda': 500.0,
              'Percentual': 50.0,
              'Posicao': 1,
            },
            <String, dynamic>{
              'CodEmpresa': 2,
              'CodFilial': 1,
              'CodProduto': 0,
              'NomeProduto': 'DIVERSOS',
              'CodUnidadeMedida': null,
              'CodGrupoProduto': null,
              'NomeGrupoProduto': null,
              'ValorVenda': 500.0,
              'Percentual': 50.0,
              'Posicao': null,
            },
          ],
          rowCount: 5,
        ),
      ),
    );

    final result = await repository.load(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: filterTop3,
    );

    check(result.isSuccess()).isTrue();
    final loadResult = result.getOrThrow();
    check(loadResult.rows.length).equals(5);

    final branch1 = loadResult.rows
        .where((row) => row.codEmpresa == 1 && row.codFilial == 1)
        .toList();
    final branch1PercentSum = branch1.fold<double>(
      0,
      (sum, row) => sum + row.percentual,
    );
    check(branch1PercentSum).isGreaterThan(99.5);
    check(branch1PercentSum).isLessThan(100.5);

    final rankedBranch1 = branch1.where((row) => !row.isDiversos).toList();
    check(rankedBranch1.every((row) => row.posicao != null)).isTrue();
    check(rankedBranch1[0].posicao).equals(1);
    check(rankedBranch1[1].posicao).equals(2);

    final diversos = loadResult.diversosRows;
    check(diversos.length).equals(2);
    check(diversos.every((row) => row.codEmpresa != 9999)).isTrue();
    check(diversos.every((row) => row.codFilial != 9999)).isTrue();
    check(diversos.every((row) => row.posicao == null)).isTrue();
  });

  test('omits DIVERSOS row when valorVenda is zero', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(
          rows: <Map<String, dynamic>>[
            <String, dynamic>{
              'CodEmpresa': 1,
              'CodFilial': 1,
              'CodProduto': 100,
              'NomeProduto': 'PROD A',
              'CodUnidadeMedida': 'UN',
              'CodGrupoProduto': 1,
              'NomeGrupoProduto': 'GRUPO',
              'ValorVenda': 100.0,
              'Percentual': 100.0,
              'Posicao': 1,
            },
            <String, dynamic>{
              'CodEmpresa': 1,
              'CodFilial': 1,
              'CodProduto': 0,
              'NomeProduto': 'DIVERSOS',
              'CodUnidadeMedida': null,
              'CodGrupoProduto': null,
              'NomeGrupoProduto': null,
              'ValorVenda': 0.0,
              'Percentual': 0.0,
              'Posicao': null,
            },
          ],
          rowCount: 2,
        ),
      ),
    );

    final result = await repository.load(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: filterTop3,
    );

    check(result.isSuccess()).isTrue();
    check(result.getOrThrow().rows.length).equals(1);
    check(result.getOrThrow().diversosRows).isEmpty();
  });
}
