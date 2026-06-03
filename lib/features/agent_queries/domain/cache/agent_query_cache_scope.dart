import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_dia_semana_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_mensal_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_filter.dart';

/// Stable cache-scope segment for facts-store keys (filter dimensions, not dates).
abstract final class AgentQueryCacheScope {
  static String periodoScope({
    required String origem,
    required String geraFinanceiro,
    required String preVenda,
  }) {
    return '${origem.trim()}|${geraFinanceiro.trim()}|${preVenda.trim()}';
  }

  static String dailyScope(ResumoTotalDiarioVendasFilter filter) {
    return periodoScope(
      origem: filter.origem,
      geraFinanceiro: filter.geraFinanceiro,
      preVenda: filter.preVenda,
    );
  }

  static String municipioFilialPeriodoScope(
    ResumoTotalVendasMunicipioFilialPeriodoFilter filter,
  ) {
    final base = periodoScope(
      origem: filter.origem,
      geraFinanceiro: filter.geraFinanceiro,
      preVenda: filter.preVenda,
    );
    final segments = <String>[];
    final codEmpresa = filter.codEmpresa;
    if (codEmpresa != null) {
      segments.add('e$codEmpresa');
    }
    final codFilial = filter.codFilial;
    if (codFilial != null) {
      segments.add('f$codFilial');
    }
    if (filter.selectedBranches.isNotEmpty) {
      final branchKeys = filter.selectedBranches
          .map(
            (branch) =>
                '${branch.normalizedAgentId}:${branch.codEmpresa}:${branch.codFilial}',
          )
          .toList(growable: false)
        ..sort();
      segments.add('br:${branchKeys.join(',')}');
    }
    if (segments.isEmpty) {
      return base;
    }
    return '$base|${segments.join('|')}';
  }

  static String weekdayScope(ResumoParcelasDiaSemanaFilter filter) {
    final base = periodoScope(
      origem: filter.origem,
      geraFinanceiro: filter.geraFinanceiro,
      preVenda: filter.preVenda,
    );
    final segments = <String>[];
    final codEmpresa = filter.codEmpresa;
    if (codEmpresa != null) {
      segments.add('e$codEmpresa');
    }
    final codFilial = filter.codFilial;
    if (codFilial != null) {
      segments.add('f$codFilial');
    }
    final codVendedor = filter.codVendedor;
    if (codVendedor != null) {
      segments.add('v$codVendedor');
    }
    if (segments.isEmpty) {
      return base;
    }
    return '$base|${segments.join('|')}';
  }

  static String lucratividadeScope(ResumoProdutoVendaLucratividadeFilter filter) {
    return filter.trimmedOrigem;
  }

  static String mensalScope(ResumoParcelasMensalFilter filter) {
    final base = periodoScope(
      origem: filter.origem,
      geraFinanceiro: filter.geraFinanceiro,
      preVenda: filter.preVenda,
    );
    final segments = <String>[];
    final codEmpresa = filter.codEmpresa;
    if (codEmpresa != null) {
      segments.add('e$codEmpresa');
    }
    final codFilial = filter.codFilial;
    if (codFilial != null) {
      segments.add('f$codFilial');
    }
    final codVendedor = filter.codVendedor;
    if (codVendedor != null) {
      segments.add('v$codVendedor');
    }
    if (segments.isEmpty) {
      return base;
    }
    return '$base|${segments.join('|')}';
  }
}
