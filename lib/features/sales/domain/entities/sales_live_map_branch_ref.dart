import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_filter.dart';
import 'package:flutter/foundation.dart';

@immutable
class SalesLiveMapBranchRef {
  const SalesLiveMapBranchRef({
    required this.agentId,
    required this.codEmpresa,
    required this.codFilial,
  });

  factory SalesLiveMapBranchRef.fromStorageKey(String raw) {
    final value = raw.trim();
    final lastDash = value.lastIndexOf('-');
    if (lastDash <= 0 || lastDash == value.length - 1) {
      throw const FormatException('Invalid live map branch ref storage key.');
    }
    final secondLastDash = value.lastIndexOf('-', lastDash - 1);
    if (secondLastDash <= 0 || secondLastDash == lastDash - 1) {
      throw const FormatException('Invalid live map branch ref storage key.');
    }

    final codEmpresa = int.tryParse(
      value.substring(secondLastDash + 1, lastDash),
    );
    final codFilial = int.tryParse(value.substring(lastDash + 1));
    final agentId = value.substring(0, secondLastDash).trim();
    if (agentId.isEmpty || codEmpresa == null || codFilial == null) {
      throw const FormatException('Invalid live map branch ref storage key.');
    }

    return SalesLiveMapBranchRef(
      agentId: agentId,
      codEmpresa: codEmpresa,
      codFilial: codFilial,
    );
  }

  final String agentId;
  final int codEmpresa;
  final int codFilial;

  String toStorageKey() => '$agentId-$codEmpresa-$codFilial';

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
