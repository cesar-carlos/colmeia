import 'dart:ui';

import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';

/// Frosted-glass container — Stitch "Glass & Gradient" rule:
/// surface at ~85% opacity with backdrop blur; edge via outline, not shadow.
class LoginGlassCard extends StatelessWidget {
  const LoginGlassCard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    final radius = BorderRadius.circular(tokens.authGlassCornerRadius);

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: tokens.authGlassBlurSigma,
          sigmaY: tokens.authGlassBlurSigma,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest.withValues(
              alpha: tokens.authGlassSurfaceOpacity,
            ),
            borderRadius: radius,
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(tokens.authGlassPadding),
            child: child,
          ),
        ),
      ),
    );
  }
}
