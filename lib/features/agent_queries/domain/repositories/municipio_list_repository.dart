import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/municipio_list_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/municipio_list_page_result.dart';

// Paginated municipio catalog from agent SQL (DI + tests mirror other query
// repos).
// ignore: one_member_abstracts
abstract interface class MunicipioListRepository {
  Future<AppResult<MunicipioListPageResult>> loadPage({
    required String userId,
    required String agentId,
    required MunicipioListFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
  });
}
