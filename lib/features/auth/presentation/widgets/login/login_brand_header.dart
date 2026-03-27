import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';

/// Brand section at the top of the login screen.
/// Matches Stitch "Login - Colmeia BI": hive icon container + product title.
class LoginBrandHeader extends StatelessWidget {
  const LoginBrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

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
          style: tt.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: 5,
            color: cs.primary,
          ),
        ),
      ],
    );
  }
}
