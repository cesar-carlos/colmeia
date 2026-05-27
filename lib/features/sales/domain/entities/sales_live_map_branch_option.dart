import 'package:colmeia/features/sales/domain/entities/sales_live_map_branch_ref.dart';

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
}
