import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_periodo_filter.dart';

/// Filters for daily sales totals (`ResumoTotalDiarioVendas`).
///
/// Period and flags match [ResumoParcelasPeriodoFilter].
class ResumoTotalDiarioVendasFilter {
  const ResumoTotalDiarioVendasFilter({
    required this.dataVendaInicio,
    required this.dataVendaFim,
    this.origem = 'FrenteLoja',
    this.geraFinanceiro = 'S',
    this.preVenda = 'N',
  });

  final DateTime dataVendaInicio;
  final DateTime dataVendaFim;
  final String origem;
  final String geraFinanceiro;
  final String preVenda;

  ResumoParcelasPeriodoFilter get _periodo => ResumoParcelasPeriodoFilter(
    dataVendaInicio: dataVendaInicio,
    dataVendaFim: dataVendaFim,
    origem: origem,
    geraFinanceiro: geraFinanceiro,
    preVenda: preVenda,
  );

  String get trimmedOrigem => _periodo.trimmedOrigem;

  String get trimmedGeraFinanceiro => _periodo.trimmedGeraFinanceiro;

  String get trimmedPreVenda => _periodo.trimmedPreVenda;

  String? validationError() => _periodo.validationError();
}
