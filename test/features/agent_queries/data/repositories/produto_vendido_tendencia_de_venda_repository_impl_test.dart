import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/data/queries/produto_vendido_tendencia_de_venda_screen_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/produto_vendido_tendencia_de_venda_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/produto_vendido_tendencia_de_venda_summary_sql.dart';
import 'package:colmeia/features/agent_queries/data/repositories/produto_vendido_tendencia_de_venda_repository_impl.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/produto_vendido_tendencia_de_venda_filter.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockAgentQueriesRepository extends Mock
    implements AgentQueriesRepository {}

void main() {
  late _MockAgentQueriesRepository agentQueriesRepository;
  late ProdutoVendidoTendenciaDeVendaRepositoryImpl repository;

  final atualInicio = DateTime(2026, 3);
  final atualFim = DateTime(2026, 3, 31);
  final anteriorInicio = DateTime(2026, 2);
  final anteriorFim = DateTime(2026, 2, 28);

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
    repository = ProdutoVendidoTendenciaDeVendaRepositoryImpl(
      agentQueriesRepository,
    );
  });

  ProdutoVendidoTendenciaDeVendaFilter buildValidFilter({
    String? classificacao,
    String? searchTerm,
    int? codGrupoProduto,
    int page = 1,
    int pageSize = 20,
  }) {
    return ProdutoVendidoTendenciaDeVendaFilter(
      periodoAtualInicio: atualInicio,
      periodoAtualFim: atualFim,
      periodoAnteriorInicio: anteriorInicio,
      periodoAnteriorFim: anteriorFim,
      classificacao: classificacao,
      searchTerm: searchTerm,
      codGrupoProduto: codGrupoProduto,
      page: page,
      pageSize: pageSize,
    );
  }


  test('returns validation failure when current period is invalid', () async {
    final result = await repository.loadAll(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: ProdutoVendidoTendenciaDeVendaFilter(
        periodoAtualInicio: atualFim,
        periodoAtualFim: atualInicio,
        periodoAnteriorInicio: anteriorInicio,
        periodoAnteriorFim: anteriorFim,
      ),
    );

    check(result.isError()).isTrue();
    check(result.exceptionOrNull()).isA<ValidationFailure>();
    verifyNever(() => agentQueriesRepository.executeSql(any()));
  });

  test('returns validation failure when periods overlap', () async {
    final result = await repository.loadAll(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: ProdutoVendidoTendenciaDeVendaFilter(
        periodoAtualInicio: DateTime(2026, 3),
        periodoAtualFim: DateTime(2026, 3, 31),
        periodoAnteriorInicio: DateTime(2026, 3, 15),
        periodoAnteriorFim: DateTime(2026, 4, 15),
      ),
    );

    check(result.isError()).isTrue();
    check(result.exceptionOrNull()).isA<ValidationFailure>();
    verifyNever(() => agentQueriesRepository.executeSql(any()));
  });

  test(
    'returns validation failure when comparison windows are inconsistent',
    () async {
      final result = await repository.loadAll(
        userId: 'user-1',
        agentId: 'agent-1',
        filter: ProdutoVendidoTendenciaDeVendaFilter(
          periodoAtualInicio: DateTime(2026, 4),
          periodoAtualFim: DateTime(2026, 4, 30),
          periodoAnteriorInicio: DateTime(2026, 2),
          periodoAnteriorFim: DateTime(2026, 3, 31),
        ),
      );

      check(result.isError()).isTrue();
      check(result.exceptionOrNull()).isA<ValidationFailure>();
      verifyNever(() => agentQueriesRepository.executeSql(any()));
    },
  );

  test('returns validation failure when origem is empty', () async {
    final result = await repository.loadAll(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: ProdutoVendidoTendenciaDeVendaFilter(
        periodoAtualInicio: atualInicio,
        periodoAtualFim: atualFim,
        periodoAnteriorInicio: anteriorInicio,
        periodoAnteriorFim: anteriorFim,
        origem: '   ',
      ),
    );

    check(result.isError()).isTrue();
    check(result.exceptionOrNull()).isA<ValidationFailure>();
    verifyNever(() => agentQueriesRepository.executeSql(any()));
  });

  test('returns validation failure when classificacao is invalid', () async {
    final result = await repository.loadAll(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: ProdutoVendidoTendenciaDeVendaFilter(
        periodoAtualInicio: atualInicio,
        periodoAtualFim: atualFim,
        periodoAnteriorInicio: anteriorInicio,
        periodoAnteriorFim: anteriorFim,
        classificacao: 'INVALIDA',
      ),
    );

    check(result.isError()).isTrue();
    check(result.exceptionOrNull()).isA<ValidationFailure>();
    verifyNever(() => agentQueriesRepository.executeSql(any()));
  });

  test('returns empty list when agent returns no rows', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(rows: <Map<String, dynamic>>[], rowCount: 0),
      ),
    );

    final result = await repository.loadAll(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: buildValidFilter(),
    );

    check(result.isSuccess()).isTrue();
    check(result.getOrThrow()).isEmpty();
    // Empty unary success triggers one retry.
    verify(() => agentQueriesRepository.executeSql(any())).called(2);
  });

  test('retries once when first page response is empty', () async {
    var calls = 0;
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer((_) async {
      calls++;
      if (calls == 1) {
        return const Success<AgentSqlExecutionResult, AppFailure>(
          AgentSqlExecutionResult(rows: <Map<String, dynamic>>[], rowCount: 0),
        );
      }
      return const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(
          rows: <Map<String, dynamic>>[
            <String, dynamic>{
              'TotalCount': 1,
              'CodEmpresa': 1,
              'CodFilial': 1,
              'CodProduto': 100,
              'NomeProduto': 'Produto A',
              'CodUnidadeMedida': 'UN',
              'CodGrupoProduto': 10,
              'NomeGrupoProduto': 'Grupo',
              'CodMarca': 20,
              'NomeMarca': 'Marca',
              'QtdAnterior': 5,
              'QtdAtual': 12,
              'Diferenca': 7,
              'PercentualTendencia': 140,
              'Classificacao': 'CRESCENDO',
            },
          ],
          rowCount: 1,
        ),
      );
    });

    final result = await repository.loadAll(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: buildValidFilter(),
    );

    check(result.isSuccess()).isTrue();
    check(result.getOrThrow().single.codProduto).equals(100);
    verify(() => agentQueriesRepository.executeSql(any())).called(2);
  });

  test('execute sends correct SQL, period params, and options', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(rows: <Map<String, dynamic>>[], rowCount: 0),
      ),
    );

    await repository.loadAll(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: buildValidFilter(),
    );

    final captured =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.first
            as AgentSqlExecuteRequest;

    check(captured.sql).equals(
      ProdutoVendidoTendenciaDeVendaSql.pagedQuery(startRow: 1, endRow: 20),
    );
    check(captured.namedParams['periodoAtualInicio']).equals('2026-03-01');
    check(captured.namedParams['periodoAtualFim']).equals('2026-03-31');
    check(captured.namedParams['periodoAnteriorInicio']).equals('2026-02-01');
    check(captured.namedParams['periodoAnteriorFim']).equals('2026-02-28');
    check(captured.namedParams['origem']).equals('FrenteLoja');
    check(captured.namedParams.containsKey('startRow')).isFalse();
    check(captured.namedParams.containsKey('endRow')).isFalse();
    check(captured.executeOptions?.maxRows).equals(
      45,
    );
    check(captured.executeOptions?.sqlTimeoutMs).equals(162000);
    check(captured.executeOptions?.executionMode).equals(
      AgentSqlExecutionMode.preserve,
    );
    check(captured.executeOptions?.preferDbStreaming).equals(false);
    check(captured.useRelay).isTrue();
    check(captured.relayMode).equals(AgentSqlRelayMode.unary);
    check(captured.skipTransportCache).isFalse();
  });

  test('custom bridgeTimeoutMs adjusts sql timeout', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(rows: <Map<String, dynamic>>[], rowCount: 0),
      ),
    );

    await repository.loadAll(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: buildValidFilter(),
      bridgeTimeoutMs: 60000,
    );

    final captured =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.first
            as AgentSqlExecuteRequest;

    check(captured.bridgeTimeoutMs).equals(60000);
    check(captured.executeOptions?.sqlTimeoutMs).equals(54000);
  });

  test('custom page and pageSize set startRow and endRow', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(rows: <Map<String, dynamic>>[], rowCount: 0),
      ),
    );

    await repository.loadAll(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: ProdutoVendidoTendenciaDeVendaFilter(
        periodoAtualInicio: atualInicio,
        periodoAtualFim: atualFim,
        periodoAnteriorInicio: anteriorInicio,
        periodoAnteriorFim: anteriorFim,
        page: 3,
      ),
    );

    final captured =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.first
            as AgentSqlExecuteRequest;

    check(captured.sql).equals(
      ProdutoVendidoTendenciaDeVendaSql.pagedQuery(startRow: 41, endRow: 60),
    );
    check(captured.namedParams.containsKey('startRow')).isFalse();
    check(captured.namedParams.containsKey('endRow')).isFalse();
    check(captured.executeOptions?.maxRows).equals(45);
  });

  test('optional detail filters are inlined into paged SQL', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(rows: <Map<String, dynamic>>[], rowCount: 0),
      ),
    );

    await repository.loadAll(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: ProdutoVendidoTendenciaDeVendaFilter(
        periodoAtualInicio: atualInicio,
        periodoAtualFim: atualFim,
        periodoAnteriorInicio: anteriorInicio,
        periodoAnteriorFim: anteriorFim,
        searchTerm: "fox' prime",
        classificacao: 'crescendo',
        codGrupoProduto: 14,
        codMarca: 490,
      ),
    );

    final captured =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.first
            as AgentSqlExecuteRequest;

    check(captured.sql).contains('AND p.CodGrupoProduto = 14');
    check(captured.sql).contains('AND p.CodMarca = 490');
    check(captured.sql).contains("N'%fox'' prime%'");
    check(captured.sql).contains("WHERE Classificacao = N'CRESCENDO'");
    check(captured.namedParams.length).equals(5);
  });

  test('maps paged rows with totalCount and filters count-only rows', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(
          rows: <Map<String, dynamic>>[
            <String, dynamic>{
              'TotalCount': 42,
            },
          ],
          rowCount: 1,
        ),
      ),
    );

    final result = await repository.loadAll(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: buildValidFilter(),
    );

    check(result.isSuccess()).isTrue();
    check(result.getOrThrow()).isEmpty();
  });

  test('maps rows to entities correctly with decimal trend values', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(
          rows: <Map<String, dynamic>>[
            <String, dynamic>{
              'TotalCount': 1,
              'CodEmpresa': 1,
              'CodFilial': 1,
              'CodProduto': 4051,
              'NomeProduto': 'BOMBA DE AR',
              'CodUnidadeMedida': 'PT',
              'CodGrupoProduto': 14,
              'NomeGrupoProduto': 'SUSPENSAO',
              'CodMarca': 490,
              'NomeMarca': 'SMART FOX',
              'QtdAnterior': '1.0000000',
              'QtdAtual': '20.0000000',
              'Diferenca': '19.0000000',
              'PercentualTendencia': '1900.0000000',
              'Classificacao': 'CRESCENDO',
            },
          ],
          rowCount: 1,
        ),
      ),
    );

    final result = await repository.loadAll(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: buildValidFilter(),
    );

    check(result.isSuccess()).isTrue();
    final rows = result.getOrThrow();
    check(rows.length).equals(1);
    final row = rows.single;
    check(row.codEmpresa).equals(1);
    check(row.codFilial).equals(1);
    check(row.codProduto).equals(4051);
    check(row.qtdAnterior).equals(1);
    check(row.qtdAtual).equals(20);
    check(row.diferenca).equals(19);
    check(row.percentualTendencia).equals(1900);
    check(row.classificacao).equals('CRESCENDO');
  });

  test('loadPageAndSummary maps totalCount and partitions RowKind rows', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(
          rows: <Map<String, dynamic>>[
            <String, dynamic>{
              'RowKind': 'SUMMARY',
              'Classificacao': 'CRESCENDO',
              'QuantidadeProdutos': 8,
              'ImpactoLiquido': '53.0',
            },
            <String, dynamic>{
              'RowKind': 'PAGE',
              'TotalCount': 57,
              'CodEmpresa': 1,
              'CodFilial': 1,
              'CodProduto': 4051,
              'NomeProduto': 'BOMBA DE AR',
              'CodUnidadeMedida': 'PT',
              'QtdAnterior': '1.0000000',
              'QtdAtual': '20.0000000',
              'Diferenca': '19.0000000',
              'PercentualTendencia': '1900.0000000',
              'Classificacao': 'CRESCENDO',
            },
            <String, dynamic>{
              'RowKind': 'GAINER',
              'CodEmpresa': 1,
              'CodFilial': 1,
              'CodProduto': 4051,
              'NomeProduto': 'BOMBA DE AR',
              'CodUnidadeMedida': 'PT',
              'QtdAnterior': '1.0000000',
              'QtdAtual': '20.0000000',
              'Diferenca': '19.0000000',
              'PercentualTendencia': '1900.0000000',
              'Classificacao': 'CRESCENDO',
            },
            <String, dynamic>{
              'RowKind': 'LOSER',
              'CodEmpresa': 1,
              'CodFilial': 1,
              'CodProduto': 9001,
              'NomeProduto': 'ITEM CAINDO',
              'CodUnidadeMedida': 'UN',
              'QtdAnterior': '10.0000000',
              'QtdAtual': '1.0000000',
              'Diferenca': '-9.0000000',
              'PercentualTendencia': '-90.0000000',
              'Classificacao': 'CAINDO',
            },
          ],
          rowCount: 4,
        ),
      ),
    );

    final filter = buildValidFilter();
    final result = await repository.loadPageAndSummary(
      userId: 'user-1',
      agentId: 'agent-1',
      pageFilter: filter,
      summaryFilter: filter,
    );

    check(result.isSuccess()).isTrue();
    final data = result.getOrThrow();
    check(data.totalCount).equals(57);
    check(data.rows.length).equals(1);
    check(data.rows.single.codProduto).equals(4051);
    check(data.summaryRows.single.quantidadeProdutos).equals(8);
    check(data.topGainers.single.codProduto).equals(4051);
    check(data.topLosers.single.codProduto).equals(9001);
  });

  test('loadSummary sends summary SQL and bounded maxRows', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(rows: <Map<String, dynamic>>[], rowCount: 0),
      ),
    );

    await repository.loadSummary(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: buildValidFilter(),
    );

    final captured =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.first
            as AgentSqlExecuteRequest;

    check(
      captured.sql,
    ).equals(ProdutoVendidoTendenciaDeVendaSummarySql.query());
    check(captured.namedParams['periodoAtualInicio']).equals('2026-03-01');
    check(captured.namedParams['origem']).equals('FrenteLoja');
    check(captured.executeOptions?.maxRows).equals(32);
    check(captured.executeOptions?.preferDbStreaming).equals(false);
    check(captured.relayMode).equals(AgentSqlRelayMode.unary);
    check(captured.skipTransportCache).isFalse();
  });

  test('retries once when first summary response is empty', () async {
    var calls = 0;
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer((_) async {
      calls++;
      if (calls == 1) {
        return const Success<AgentSqlExecutionResult, AppFailure>(
          AgentSqlExecutionResult(rows: <Map<String, dynamic>>[], rowCount: 0),
        );
      }
      return const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(
          rows: <Map<String, dynamic>>[
            <String, dynamic>{
              'Classificacao': 'NOVO',
              'QuantidadeProdutos': 84,
              'ImpactoLiquido': '2522.806',
            },
          ],
          rowCount: 1,
        ),
      );
    });

    final result = await repository.loadSummary(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: buildValidFilter(),
    );

    check(result.isSuccess()).isTrue();
    check(result.getOrThrow().single.quantidadeProdutos).equals(84);
    verify(() => agentQueriesRepository.executeSql(any())).called(2);
  });

  test('loadSummary maps aggregated rows', () async {
    when(
      () => agentQueriesRepository.executeSql(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(
          rows: <Map<String, dynamic>>[
            <String, dynamic>{
              'Classificacao': 'CRESCENDO',
              'QuantidadeProdutos': 8,
              'ImpactoLiquido': '53.0',
            },
          ],
          rowCount: 1,
        ),
      ),
    );

    final result = await repository.loadSummary(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: buildValidFilter(),
    );

    check(result.isSuccess()).isTrue();
    final rows = result.getOrThrow();
    check(rows.length).equals(1);
    check(rows.single.classificacao).equals('CRESCENDO');
    check(rows.single.quantidadeProdutos).equals(8);
    check(rows.single.impactoLiquido).equals(53);
  });

  test(
    'loadPageAndSummary uses single executeSql with shared screen SQL',
    () async {
      when(
        () => agentQueriesRepository.executeSql(any()),
      ).thenAnswer(
        (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
          AgentSqlExecutionResult(
            rows: <Map<String, dynamic>>[
              <String, dynamic>{
                'RowKind': 'SUMMARY',
                'Classificacao': 'ESTAVEL',
                'QuantidadeProdutos': 1,
                'ImpactoLiquido': '0.0',
              },
              <String, dynamic>{
                'RowKind': 'PAGE',
                'TotalCount': 0,
              },
            ],
            rowCount: 2,
          ),
        ),
      );

      final filter = buildValidFilter();
      final result = await repository.loadPageAndSummary(
        userId: 'user-1',
        agentId: 'agent-1',
        pageFilter: filter,
        summaryFilter: filter,
      );

      check(result.isSuccess()).isTrue();
      check(result.getOrThrow().rows).isEmpty();
      check(result.getOrThrow().totalCount).equals(0);
      check(result.getOrThrow().summaryRows).length.equals(1);
      check(result.getOrThrow().topGainers).isEmpty();
      check(result.getOrThrow().topLosers).isEmpty();

      final captured =
          verify(
                () => agentQueriesRepository.executeSql(captureAny()),
              ).captured.single
              as AgentSqlExecuteRequest;
      check(captured.sql).equals(
        ProdutoVendidoTendenciaDeVendaScreenSql.query(
          startRow: 1,
          endRow: 20,
        ),
      );
      check(captured.namedParams['periodoAtualInicio']).equals('2026-03-01');
      check(captured.executeOptions?.preferDbStreaming).equals(false);
      check(captured.relayMode).equals(AgentSqlRelayMode.unary);
      check(captured.skipTransportCache).isFalse();
      check(captured.executeOptions?.maxRows).equals(107);
    },
  );

  test(
    'loadPageAndSummary rejects divergent page and summary universe filters',
    () async {
      final result = await repository.loadPageAndSummary(
        userId: 'user-1',
        agentId: 'agent-1',
        pageFilter: buildValidFilter(searchTerm: 'fox'),
        summaryFilter: buildValidFilter(searchTerm: 'other'),
      );

      check(result.isError()).isTrue();
      check(result.exceptionOrNull()).isA<ValidationFailure>();
      check(result.exceptionOrNull()!.message).equals(
        ProdutoVendidoTendenciaDeVendaRepositoryImpl.errorScreenUniverseMismatch,
      );
      verifyNever(() => agentQueriesRepository.executeSql(any()));
    },
  );

  test(
    'loadPageAndSummary allows divergent classificacao between page and summary',
    () async {
      when(
        () => agentQueriesRepository.executeSql(any()),
      ).thenAnswer(
        (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
          AgentSqlExecutionResult(
            rows: <Map<String, dynamic>>[
              <String, dynamic>{
                'RowKind': 'SUMMARY',
                'Classificacao': 'CAINDO',
                'QuantidadeProdutos': 2,
                'ImpactoLiquido': '-4.0',
              },
              <String, dynamic>{
                'RowKind': 'PAGE',
                'TotalCount': 0,
              },
            ],
            rowCount: 2,
          ),
        ),
      );

      final result = await repository.loadPageAndSummary(
        userId: 'user-1',
        agentId: 'agent-1',
        pageFilter: buildValidFilter(classificacao: 'CRESCENDO'),
        summaryFilter: buildValidFilter(classificacao: 'CAINDO'),
      );

      check(result.isSuccess()).isTrue();
      final captured =
          verify(
                () => agentQueriesRepository.executeSql(captureAny()),
              ).captured.single
              as AgentSqlExecuteRequest;
      check(captured.sql).equals(
        ProdutoVendidoTendenciaDeVendaScreenSql.query(
          startRow: 1,
          endRow: 20,
          pageClassificacao: 'CRESCENDO',
          summaryClassificacao: 'CAINDO',
        ),
      );
    },
  );

  test(
    'loadPageAndSummary returns UnknownFailure when page rows are malformed',
    () async {
      when(
        () => agentQueriesRepository.executeSql(any()),
      ).thenAnswer(
        (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
          AgentSqlExecutionResult(
            rows: <Map<String, dynamic>>[
              <String, dynamic>{
                'RowKind': 'PAGE',
                'TotalCount': 1,
                'CodProduto': 1,
              },
            ],
            rowCount: 1,
          ),
        ),
      );

      final filter = buildValidFilter();
      final result = await repository.loadPageAndSummary(
        userId: 'user-1',
        agentId: 'agent-1',
        pageFilter: filter,
        summaryFilter: filter,
      );

      check(result.isError()).isTrue();
      check(result.exceptionOrNull()).isA<UnknownFailure>();
    },
  );

  test(
    'loadPageAndSummary returns UnknownFailure for unexpected RowKind',
    () async {
      when(
        () => agentQueriesRepository.executeSql(any()),
      ).thenAnswer(
        (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
          AgentSqlExecutionResult(
            rows: <Map<String, dynamic>>[
              <String, dynamic>{
                'RowKind': 'OTHER',
                'TotalCount': 0,
              },
            ],
            rowCount: 1,
          ),
        ),
      );

      final filter = buildValidFilter();
      final result = await repository.loadPageAndSummary(
        userId: 'user-1',
        agentId: 'agent-1',
        pageFilter: filter,
        summaryFilter: filter,
      );

      check(result.isError()).isTrue();
      check(result.exceptionOrNull()).isA<UnknownFailure>();
    },
  );
}
