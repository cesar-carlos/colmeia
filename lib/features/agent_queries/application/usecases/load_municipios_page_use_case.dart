import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/municipio_list_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/municipio_list_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/municipio_list_repository.dart';

class LoadMunicipiosPageUseCase {
  LoadMunicipiosPageUseCase(this._repository);

  final MunicipioListRepository _repository;

  Future<AppResult<MunicipioListPageResult>> call({
    required String agentId,
    required MunicipioListFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
  }) {
    return _repository.loadPage(
      agentId: agentId,
      filter: filter,
      clientToken: clientToken,
      bridgeTimeoutMs: bridgeTimeoutMs,
    );
  }
}
