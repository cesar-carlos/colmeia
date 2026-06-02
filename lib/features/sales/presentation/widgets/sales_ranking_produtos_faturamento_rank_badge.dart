import 'package:colmeia/features/sales/presentation/widgets/sales_ranking_produtos_faturamento_grid_style.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:flutter/material.dart';

class SalesRankingProdutosFaturamentoRankBadge extends StatelessWidget {
  const SalesRankingProdutosFaturamentoRankBadge({
    required this.rank,
    super.key,
  });

  final int rank;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.appTokens;
    final colors = theme.appColors;

    final (background, foreground, icon) = switch (rank) {
      1 => (
        colors.primaryContainer,
        colors.onPrimaryContainer,
        Icons.workspace_premium_rounded,
      ),
      2 => (
        colors.secondaryContainer,
        colors.onSecondaryContainer,
        Icons.military_tech_rounded,
      ),
      3 => (
        colors.tertiaryFixed,
        colors.onTertiaryFixed,
        Icons.stars_rounded,
      ),
      _ => (
        theme.colorScheme.surfaceContainerHigh,
        colors.onSurfaceVariant,
        null,
      ),
    };
    final showMedal = rank >= 1 && rank <= 3;

    return ExcludeSemantics(
      child: Container(
        width: kSalesRankingFaturamentoRankBadgeSize,
        height: kSalesRankingFaturamentoRankBadgeSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(tokens.formFieldRadius),
        ),
        child: showMedal
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(icon, size: 10, color: foreground),
                  Text(
                    '$rank',
                    style: theme.appTypography.caption.copyWith(
                      fontWeight: FontWeight.w800,
                      color: foreground,
                      height: 1,
                    ),
                  ),
                ],
              )
            : Text(
                rank > 0 ? '$rank' : '–',
                style: theme.appTypography.caption.copyWith(
                  fontWeight: FontWeight.w800,
                  color: foreground,
                ),
              ),
      ),
    );
  }
}
