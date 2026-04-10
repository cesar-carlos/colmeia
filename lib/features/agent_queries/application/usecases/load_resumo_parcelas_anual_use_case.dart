import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_anual_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_anual_row.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_parcelas_anual_repository.dart';

class LoadResumoParcelasAnualUseCase {
  LoadResumoParcelasAnualUseCase(this._repository);

  final ResumoParcelasAnualRepository _repository;

  Future<AppResult<List<ResumoParcelasAnualRow>>> call({
    required String agentId,
    required ResumoParcelasAnualFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
  }) {
    return _repository.load(
      agentId: agentId,
      filter: filter,
      clientToken: clientToken,
      bridgeTimeoutMs: bridgeTimeoutMs,
    );
  }
}
