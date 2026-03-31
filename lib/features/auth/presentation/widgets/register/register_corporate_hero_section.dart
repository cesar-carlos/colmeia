import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_editorial_media_card.dart';
import 'package:colmeia/shared/widgets/app_tag_chip.dart';
import 'package:flutter/material.dart';

/// Hero for corporate registration: Stitch badge, headline, supporting copy.
class RegisterCorporateHeroSection extends StatelessWidget {
  const RegisterCorporateHeroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tokens = theme.extension<AppThemeTokens>()!;

    return AppEditorialMediaCard(
      heroHeight: 164,
      heroBackgroundColor: cs.surfaceContainerLowest,
      title: 'Crie sua conta no Colmeia BI.',
      description:
          'Otimize a gestão da sua loja com análises precisas, permissões por '
          'perfil e visão operacional em tempo real.',
      footer: Wrap(
        spacing: tokens.gapSm,
        runSpacing: tokens.gapSm,
        children: <Widget>[
          AppTagChip(
            label: 'Registro Corporativo',
            foregroundColor: cs.primary,
            backgroundColor: cs.primaryContainer.withValues(alpha: 0.38),
            borderColor: cs.primary.withValues(alpha: 0.16),
          ),
          const AppTagChip(label: 'Acesso por lojas'),
          const AppTagChip(label: 'Perfis e permissões'),
        ],
      ),
      hero: const _RegisterCorporateHeroArtwork(),
    );
  }
}

class _RegisterCorporateHeroArtwork extends StatelessWidget {
  const _RegisterCorporateHeroArtwork();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Positioned(
          left: -28,
          top: 10,
          bottom: 20,
          width: 120,
          child: Transform.rotate(
            angle: -0.2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: cs.tertiary.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(tokens.cardRadius + 8),
              ),
            ),
          ),
        ),
        Positioned(
          right: -40,
          top: -8,
          bottom: 4,
          width: 150,
          child: Transform.rotate(
            angle: 0.24,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: cs.tertiary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(tokens.cardRadius + 12),
              ),
            ),
          ),
        ),
        Center(
          child: Container(
            width: 250,
            height: 132,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  cs.tertiary.withValues(alpha: 0.92),
                  cs.tertiary.withValues(alpha: 0.72),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(tokens.cardRadius + 10),
            ),
            child: Center(
              child: Text(
                'CORPORATE\nACCESS\nFLOW',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.94),
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 18,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              width: 60,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.58),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
