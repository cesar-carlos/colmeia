import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/marca_produto_option.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/marca_produto_options_repository.dart';

class LoadMarcaProdutoOptionsUseCase {
  LoadMarcaProdutoOptionsUseCase(this._repository);

  final MarcaProdutoOptionsRepository _repository;

  Future<AppResult<List<MarcaProdutoOption>>> call({
    required String userId,
    required String agentId,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
  }) {
    return _repository.loadAll(
      userId: userId,
      agentId: agentId,
      clientToken: clientToken,
      bridgeTimeoutMs: bridgeTimeoutMs,
      hubPresenceOnlineAgentIdsSnapshot: hubPresenceOnlineAgentIdsSnapshot,
      hubConnectedFromApprovedCatalogRow: hubConnectedFromApprovedCatalogRow,
    );
  }
}
