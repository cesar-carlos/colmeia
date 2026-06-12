import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/charts/app_chart_theme.dart';
import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

class CategoryDonutCardLoadingBlock extends StatelessWidget {
  const CategoryDonutCardLoadingBlock({
    required this.tokens,
    required this.chartTheme,
    super.key,
  });

  final AppThemeTokens tokens;
  final AppChartTheme chartTheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final h = chartTheme.height * 0.85;
    final radius = BorderRadius.circular(tokens.cardRadius * 0.45);
    final placeholder = SizedBox(
      height: h,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: h * 0.92,
            height: h * 0.92,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
            ),
          ),
          SizedBox(width: tokens.gapMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List<Widget>.generate(4, (i) {
                return Padding(
                  padding: EdgeInsets.only(bottom: i < 3 ? tokens.gapXs : 0),
                  child: Container(
                    height: 36,
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: radius,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );

    return ExcludeSemantics(
      child: Skeletonizer(
        child: placeholder,
      ),
    );
  }
}

class CategoryDonutCardEmptyBlock extends StatelessWidget {
  const CategoryDonutCardEmptyBlock({
    required this.placeholder,
    required this.tokens,
    required this.theme,
    super.key,
  });

  final Widget? placeholder;
  final AppThemeTokens tokens;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: tokens.chartCompactHeight * 0.9,
      child: Center(
        child:
            placeholder ??
            Text(
              l10n.chartCategoryDonutEmptyForFilter,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.appColors.onSurfaceVariant,
              ),
            ),
      ),
    );
  }
}
