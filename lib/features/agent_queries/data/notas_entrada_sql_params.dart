import 'package:colmeia/features/agent_queries/data/agent_queries_sql_local_date.dart';
import 'package:colmeia/features/agent_queries/data/resumo_vendas_diarias_suggestion_sql_params.dart';
import 'package:colmeia/features/agent_queries/domain/entities/notas_entrada_filter.dart';

/// Named binds shared by the note catalog and supplier-summary queries.
abstract final class NotasEntradaSqlParams {
  static Map<String, Object?> namedParamsFor(NotasEntradaFilter filter) {
    final params = <String, Object?>{
      'codEmpresa': filter.codEmpresa,
      'codFilial': filter.codFilial,
      'nomeFornecedorPattern':
          ResumoVendasDiariasSuggestionSqlParams.buildSearchPattern(
            filter.normalizedSearchTerm,
          ),
      'startRow': filter.startRow,
      'endRow': filter.endRow,
    };
    final dataLancamentoInicio = filter.dataLancamentoInicio;
    if (dataLancamentoInicio != null) {
      params['dataLancamentoInicio'] = AgentQueriesSqlLocalDate.format(
        dataLancamentoInicio,
      );
    }
    final dataLancamentoFim = filter.dataLancamentoFim;
    if (dataLancamentoFim != null) {
      params['dataLancamentoFim'] = AgentQueriesSqlLocalDate.format(
        dataLancamentoFim,
      );
    }
    final codFornecedor = filter.codFornecedor;
    if (codFornecedor != null) {
      params['codFornecedor'] = codFornecedor;
    }
    return params;
  }
}
