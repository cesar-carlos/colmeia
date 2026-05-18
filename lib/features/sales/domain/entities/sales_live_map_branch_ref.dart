import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_filter.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_branch_ref_codec.dart';
import 'package:flutter/foundation.dart';

@immutable
class SalesLiveMapBranchRef {
  const SalesLiveMapBranchRef({
    required this.agentId,
    required this.codEmpresa,
    required this.codFilial,
  });

  factory SalesLiveMapBranchRef.fromStorageKey(String raw) {
    return SalesLiveMapBranchRefCodec.decode(raw);
  }

  final String agentId;
  final int codEmpresa;
  final int codFilial;

  String toStorageKey() => SalesLiveMapBranchRefCodec.encode(this);

  ResumoTotalVendasMunicipioFilialPeriodoBranchRef toAgentQueryBranchRef() {
    return ResumoTotalVendasMunicipioFilialPeriodoBranchRef(
      agentId: agentId,
      codEmpresa: codEmpresa,
      codFilial: codFilial,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is SalesLiveMapBranchRef &&
        other.agentId == agentId &&
        other.codEmpresa == codEmpresa &&
        other.codFilial == codFilial;
  }

  @override
  int get hashCode => Object.hash(agentId, codEmpresa, codFilial);

  @override
  String toString() => toStorageKey();
}
