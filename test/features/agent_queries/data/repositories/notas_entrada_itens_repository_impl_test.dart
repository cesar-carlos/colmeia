import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_bounded_result_max_rows.dart';
import 'package:colmeia/features/agent_queries/data/queries/notas_entrada_itens_sql.dart';
import 'package:colmeia/features/agent_queries/data/repositories/notas_entrada_itens_repository_impl.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/notas_entrada_itens_filter.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockAgentQueriesRepository extends Mock
    implements AgentQueriesRepository {}

void main() {
  late _MockAgentQueriesRepository agentQueriesRepository;
  late NotasEntradaItensRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(
      const AgentSqlExecuteRequest(agentId: 'fallback-agent', sql: 'SELECT 1'),
    );
  });

  setUp(() {
    agentQueriesRepository = _MockAgentQueriesRepository();
    repository = NotasEntradaItensRepositoryImpl(agentQueriesRepository);
  });

  test(
    'returns validation failure without executing an invalid scope',
    () async {
      final result = await repository.load(
        userId: 'user-1',
        agentId: 'agent-1',
        filter: const NotasEntradaItensFilter(compraId: 0),
      );

      check(result.isError()).isTrue();
      check(result.exceptionOrNull()).isA<ValidationFailure>();
      verifyNever(() => agentQueriesRepository.executeSql(any()));
    },
  );

  test('sends only CompraId', () async {
    when(() => agentQueriesRepository.executeSql(any())).thenAnswer(
      (_) async => const Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(
          rows: <Map<String, dynamic>>[],
          rowCount: 0,
        ),
      ),
    );

    await repository.load(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: const NotasEntradaItensFilter(compraId: 80),
    );

    final captured =
        verify(
              () => agentQueriesRepository.executeSql(captureAny()),
            ).captured.single
            as AgentSqlExecuteRequest;
    check(captured.sql).equals(NotasEntradaItensSql.query);
    check(captured.namedParams['compraId']).equals(80);
    check(captured.namedParams.containsKey('codEmpresa')).isFalse();
    check(captured.namedParams.containsKey('codFilial')).isFalse();
    check(captured.executeOptions?.maxRows).equals(
      AgentQueriesBoundedResultMaxRows.notasEntradaItens,
    );
    check(captured.executeOptions?.executionMode).equals(
      AgentSqlExecutionMode.preserve,
    );
    check(captured.executeOptions?.preferDbStreaming).equals(false);
    check(captured.useRelay).isTrue();
    check(captured.relayMode).equals(AgentSqlRelayMode.unary);
    check(captured.skipTransportCache).isTrue();
  });

  test('maps line items and a cancelled flag', () async {
    when(() => agentQueriesRepository.executeSql(any())).thenAnswer(
      (_) async => Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(
          rows: <Map<String, dynamic>>[_itemRow()],
          rowCount: 1,
        ),
      ),
    );

    final result = await repository.load(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: const NotasEntradaItensFilter(compraId: 80),
    );

    check(result.isSuccess()).isTrue();
    final page = result.getOrThrow();
    check(page.items.length).equals(1);
    check(page.items.single.compraId).equals(80);
    check(page.items.single.codProduto).equals(15);
    check(page.items.single.nomeProduto).equals('Mel silvestre');
    check(page.items.single.quantidade).equals(2);
    check(page.items.single.valorTotal).equals(45.5);
    check(page.isCancelled).isFalse();
    check(page.isTruncated).isFalse();
    check(page.maxRows).equals(
      AgentQueriesBoundedResultMaxRows.notasEntradaItens,
    );
    check(page.totalValorItens).equals(45.5);
  });

  test('marks the result truncated when the row cap is reached', () async {
    const cap = AgentQueriesBoundedResultMaxRows.notasEntradaItens;
    when(() => agentQueriesRepository.executeSql(any())).thenAnswer(
      (_) async => Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(
          rows: List<Map<String, dynamic>>.generate(
            cap,
            (index) => _itemRow(codProduto: index + 1),
          ),
          rowCount: cap,
        ),
      ),
    );

    final result = await repository.load(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: const NotasEntradaItensFilter(compraId: 80),
    );

    final page = result.getOrThrow();
    check(page.items.length).equals(cap);
    check(page.isTruncated).isTrue();
    check(page.maxRows).equals(cap);
  });

  test('keeps a line when product and unit are missing', () async {
    when(() => agentQueriesRepository.executeSql(any())).thenAnswer(
      (_) async => Success<AgentSqlExecutionResult, AppFailure>(
        AgentSqlExecutionResult(
          rows: <Map<String, dynamic>>[
            _itemRow(
              nomeProduto: null,
              codUnidadeMedida: null,
              descricaoUnidadeMedida: null,
              codGrupoProduto: null,
              nomeGrupoProduto: null,
            ),
          ],
          rowCount: 1,
        ),
      ),
    );

    final result = await repository.load(
      userId: 'user-1',
      agentId: 'agent-1',
      filter: const NotasEntradaItensFilter(compraId: 80),
    );

    final row = result.getOrThrow().items.single;
    check(row.nomeProduto).equals('');
    check(row.codUnidadeMedida).isNull();
    check(row.descricaoUnidadeMedida).isNull();
    check(row.codGrupoProduto).isNull();
    check(row.nomeGrupoProduto).isNull();
  });
}

Map<String, dynamic> _itemRow({
  int codProduto = 15,
  Object? nomeProduto = 'Mel silvestre',
  Object? codUnidadeMedida = 'UN',
  Object? descricaoUnidadeMedida = 'UNIDADE',
  Object? codGrupoProduto = 3,
  Object? nomeGrupoProduto = 'Alimentos',
}) {
  return <String, dynamic>{
    'CodEmpresa': 1,
    'CodFilial': 1,
    'CompraId': 80,
    'CompraCancelada': 'N',
    'CodProduto': codProduto,
    'NomeProduto': nomeProduto,
    'CodUnidadeMedida': codUnidadeMedida,
    'DescricaoUnidadeMedida': descricaoUnidadeMedida,
    'CodGrupoProduto': codGrupoProduto,
    'NomeGrupoProduto': nomeGrupoProduto,
    'Quantidade': 2,
    'ValorUnitario': 22.75,
    'SubTotal': 45.5,
    'ValorDescontoItem': 0,
    'ValorTotalDesconto': 0,
    'ValorDescontoProporcional': 0,
    'ValorTotal': 45.5,
  };
}
