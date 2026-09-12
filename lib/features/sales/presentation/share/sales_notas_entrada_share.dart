import 'package:colmeia/features/agent_queries/domain/entities/nota_entrada_row.dart';
import 'package:colmeia/features/sales/presentation/share/sales_chart_share_export_filter.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_notas_entrada_columns.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_export_header_context.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_metadata.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_limits.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_pdf_orientation.dart';
import 'package:colmeia/shared/widgets/charts/chart_share_table_data.dart';
import 'package:flutter/material.dart';

ChartShareExportHeaderContext buildSalesNotasEntradaShareExportHeaderContext({
  required AppLocalizations l10n,
  required String agentName,
  required DateTime dataLancamentoInicio,
  required DateTime dataLancamentoFim,
  String? searchTerm,
}) {
  final parameters = <ChartShareExportHeaderParameter>[
    ChartShareExportHeaderParameter(
      label: l10n.salesNotasEntradaLaunchPeriodLabel,
      value: salesChartShareDateTimeRangeValue(
        DateTimeRange(start: dataLancamentoInicio, end: dataLancamentoFim),
      ),
    ),
  ];
  final normalizedSearch = searchTerm?.trim();
  if (normalizedSearch != null && normalizedSearch.isNotEmpty) {
    parameters.add(
      ChartShareExportHeaderParameter(
        label: l10n.salesNotasEntradaFilterSearch,
        value: normalizedSearch,
      ),
    );
  }
  return buildSalesSingleAgentChartShareExportHeaderContext(
    l10n: l10n,
    agentName: agentName,
    parameters: parameters,
  );
}

ChartShareMetadata buildSalesNotasEntradaShareMetadata({
  required AppLocalizations l10n,
  required List<NotaEntradaRow> rows,
  ChartShareExportHeaderContext? exportHeaderContext,
}) {
  final labels = SalesNotasEntradaColumnLabels.fromL10n(l10n);
  final tableLimit = applyChartShareTableRowLimit(
    tableData: ChartShareTableData(
      headers: <String>[
        labels.documento,
        labels.emissao,
        labels.entrada,
        labels.lancamento,
        labels.codFornecedor,
        labels.fornecedor,
        labels.cnpjCpf,
        labels.valorTotal,
      ],
      rows: <List<String>>[
        for (final row in rows)
          <String>[
            row.numeroDocumento,
            formatSalesNotasEntradaDate(row.dataEmissao),
            formatSalesNotasEntradaDate(row.dataEntrada),
            formatSalesNotasEntradaLaunchDate(row.dataLancamento),
            '${row.codFornecedor}',
            row.nomeFornecedor,
            formatSalesNotasEntradaTaxId(row.cnpjCpfFornecedor),
            formatSalesNotasEntradaCurrency(row.valorTotalCompra),
          ],
      ],
    ),
    truncationNoticeBuilder: (shownRows, totalRows) =>
        l10n.chartSharePdfTableRowsTruncated(shownRows, totalRows),
  );

  return ChartShareMetadata(
    title: l10n.salesCardNotasEntradaTitle,
    subtitle: l10n.salesNotasEntradaIntroSubtitle,
    includeChartImage: false,
    pdfOrientation: ChartSharePdfOrientation.landscape,
    filterSummary: buildChartSharePdfFilterSummary(
      exportHeaderContext: exportHeaderContext,
      truncationNotice: tableLimit.truncationNotice,
    ),
    tableData: tableLimit.tableData,
  );
}
