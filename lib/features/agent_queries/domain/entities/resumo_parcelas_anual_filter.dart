import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_periodo_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_sql_dimension_filters.dart';

/// Filters for the annual parcel summary SQL (company, branch, calendar year).
///
/// Period and flags match `ResumoParcelasPeriodoFilter`. Optional dimension
/// filters are forwarded as named parameters (null means no restriction).
/// When [codFilial] is set, [codEmpresa] must also be set so the branch filter
/// is well scoped.
class ResumoParcelasAnualFilter {
  const ResumoParcelasAnualFilter({
    required this.dataVendaInicio,
    required this.dataVendaFim,
    this.origem = 'FrenteLoja',
    this.geraFinanceiro = 'S',
    this.preVenda = 'N',
    this.codEmpresa,
    this.codFilial,
    this.codVendedor,
  });

  final DateTime dataVendaInicio;
  final DateTime dataVendaFim;
  final String origem;
  final String geraFinanceiro;
  final String preVenda;
  final int? codEmpresa;
  final int? codFilial;
  final int? codVendedor;

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
    final periodoError = _periodo.validationError();
    if (periodoError != null) {
      return periodoError;
    }
    return ResumoParcelasSqlDimensionFilters.validationError(
      codEmpresa: codEmpresa,
      codFilial: codFilial,
      codVendedor: codVendedor,
    );
  }
}
