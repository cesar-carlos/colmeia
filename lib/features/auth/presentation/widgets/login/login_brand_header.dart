import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:flutter/material.dart';

/// Brand section at the top of the login screen.
/// Matches Stitch "Login - Colmeia BI": hive icon container + product title.
class LoginBrandHeader extends StatelessWidget {
  const LoginBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final tt = theme.textTheme;
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: tokens.authHeroContainerSize,
          height: tokens.authHeroContainerSize,
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(tokens.authHeroCornerRadius),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Icon(
            Icons.hive_rounded,
            size: tokens.authHeroGlyphSize,
            color: cs.onPrimaryContainer,
          ),
        ),
        SizedBox(height: tokens.authLoginGapHeroToTitle),
        Text(
          'COLMEIA BI',
          style: typography.utilityOverline.copyWith(
            fontSize: tt.titleLarge?.fontSize ?? 22,
            height: tt.titleLarge?.height,
            fontWeight: FontWeight.w900,
            letterSpacing: 5,
            color: cs.primary,
          ),
        ),
      ],
    );
  }
}
