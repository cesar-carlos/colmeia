import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/grupo_produto_option.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/grupo_produto_options_repository.dart';

class LoadGrupoProdutoOptionsUseCase {
  LoadGrupoProdutoOptionsUseCase(this._repository);

  final GrupoProdutoOptionsRepository _repository;

  /// Prefer `searchTerm` for autocomplete flows.
  ///
  /// `nomeGrupoProduto` remains available as a legacy alias for compatibility.
  Future<AppResult<List<GrupoProdutoOption>>> call({
    required String userId,
    required String agentId,
    int page = 1,
    int pageSize = 20,
    String? searchTerm,
    @Deprecated('Use searchTerm instead.') String? nomeGrupoProduto,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
  }) {
    final mergedSearchTerm = _mergedAutocompleteInput(
      searchTerm: searchTerm,
      legacy: nomeGrupoProduto,
    );
    return _repository.loadAll(
      userId: userId,
      agentId: agentId,
      page: page,
      pageSize: pageSize,
      searchTerm: mergedSearchTerm,
      clientToken: clientToken,
      bridgeTimeoutMs: bridgeTimeoutMs,
      hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
      hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
    );
  }

  static String? _mergedAutocompleteInput({
    required String? searchTerm,
    required String? legacy,
  }) {
    final normalized = searchTerm?.trim();
    if (normalized != null && normalized.isNotEmpty) {
      return normalized;
    }
    return legacy;
  }
}
