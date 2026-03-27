import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';

/// Hero for corporate registration: Stitch badge, headline, supporting copy.
class RegisterCorporateHeroSection extends StatelessWidget {
  const RegisterCorporateHeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;
    final tokens = theme.extension<AppThemeTokens>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.gapMd,
            vertical: tokens.gapXs,
          ),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(tokens.formFieldRadius),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Text(
            'Registro Corporativo',
            style: tt.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.primary,
              letterSpacing: 0.6,
            ),
          ),
        ),
        SizedBox(height: tokens.authLoginGapMajorSection),
        Text(
          'Crie sua conta no Colmeia BI.',
          style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        SizedBox(height: tokens.gapSm),
        Text(
          'Otimize a gestão da sua loja com análises precisas e dados em '
          'tempo real. Junte-se à nossa rede de inteligência.',
          style: tt.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
        ),
      ],
    );
  }
}
