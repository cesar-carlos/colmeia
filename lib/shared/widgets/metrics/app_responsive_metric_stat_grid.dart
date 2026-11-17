import 'dart:math' as math;

import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/metrics/resolve_metric_grid_columns.dart';
import 'package:material_ui/material_ui.dart';

/// Lays out metric tiles in a responsive wrap grid with equal column widths.
///
/// Column count follows [AppBreakpoints.kpiGridWide] and
/// [AppBreakpoints.kpiGridExtraWide] unless overridden.
class AppResponsiveMetricStatGrid extends StatelessWidget {
  const AppResponsiveMetricStatGrid({
    required this.children,
    this.narrowColumns = 2,
    this.wideColumns = 3,
    this.extraWideColumns = 3,
    super.key,
  }) : assert(narrowColumns > 0, 'narrowColumns must be positive.'),
       assert(wideColumns > 0, 'wideColumns must be positive.'),
       assert(extraWideColumns > 0, 'extraWideColumns must be positive.');

  final List<Widget> children;
  final int narrowColumns;
  final int wideColumns;
  final int extraWideColumns;

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;
    final fontSize = Theme.of(context).appTypography.body.fontSize!;
    final textScale =
        MediaQuery.textScalerOf(context).scale(fontSize) / fontSize;

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = tokens.gapMd;
        final availableWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final columns = resolveMetricGridColumns(
          width: availableWidth,
          gap: gap,
          textScale: textScale,
          narrowColumns: narrowColumns,
          wideColumns: wideColumns,
          extraWideColumns: extraWideColumns,
        );
        final width = math.max<double>(
          0,
          (availableWidth - (gap * (columns - 1))) / columns,
        );

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: children
              .map((child) => SizedBox(width: width, child: child))
              .toList(growable: false),
        );
      },
    );
  }
}
