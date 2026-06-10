import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/data/queries/produto_vendido_tendencia_de_venda_sql.dart';
import 'package:colmeia/features/agent_queries/data/queries/produto_vendido_tendencia_de_venda_summary_sql.dart';
import 'package:colmeia/features/agent_queries/data/repositories/produto_vendido_tendencia_de_venda_repository_impl.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
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
    registerFallbackValue(
      const AgentSqlExecuteBatchRequest(
        agentId: 'fallback-agent',
        commands: <AgentSqlExecuteBatchCommand>[
          AgentSqlExecuteBatchCommand(sql: 'SELECT 1'),
        ],
      ),
    );
  });

  setUp(() {
    agentQueriesRepository = _MockAgentQueriesRepository();
    repository = ProdutoVendidoTendenciaDeVendaRepositoryImpl(
      agentQueriesRepository,
    );
  });

  ProdutoVendidoTendenciaDeVendaFilter buildValidFilter() {
    return ProdutoVendidoTendenciaDeVendaFilter(
      periodoAtualInicio: atualInicio,
      periodoAtualFim: atualFim,
      periodoAnteriorInicio: anteriorInicio,
      periodoAnteriorFim: anteriorFim,
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
            ).captured.single
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
    check(captured.useRelay).isTrue();
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
            ).captured.single
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
            ).captured.single
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
            ).captured.single
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

  test('loadPageAndSummary maps totalCount from paged batch item', () async {
    when(
      () => agentQueriesRepository.executeSqlBatch(any()),
    ).thenAnswer(
      (_) async => const Success<AgentSqlBatchExecutionResult, AppFailure>(
        AgentSqlBatchExecutionResult(
          items: <AgentSqlBatchExecutionItem>[
            AgentSqlBatchExecutionItem(
              index: 0,
              ok: true,
              rows: <Map<String, dynamic>>[
                <String, dynamic>{
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
              ],
              rowCount: 1,
            ),
            AgentSqlBatchExecutionItem(
              index: 1,
              ok: true,
              rows: <Map<String, dynamic>>[],
              rowCount: 0,
            ),
            AgentSqlBatchExecutionItem(
              index: 2,
              ok: true,
              rows: <Map<String, dynamic>>[],
              rowCount: 0,
            ),
            AgentSqlBatchExecutionItem(
              index: 3,
              ok: true,
              rows: <Map<String, dynamic>>[],
              rowCount: 0,
            ),
          ],
          totalCommands: 4,
          successfulCommands: 4,
          failedCommands: 0,
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
            ).captured.single
            as AgentSqlExecuteRequest;

    check(
      captured.sql,
    ).equals(ProdutoVendidoTendenciaDeVendaSummarySql.query());
    check(captured.namedParams['periodoAtualInicio']).equals('2026-03-01');
    check(captured.namedParams['origem']).equals('FrenteLoja');
    check(captured.executeOptions?.maxRows).equals(32);
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
    'loadPageAndSummary uses single executeSqlBatch with page, summary, top gainers, top losers',
    () async {
      when(
        () => agentQueriesRepository.executeSqlBatch(any()),
      ).thenAnswer(
        (_) async => const Success<AgentSqlBatchExecutionResult, AppFailure>(
          AgentSqlBatchExecutionResult(
            items: <AgentSqlBatchExecutionItem>[
              AgentSqlBatchExecutionItem(
                index: 0,
                ok: true,
                rows: <Map<String, dynamic>>[],
                rowCount: 0,
              ),
              AgentSqlBatchExecutionItem(
                index: 1,
                ok: true,
                rows: <Map<String, dynamic>>[],
                rowCount: 0,
              ),
              AgentSqlBatchExecutionItem(
                index: 2,
                ok: true,
                rows: <Map<String, dynamic>>[],
                rowCount: 0,
              ),
              AgentSqlBatchExecutionItem(
                index: 3,
                ok: true,
                rows: <Map<String, dynamic>>[],
                rowCount: 0,
              ),
            ],
            totalCommands: 4,
            successfulCommands: 4,
            failedCommands: 0,
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
      check(result.getOrThrow().summaryRows).isEmpty();
      check(result.getOrThrow().topGainers).isEmpty();
      check(result.getOrThrow().topLosers).isEmpty();

      verifyNever(() => agentQueriesRepository.executeSql(any()));
      final captured =
          verify(
                () => agentQueriesRepository.executeSqlBatch(captureAny()),
              ).captured.single
              as AgentSqlExecuteBatchRequest;
      check(captured.commands).length.equals(4);
      check(captured.commands[0].sql).equals(
        ProdutoVendidoTendenciaDeVendaSql.pagedQuery(startRow: 1, endRow: 20),
      );
      check(captured.commands[1].sql).equals(
        ProdutoVendidoTendenciaDeVendaSummarySql.query(),
      );
      check(captured.commands[2].sql).equals(
        ProdutoVendidoTendenciaDeVendaSql.topGainersQuery(),
      );
      check(captured.commands[3].sql).equals(
        ProdutoVendidoTendenciaDeVendaSql.topLosersQuery(),
      );
      check(captured.useRelay).isTrue();
    },
  );

  test(
    'loadPageAndSummary returns failure when page batch item is missing',
    () async {
      when(
        () => agentQueriesRepository.executeSqlBatch(any()),
      ).thenAnswer(
        (_) async => const Success<AgentSqlBatchExecutionResult, AppFailure>(
          AgentSqlBatchExecutionResult(
            items: <AgentSqlBatchExecutionItem>[
              AgentSqlBatchExecutionItem(
                index: 1,
                ok: true,
                rows: <Map<String, dynamic>>[],
                rowCount: 0,
              ),
            ],
            totalCommands: 4,
            successfulCommands: 1,
            failedCommands: 0,
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
      final failure = result.exceptionOrNull();
      check(failure).isA<RpcFailure>();
      check((failure! as RpcFailure).reason).equals('missing_batch_item');
    },
  );

  test(
    'loadPageAndSummary returns failure when summary item ok is false',
    () async {
      when(
        () => agentQueriesRepository.executeSqlBatch(any()),
      ).thenAnswer(
        (_) async => const Success<AgentSqlBatchExecutionResult, AppFailure>(
          AgentSqlBatchExecutionResult(
            items: <AgentSqlBatchExecutionItem>[
              AgentSqlBatchExecutionItem(
                index: 0,
                ok: true,
                rows: <Map<String, dynamic>>[],
                rowCount: 0,
              ),
              AgentSqlBatchExecutionItem(
                index: 1,
                ok: false,
                error: 'summary failed',
                rows: <Map<String, dynamic>>[],
                rowCount: 0,
              ),
            ],
            totalCommands: 4,
            successfulCommands: 1,
            failedCommands: 1,
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
      final failure = result.exceptionOrNull();
      check(failure).isA<RpcFailure>();
      check((failure! as RpcFailure).reason).equals('batch_item_failed');
      check(failure.message).contains('summary failed');
    },
  );

  test(
    'loadPageAndSummary returns failure when top gainers item ok is false',
    () async {
      when(
        () => agentQueriesRepository.executeSqlBatch(any()),
      ).thenAnswer(
        (_) async => const Success<AgentSqlBatchExecutionResult, AppFailure>(
          AgentSqlBatchExecutionResult(
            items: <AgentSqlBatchExecutionItem>[
              AgentSqlBatchExecutionItem(
                index: 0,
                ok: true,
                rows: <Map<String, dynamic>>[],
                rowCount: 0,
              ),
              AgentSqlBatchExecutionItem(
                index: 1,
                ok: true,
                rows: <Map<String, dynamic>>[],
                rowCount: 0,
              ),
              AgentSqlBatchExecutionItem(
                index: 2,
                ok: false,
                error: 'top gainers failed',
                rows: <Map<String, dynamic>>[],
                rowCount: 0,
              ),
            ],
            totalCommands: 4,
            successfulCommands: 2,
            failedCommands: 1,
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
      final failure = result.exceptionOrNull();
      check(failure).isA<RpcFailure>();
      check((failure! as RpcFailure).reason).equals('batch_item_failed');
      check(failure.message).contains('top gainers failed');
    },
  );

  test(
    'loadPageAndSummary returns UnknownFailure when page rows are malformed',
    () async {
      when(
        () => agentQueriesRepository.executeSqlBatch(any()),
      ).thenAnswer(
        (_) async => const Success<AgentSqlBatchExecutionResult, AppFailure>(
          AgentSqlBatchExecutionResult(
            items: <AgentSqlBatchExecutionItem>[
              AgentSqlBatchExecutionItem(
                index: 0,
                ok: true,
                rows: <Map<String, dynamic>>[
                  <String, dynamic>{
                    'TotalCount': 1,
                    'CodProduto': 1,
                  },
                ],
                rowCount: 1,
              ),
              AgentSqlBatchExecutionItem(
                index: 1,
                ok: true,
                rows: <Map<String, dynamic>>[],
                rowCount: 0,
              ),
              AgentSqlBatchExecutionItem(
                index: 2,
                ok: true,
                rows: <Map<String, dynamic>>[],
                rowCount: 0,
              ),
              AgentSqlBatchExecutionItem(
                index: 3,
                ok: true,
                rows: <Map<String, dynamic>>[],
                rowCount: 0,
              ),
            ],
            totalCommands: 4,
            successfulCommands: 4,
            failedCommands: 0,
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
