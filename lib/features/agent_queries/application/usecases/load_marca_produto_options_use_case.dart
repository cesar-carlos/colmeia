import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/marca_produto_option.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/marca_produto_options_repository.dart';

class LoadMarcaProdutoOptionsUseCase {
  LoadMarcaProdutoOptionsUseCase(this._repository);

  final MarcaProdutoOptionsRepository _repository;

  /// Prefer `searchTerm` for autocomplete flows.
  ///
  /// `nomeMarca` remains available as a legacy alias for compatibility.
  Future<AppResult<List<MarcaProdutoOption>>> call({
    required String userId,
    required String agentId,
    int page = 1,
    int pageSize = 20,
    String? searchTerm,
    @Deprecated('Use searchTerm instead.') String? nomeMarca,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
  }) {
    final mergedSearchTerm = _mergedAutocompleteInput(
      searchTerm: searchTerm,
      legacy: nomeMarca,
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
      cancelScope: cancelScope,
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
