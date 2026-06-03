/// Filters and pagination for the branch registration catalog query.
class CadastroFilialFilter {
  const CadastroFilialFilter({
    this.codEmpresa,
    this.codFilial,
    this.selectedBranches = const <CadastroFilialBranchRef>[],
    this.page = 1,
    this.pageSize = defaultPageSize,
    this.mapCatalogProjection = false,
  });

  static const int defaultPageSize = 20;

  /// Upper bound for page size (safety on agent `max_rows` and payload).
  /// Must stay <= `AgentQueriesBoundedResultMaxRows.cadastroFilialPage`.
  static const int maxPageSize = 500;

  final int? codEmpresa;
  final int? codFilial;
  final List<CadastroFilialBranchRef> selectedBranches;
  final int page;
  final int pageSize;

  /// When true, SQL omits CNPJ/CodMunicipio columns unused by the sales map.
  final bool mapCatalogProjection;

  bool get hasSelectedBranches => selectedBranches.isNotEmpty;

  Set<String>? get selectedAgentIds {
    if (selectedBranches.isEmpty) {
      return null;
    }
    return Set<String>.unmodifiable(
      selectedBranches.map((branch) => branch.normalizedAgentId),
    );
  }

  List<CadastroFilialBranchRef> branchesForAgent(String agentId) {
    final normalizedAgentId = agentId.trim();
    if (normalizedAgentId.isEmpty || selectedBranches.isEmpty) {
      return const <CadastroFilialBranchRef>[];
    }
    return selectedBranches
        .where((branch) => branch.normalizedAgentId == normalizedAgentId)
        .toList(growable: false);
  }

  String get filterScopeSignature {
    final branchSignature = CadastroFilialBranchRef.signature(selectedBranches);
    if (branchSignature != '*') {
      return 'branches=$branchSignature';
    }
    return 'empresa=${codEmpresa ?? '*'}|filial=${codFilial ?? '*'}';
  }

  CadastroFilialFilter copyWith({
    int? codEmpresa,
    int? codFilial,
    Object? selectedBranches = _sentinel,
    int? page,
    int? pageSize,
    bool? mapCatalogProjection,
  }) {
    return CadastroFilialFilter(
      codEmpresa: codEmpresa ?? this.codEmpresa,
      codFilial: codFilial ?? this.codFilial,
      selectedBranches: selectedBranches == _sentinel
          ? this.selectedBranches
          : List<CadastroFilialBranchRef>.unmodifiable(
              (selectedBranches as Iterable<CadastroFilialBranchRef>?) ??
                  const <CadastroFilialBranchRef>[],
            ),
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      mapCatalogProjection:
          mapCatalogProjection ?? this.mapCatalogProjection,
    );
  }

  int get offset => (page - 1) * pageSize;

  /// Inclusive 1-based row index for `ROW_NUMBER()` paging (`offset + 1`).
  int get startRow => offset + 1;

  /// Inclusive end row index for `ROW_NUMBER()` paging (`offset + pageSize`).
  int get endRow => offset + pageSize;

  String? validationError() {
    final empresa = codEmpresa;
    if (empresa != null && empresa <= 0) {
      return 'codEmpresa must be greater than zero';
    }
    final filial = codFilial;
    if (filial != null && filial < 0) {
      return 'codFilial must be greater than or equal to zero';
    }
    if (page < 1) {
      return 'page must be >= 1';
    }
    if (pageSize < 1) {
      return 'pageSize must be >= 1';
    }
    if (pageSize > maxPageSize) {
      return 'pageSize must be <= $maxPageSize';
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

class CadastroFilialBranchRef {
  const CadastroFilialBranchRef({
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

  static String signature(Iterable<CadastroFilialBranchRef> branches) {
    final normalized = <String>{
      for (final branch in branches)
        '${branch.normalizedAgentId}:${branch.codEmpresa}:${branch.codFilial}',
    }.toList(growable: false)..sort();
    if (normalized.isEmpty) {
      return '*';
    }
    return normalized.join(',');
  }
}

const Object _sentinel = Object();
