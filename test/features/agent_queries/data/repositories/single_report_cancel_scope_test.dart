import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcela_forma_pagamento_diario_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcela_forma_pagamento_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcela_forma_pagamento_repository_impl_v2.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcela_por_usuario_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcelas_anual_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcelas_dia_semana_usuario_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_parcelas_forma_pagamento_por_mes_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_total_vendas_municipio_filial_diario_repository_impl.dart';
import 'package:colmeia/features/agent_queries/data/repositories/resumo_vendas_diarias_por_vendedor_repository_impl.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_batch_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execution_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_anual_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_forma_pagamento_por_mes_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_periodo_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_produto_vendido_sql_periodo_filter.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/agent_queries_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:result_dart/result_dart.dart';

void main() {
  final date = DateTime(2026);
  final loaders =
      <
        String,
        Future<Object> Function(AgentQueriesRepository, AgentQueriesCancelScope)
      >{
        'resumo_parcelas_anual': (repository, scope) =>
            ResumoParcelasAnualRepositoryImpl(repository).load(
              userId: 'user-1',
              agentId: 'agent-1',
              clientToken: 'test-token',
              filter: ResumoParcelasAnualFilter(
                dataVendaInicio: date,
                dataVendaFim: date,
              ),
              cancelScope: scope,
            ),
        'resumo_parcelas_dia_semana_usuario': (repository, scope) =>
            ResumoParcelasDiaSemanaUsuarioRepositoryImpl(repository).load(
              userId: 'user-1',
              agentId: 'agent-1',
              clientToken: 'test-token',
              filter: ResumoParcelasDiaSemanaFilter(
                dataVendaInicio: date,
                dataVendaFim: date,
              ),
              cancelScope: scope,
            ),
        'resumo_parcelas_forma_pagamento_por_mes': (repository, scope) =>
            ResumoParcelasFormaPagamentoPorMesRepositoryImpl(repository).load(
              userId: 'user-1',
              agentId: 'agent-1',
              clientToken: 'test-token',
              filter: ResumoParcelasFormaPagamentoPorMesFilter(
                dataVendaInicio: date,
                dataVendaFim: date,
              ),
              cancelScope: scope,
            ),
        'resumo_parcela_forma_pagamento': (repository, scope) =>
            ResumoParcelaFormaPagamentoRepositoryImpl(repository).load(
              userId: 'user-1',
              agentId: 'agent-1',
              clientToken: 'test-token',
              filter: ResumoParcelasPeriodoFilter(
                dataVendaInicio: date,
                dataVendaFim: date,
              ),
              cancelScope: scope,
            ),
        'resumo_parcela_forma_pagamento_v2': (repository, scope) =>
            ResumoParcelaFormaPagamentoRepositoryImplV2(repository).load(
              userId: 'user-1',
              agentId: 'agent-1',
              clientToken: 'test-token',
              filter: ResumoParcelasPeriodoFilter(
                dataVendaInicio: date,
                dataVendaFim: date,
              ),
              cancelScope: scope,
            ),
        'resumo_parcela_forma_pagamento_diario': (repository, scope) =>
            ResumoParcelaFormaPagamentoDiarioRepositoryImpl(repository).load(
              userId: 'user-1',
              agentId: 'agent-1',
              clientToken: 'test-token',
              filter: ResumoParcelasPeriodoFilter(
                dataVendaInicio: date,
                dataVendaFim: date,
              ),
              cancelScope: scope,
            ),
        'resumo_parcela_por_usuario': (repository, scope) =>
            ResumoParcelaPorUsuarioRepositoryImpl(repository).load(
              userId: 'user-1',
              agentId: 'agent-1',
              clientToken: 'test-token',
              filter: ResumoParcelasPeriodoFilter(
                dataVendaInicio: date,
                dataVendaFim: date,
              ),
              cancelScope: scope,
            ),
        'resumo_total_vendas_municipio_filial_diario': (repository, scope) =>
            ResumoTotalVendasMunicipioFilialDiarioRepositoryImpl(repository)
                .load(
                  userId: 'user-1',
                  agentId: 'agent-1',
                  clientToken: 'test-token',
                  filter: ResumoVendasProdutoVendidoSqlPeriodoFilter(
                    dataVendaInicio: date,
                    dataVendaFim: date,
                  ),
                  cancelScope: scope,
                ),
        'resumo_vendas_diarias_por_vendedor': (repository, scope) =>
            ResumoVendasDiariasPorVendedorRepositoryImpl(repository).load(
              userId: 'user-1',
              agentId: 'agent-1',
              clientToken: 'test-token',
              filter: ResumoVendasDiariasPorVendedorFilter(
                dataVendaInicio: date,
                dataVendaFim: date,
              ),
              cancelScope: scope,
            ),
      };
  for (final entry in loaders.entries) {
    test(
      '${entry.key} forwards caller cancellation to SQL execution',
      () async {
        final repository = _CancellationRecordingRepository();
        final scope = AgentQueriesCancelScope()..cancelAll();
        await entry.value(repository, scope);
        expect(repository.seenScope, same(scope));
        expect(repository.seenScope!.isCancelled, true);
      },
    );
  }
}

class _CancellationRecordingRepository implements AgentQueriesRepository {
  AgentQueriesCancelScope? seenScope;
  @override
  Future<AppResult<AgentSqlExecutionResult>> executeSql(
    AgentSqlExecuteRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) async {
    seenScope = cancelScope;
    return const Failure(OperationCancelledFailure());
  }

  @override
  Future<AppResult<AgentSqlBatchExecutionResult>> executeSqlBatch(
    AgentSqlExecuteBatchRequest request, {
    AgentQueriesCancelScope? cancelScope,
  }) async {
    throw StateError('These summaries use unary SQL execution');
  }
}
