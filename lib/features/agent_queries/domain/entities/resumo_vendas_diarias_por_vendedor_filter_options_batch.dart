import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_text_option.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_vendedor_option.dart';

/// One agent's three filter option lists from a single `sql.executeBatch`.
class ResumoVendasDiariasPorVendedorFilterOptionsPerAgentBatch {
  const ResumoVendasDiariasPorVendedorFilterOptionsPerAgentBatch({
    required this.vendedorOptions,
    required this.bairroOptions,
    required this.municipioOptions,
  });

  final List<ResumoVendasDiariasPorVendedorVendedorOption> vendedorOptions;
  final List<ResumoVendasDiariasPorVendedorTextOption> bairroOptions;
  final List<ResumoVendasDiariasPorVendedorTextOption> municipioOptions;
}

/// Merged filter options after an across-agents batch load.
class ResumoVendasDiariasPorVendedorAllFilterOptionsAcrossAgents {
  const ResumoVendasDiariasPorVendedorAllFilterOptionsAcrossAgents({
    required this.vendedorOptions,
    required this.bairroOptions,
    required this.municipioOptions,
  });

  final List<ResumoVendasDiariasPorVendedorVendedorOption> vendedorOptions;
  final List<ResumoVendasDiariasPorVendedorTextOption> bairroOptions;
  final List<ResumoVendasDiariasPorVendedorTextOption> municipioOptions;
}
