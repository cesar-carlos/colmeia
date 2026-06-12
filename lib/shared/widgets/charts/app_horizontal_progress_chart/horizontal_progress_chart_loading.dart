import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/charts/app_horizontal_progress_chart/horizontal_progress_chart_header.dart';
import 'package:flutter/material.dart';

class HorizontalProgressChartLoadingBlock extends StatelessWidget {
  const HorizontalProgressChartLoadingBlock({
    required this.rowCount,
    required this.rowSpacing,
    required this.barHeight,
    required this.barRadius,
    required this.trackColor,
    required this.barColor,
    required this.rowPadding,
    required this.gapSm,
    required this.titleWidget,
    required this.title,
    required this.resolvedTitleStyle,
    required this.titleTextAlign,
    required this.titleBottomSpacing,
    super.key,
    this.headerTrailing,
  });

  final int rowCount;
  final double rowSpacing;
  final double barHeight;
  final BorderRadiusGeometry barRadius;
  final Color trackColor;
  final Color barColor;
  final EdgeInsetsGeometry? rowPadding;
  final double gapSm;
  final Widget? titleWidget;
  final String? title;
  final TextStyle? resolvedTitleStyle;
  final TextAlign? titleTextAlign;
  final double titleBottomSpacing;
  final Widget? headerTrailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final placeholderStyle = theme.textTheme.bodyLarge?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );

    final rows = <Widget>[];
    for (var i = 0; i < rowCount; i++) {
      if (i > 0) {
        rows.add(SizedBox(height: rowSpacing));
      }
      rows.add(
        Padding(
          padding: rowPadding ?? EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).appLoading,
                      style: placeholderStyle,
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    height: 12,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: gapSm),
              ClipRRect(
                borderRadius: barRadius,
                child: LinearProgressIndicator(
                  minHeight: barHeight,
                  backgroundColor: trackColor,
                  color: barColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        HorizontalProgressChartHeader(
          titleWidget: titleWidget,
          title: title,
          titleStyle: resolvedTitleStyle,
          titleTextAlign: titleTextAlign,
          bottomSpacing: titleBottomSpacing,
          headerTrailing: headerTrailing,
        ),
        ...rows,
      ],
    );
  }
}
