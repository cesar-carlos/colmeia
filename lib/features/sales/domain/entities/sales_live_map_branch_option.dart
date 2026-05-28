import 'package:colmeia/features/sales/domain/entities/sales_live_map_branch_ref.dart';
import 'package:flutter/foundation.dart';

@immutable
class SalesLiveMapBranchOption {
  const SalesLiveMapBranchOption({
    required this.id,
    required this.agentId,
    required this.agentName,
    required this.codEmpresa,
    required this.codFilial,
    required this.registrationName,
    required this.city,
    required this.uf,
    this.fantasyName,
  });

  final String id;
  final String agentId;
  final String agentName;
  final int codEmpresa;
  final int codFilial;
  final String registrationName;
  final String city;
  final String uf;
  final String? fantasyName;

  String get name => registrationName;

  SalesLiveMapBranchRef get branchRef => SalesLiveMapBranchRef(
    agentId: agentId,
    codEmpresa: codEmpresa,
    codFilial: codFilial,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is SalesLiveMapBranchOption &&
        other.id == id &&
        other.agentId == agentId &&
        other.agentName == agentName &&
        other.codEmpresa == codEmpresa &&
        other.codFilial == codFilial &&
        other.registrationName == registrationName &&
        other.city == city &&
        other.uf == uf &&
        other.fantasyName == fantasyName;
  }

  @override
  int get hashCode => Object.hash(
    id,
    agentId,
    agentName,
    codEmpresa,
    codFilial,
    registrationName,
    city,
    uf,
    fantasyName,
  );
}
