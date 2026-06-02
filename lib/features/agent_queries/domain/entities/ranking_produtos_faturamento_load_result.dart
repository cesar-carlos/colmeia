import 'package:colmeia/features/agent_queries/domain/entities/ranking_produtos_faturamento_row.dart';

/// Result of a ranking produtos faturamento load, preserving SQL row order.
class RankingProdutosFaturamentoLoadResult {
  const RankingProdutosFaturamentoLoadResult({required this.rows});

  final List<RankingProdutosFaturamentoRow> rows;

  List<RankingProdutosFaturamentoRow> get rankedProducts => rows
      .where((row) => !row.isDiversos)
      .toList(growable: false);

  List<RankingProdutosFaturamentoRow> get diversosRows =>
      rows.where((row) => row.isDiversos).toList(growable: false);
}
