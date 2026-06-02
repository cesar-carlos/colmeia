import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/agent_queries/domain/entities/ranking_produtos_faturamento_row.dart';
import 'package:colmeia/shared/widgets/charts/app_category_donut_card_models.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final NumberFormat _percentLabelFormat = NumberFormat('#,##0.0', 'pt_BR');

/// Builds pie/donut slices from branch rows using [RankingProdutosFaturamentoRow.percentual]
/// so segment angles close at ~100% of branch revenue share.
List<AppCategoryDonutSegment> rankingProdutosFaturamentoDonutSegments({
  required List<RankingProdutosFaturamentoRow> rows,
  required String diversosLabel,
  required List<Color> palette,
  Color? diversosColor,
  int maxHighlightedSegments = 5,
}) {
  if (rows.isEmpty) {
    return const <AppCategoryDonutSegment>[];
  }

  final segments = <AppCategoryDonutSegment>[];

  final highlightedCount = maxHighlightedSegments < 1
      ? rows.length
      : maxHighlightedSegments;
  final highlightedRows = rows.take(highlightedCount).toList(growable: false);
  final overflowRows = rows.skip(highlightedCount).toList(growable: false);

  for (var index = 0; index < highlightedRows.length; index++) {
    final row = highlightedRows[index];
    segments.add(
      _segmentFromRow(
        row,
        index: index,
        diversosLabel: diversosLabel,
        palette: palette,
        diversosColor: diversosColor,
      ),
    );
  }

  if (overflowRows.isNotEmpty) {
    final overflowPercent = overflowRows.fold<double>(
      0,
      (sum, row) => sum + row.percentual,
    );
    final overflowValue = overflowRows.fold<double>(
      0,
      (sum, row) => sum + row.valorVenda,
    );
    segments.add(
      AppCategoryDonutSegment(
        label: diversosLabel,
        value: overflowPercent,
        valueLabel: AppBrFormatters.currency(overflowValue),
        percentLabel: '${_percentLabelFormat.format(overflowPercent)}%',
        color: diversosColor,
      ),
    );
  }
  return segments;
}

AppCategoryDonutSegment _segmentFromRow(
  RankingProdutosFaturamentoRow row, {
  required int index,
  required String diversosLabel,
  required List<Color> palette,
  required Color? diversosColor,
}) {
  final label = row.isDiversos ? diversosLabel : row.nomeProduto.trim();
  return AppCategoryDonutSegment(
    label: label.isEmpty ? diversosLabel : label,
    value: row.percentual,
    valueLabel: AppBrFormatters.currency(row.valorVenda),
    percentLabel: '${_percentLabelFormat.format(row.percentual)}%',
    color: row.isDiversos ? diversosColor : palette[index % palette.length],
  );
}
