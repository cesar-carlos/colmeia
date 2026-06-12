import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/agent_queries/domain/entities/ranking_produtos_faturamento_row.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/reports/app_report_column.dart';
import 'package:intl/intl.dart';

List<AppReportColumn<RankingProdutosFaturamentoRow>>
rankingProdutosFaturamentoShareGridColumns(AppLocalizations l10n) {
  final percentFormat = NumberFormat('#,##0.0', 'pt_BR');

  return <AppReportColumn<RankingProdutosFaturamentoRow>>[
    AppReportColumn<RankingProdutosFaturamentoRow>(
      key: 'posicao',
      label: l10n.salesRankingProdutosFaturamentoGridColumnPosicao,
      valueGetter: (row) => row.posicao,
      sortable: false,
    ),
    AppReportColumn<RankingProdutosFaturamentoRow>(
      key: 'produto',
      label: l10n.salesRankingProdutosFaturamentoGridColumnProduto,
      valueGetter: (row) => row.isDiversos
          ? l10n.salesRankingProdutosFaturamentoDiversosLabel
          : row.nomeProduto.trim(),
      sortable: false,
    ),
    AppReportColumn<RankingProdutosFaturamentoRow>(
      key: 'venda',
      label: l10n.salesRankingProdutosFaturamentoGridColumnVenda,
      valueGetter: (row) => row.valorVenda,
      formatter: (value) => AppBrFormatters.currency((value as num?) ?? 0),
    ),
    AppReportColumn<RankingProdutosFaturamentoRow>(
      key: 'percent',
      label: l10n.salesRankingProdutosFaturamentoGridColumnPercent,
      valueGetter: (row) => row.percentual,
      formatter: (value) => '${percentFormat.format((value as num?) ?? 0)}%',
    ),
  ];
}
