import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_produto_vendido_sql_periodo_filter.dart';

/// Filters for period sales by branch municipality
/// (`ResumoTotalVendasMunicipioFilialPeriodo`).
///
/// Same shape as [ResumoVendasProdutoVendidoSqlPeriodoFilter].
class ResumoTotalVendasMunicipioFilialPeriodoFilter
    extends ResumoVendasProdutoVendidoSqlPeriodoFilter {
  ResumoTotalVendasMunicipioFilialPeriodoFilter({
    required super.dataVendaInicio,
    required super.dataVendaFim,
    super.origem,
    super.geraFinanceiro,
    super.preVenda,
    Iterable<ResumoTotalVendasMunicipioFilialPeriodoBranchRef>
        selectedBranches =
        const <ResumoTotalVendasMunicipioFilialPeriodoBranchRef>[],
  }) : selectedBranches = List.unmodifiable(selectedBranches);

  /// Optional branch pushdown for live-map reloads.
  ///
  /// The bridge has a low named-parameter budget for some deployments, so the
  /// repository validates these refs and inlines only integer company/branch
  /// literals into the generated SQL.
  final List<ResumoTotalVendasMunicipioFilialPeriodoBranchRef> selectedBranches;

  bool get hasSelectedBranches => selectedBranches.isNotEmpty;

  Set<String>? get selectedAgentIds {
    if (selectedBranches.isEmpty) {
      return null;
    }
    return Set<String>.unmodifiable(
      selectedBranches.map((branch) => branch.agentId),
    );
  }

  List<ResumoTotalVendasMunicipioFilialPeriodoBranchRef> branchesForAgent(
    String agentId,
  ) {
    final normalizedAgentId = agentId.trim();
    if (normalizedAgentId.isEmpty || selectedBranches.isEmpty) {
      return const <ResumoTotalVendasMunicipioFilialPeriodoBranchRef>[];
    }

    return selectedBranches
        .where((branch) => branch.agentId == normalizedAgentId)
        .toList(growable: false);
  }

  @override
  String? validationError() {
    final base = super.validationError();
    if (base != null) {
      return base;
    }

    for (final branch in selectedBranches) {
      final error = branch.validationError();
      if (error != null) {
        return error;
      }
    }
    return null;
  }
}

class ResumoTotalVendasMunicipioFilialPeriodoBranchRef {
  const ResumoTotalVendasMunicipioFilialPeriodoBranchRef({
    required this.agentId,
    required this.codEmpresa,
    required this.codFilial,
  });

  final String agentId;
  final int codEmpresa;
  final int codFilial;

  String get normalizedAgentId => agentId.trim();

  String? validationError() {
    if (normalizedAgentId.isEmpty) {
      return 'selectedBranches.agentId must not be empty';
    }
    if (codEmpresa <= 0) {
      return 'selectedBranches.codEmpresa must be greater than zero';
    }
    if (codFilial < 0) {
      return 'selectedBranches.codFilial must be greater than or equal to zero';
    }
    return null;
  }
}
