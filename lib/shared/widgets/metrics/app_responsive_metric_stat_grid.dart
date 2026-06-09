import 'dart:math' as math;

import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';

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
  });

  final List<Widget> children;
  final int narrowColumns;
  final int wideColumns;
  final int extraWideColumns;

  @override
  Widget build(BuildContext context) {
    final tokens = context.appTokens;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = _resolveColumns(constraints.maxWidth);
        final gap = tokens.gapMd;
        final width = math.max<double>(
          0,
          (constraints.maxWidth - (gap * (columns - 1))) / columns,
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

  int _resolveColumns(double maxWidth) {
    if (maxWidth >= AppBreakpoints.kpiGridExtraWide) {
      return extraWideColumns;
    }
    if (maxWidth >= AppBreakpoints.kpiGridWide) {
      return wideColumns;
    }
    return narrowColumns;
  }
}
