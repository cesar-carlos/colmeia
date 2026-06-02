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
}) {
  if (rows.isEmpty) {
    return const <AppCategoryDonutSegment>[];
  }

  final segments = <AppCategoryDonutSegment>[];
  for (var index = 0; index < rows.length; index++) {
    final row = rows[index];
    final label = row.isDiversos ? diversosLabel : row.nomeProduto.trim();
    segments.add(
      AppCategoryDonutSegment(
        label: label.isEmpty ? diversosLabel : label,
        value: row.percentual,
        valueLabel: AppBrFormatters.currency(row.valorVenda),
        percentLabel: '${_percentLabelFormat.format(row.percentual)}%',
        color: row.isDiversos ? diversosColor : palette[index % palette.length],
      ),
    );
  }
  return segments;
}
