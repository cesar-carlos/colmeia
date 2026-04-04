import 'dart:math' as math;

import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';

/// Soft rounded square behind a KPI leading icon (dashboard metric tiles).
class AppMetricStatIconBadge extends StatelessWidget {
  const AppMetricStatIconBadge({
    required this.child,
    required this.backgroundColor,
    this.size = 40,
    super.key,
  });

  final Widget child;
  final Color backgroundColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final clamped = math.max(10, math.min(14, tokens.cardRadius * 0.55));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(clamped.toDouble()),
      ),
      child: SizedBox(
        width: size,
        height: size,
        child: Center(child: child),
      ),
    );
  }
}
