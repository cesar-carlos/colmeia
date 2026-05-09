import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_periodo_filter.dart';

/// Shared period and `ProdutoVendido` SQL flags for agent queries that filter by
/// sale date, `Origem`, `TipoOperacaoSaida.GeraFinanceiro`, and `PreVenda`.
///
/// Consumed via typedef aliases declared in `resumo_total_diario_vendas_filter.dart`
/// and `resumo_total_vendas_municipio_filial_diario_filter.dart`.
///
/// Validation matches [ResumoParcelasPeriodoFilter], plus `origem` must not
/// contain SQL `LIKE` wildcards (`%`, `_`): matching uses `=` on `pv.Origem`.
class ResumoVendasProdutoVendidoSqlPeriodoFilter {
  const ResumoVendasProdutoVendidoSqlPeriodoFilter({
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

  String? validationError() {
    final base = _periodo.validationError();
    if (base != null) {
      return base;
    }
    final o = trimmedOrigem;
    if (o.contains('%') || o.contains('_')) {
      return 'origem must not contain SQL LIKE wildcards (% or _) '
          'for ProdutoVendido resumo queries (exact match only)';
    }
    return null;
  }
}
