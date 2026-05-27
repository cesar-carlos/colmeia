import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_participant.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_vendas_municipio_filial_periodo_row.dart';
import 'package:colmeia/features/sales/application/sales_live_map_point_factory.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_branch_ref.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_point.dart';

/// Mutable aggregate built per branch while mapping `LoadSalesLiveMapUseCase`
/// reports. Owns location metadata, sales counters, and the optional pending
/// / unavailable status applied when sales data is incomplete.
class SalesLiveMapBranchAggregate {
  SalesLiveMapBranchAggregate({
    required this.agentId,
    required this.agentName,
    required this.codEmpresa,
    required this.codFilial,
    required this.nomeFilial,
    required this.nomeMunicipioFilial,
    required this.ufMunicipioFilial,
    this.nomeFantasiaFilial,
    this.cepFilial,
    this.codigoIbgeMunicipioFilial,
  });

  factory SalesLiveMapBranchAggregate.fromRow({
    required AgentQueryExecutionParticipant<
      ResumoTotalVendasMunicipioFilialPeriodoRow
    >
    participant,
    required ResumoTotalVendasMunicipioFilialPeriodoRow row,
  }) {
    return SalesLiveMapBranchAggregate(
      agentId: participant.agentId,
      agentName: participant.displayName,
      codEmpresa: row.codEmpresa,
      codFilial: row.codFilial,
      nomeFilial: row.nomeFilial,
      nomeFantasiaFilial: row.nomeFantasiaFilial,
      cepFilial: row.cepFilial,
      nomeMunicipioFilial: row.nomeMunicipioFilial,
      ufMunicipioFilial: row.ufMunicipioFilial,
      codigoIbgeMunicipioFilial: row.codigoIbgeMunicipioFilial,
    );
  }

  factory SalesLiveMapBranchAggregate.fromCadastro({
    required AgentQueryExecutionParticipant<CadastroFilialRow> participant,
    required CadastroFilialRow row,
  }) {
    return SalesLiveMapBranchAggregate(
      agentId: participant.agentId,
      agentName: participant.displayName,
      codEmpresa: row.codEmpresa,
      codFilial: row.codFilial,
      nomeFilial: row.nomeFilial,
      nomeFantasiaFilial: row.nomeFantasia,
      cepFilial: row.cep,
      nomeMunicipioFilial: row.nomeMunicipio,
      ufMunicipioFilial: row.ufMunicipio,
      codigoIbgeMunicipioFilial: row.codigoIbge,
    );
  }

  final String agentId;
  final String agentName;
  final int codEmpresa;
  final int codFilial;
  final String nomeFilial;
  final String? nomeFantasiaFilial;
  final String? cepFilial;
  final String? nomeMunicipioFilial;
  final String? ufMunicipioFilial;
  final String? codigoIbgeMunicipioFilial;
  double totalVenda = 0;
  int qtdVendas = 0;
  bool salesDataLoading = false;
  bool salesDataUnavailable = false;
  String? salesDataStatusLabel;

  String get id => '$agentId-$codEmpresa-$codFilial';

  SalesLiveMapBranchRef get branchRef => SalesLiveMapBranchRef(
    agentId: agentId,
    codEmpresa: codEmpresa,
    codFilial: codFilial,
  );

  String get locationSourceSignature {
    return <String>[
      _normalizeLocationPart(ufMunicipioFilial),
      _normalizeLocationPart(nomeMunicipioFilial),
      _normalizeLocationPart(cepFilial),
      _normalizeLocationPart(codigoIbgeMunicipioFilial),
    ].join('|');
  }

  String get name {
    final fantasy = nomeFantasiaFilial?.trim();
    if (fantasy != null && fantasy.isNotEmpty) {
      return fantasy;
    }
    return nomeFilial;
  }

  String get registrationName {
    final branch = nomeFilial.trim();
    if (branch.isNotEmpty) {
      return branch;
    }
    return name;
  }

  void add(ResumoTotalVendasMunicipioFilialPeriodoRow row) {
    totalVenda += row.totalVenda;
    qtdVendas += row.qtdVendas;
  }

  void markSalesDataLoading() {
    salesDataLoading = true;
    salesDataUnavailable = false;
    salesDataStatusLabel = null;
  }

  void markSalesDataUnavailable(String statusLabel) {
    salesDataLoading = false;
    salesDataUnavailable = true;
    salesDataStatusLabel = statusLabel;
  }

  SalesLiveMapPointSource toPointSource(
    SalesLiveMapPointFactory pointFactory,
  ) {
    return pointFactory.createSource(
      id: id,
      name: name,
      salesAmount: totalVenda,
      salesCount: qtdVendas,
      uf: ufMunicipioFilial,
      city: nomeMunicipioFilial,
      latitude: null,
      longitude: null,
      cep: cepFilial,
      ibgeMunicipalityCode: codigoIbgeMunicipioFilial,
      allowUfFallback: false,
      fantasyName: salesLiveMapTrimmedOrNull(nomeFantasiaFilial),
      branchName: salesLiveMapTrimmedOrNull(nomeFilial),
      companyCode: codEmpresa,
      branchCode: codFilial,
      agentName: salesLiveMapTrimmedOrNull(agentName),
      salesDataLoading: salesDataLoading,
      salesDataUnavailable: salesDataUnavailable,
      salesDataStatusLabel: salesLiveMapTrimmedOrNull(salesDataStatusLabel),
      subtitle: 'Agente $agentName - Empresa $codEmpresa - Filial $codFilial',
      payload: this,
    );
  }

  SalesLiveMapBranchOption toBranchOption() {
    return SalesLiveMapBranchOption(
      id: id,
      agentId: agentId,
      agentName: agentName,
      codEmpresa: codEmpresa,
      codFilial: codFilial,
      registrationName: registrationName,
      fantasyName: salesLiveMapTrimmedOrNull(nomeFantasiaFilial),
      city: _branchCityLabel,
      uf: _branchUfLabel,
    );
  }

  String get _branchCityLabel {
    final city = nomeMunicipioFilial?.trim();
    if (city != null && city.isNotEmpty) {
      return city;
    }

    return 'Sem municipio';
  }

  String get _branchUfLabel {
    final uf = ufMunicipioFilial?.trim();
    if (uf != null && uf.isNotEmpty) {
      return uf;
    }

    return '--';
  }
}

String _normalizeLocationPart(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return '';
  }
  return trimmed.toUpperCase();
}

/// Returns [value] trimmed when it has non-whitespace content, or `null`
/// otherwise. Shared across `SalesLiveMapBranchAggregate` consumers that
/// need to normalize optional string fields for display or persistence.
String? salesLiveMapTrimmedOrNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}
