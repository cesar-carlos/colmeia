import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/app_status_badge.dart';
import 'package:colmeia/shared/widgets/app_tag_chip.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';

class AppBadgesDemoPage extends StatelessWidget {
  const AppBadgesDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return ListView(
      padding: EdgeInsets.all(tokens.contentSpacing),
      children: <Widget>[
        const AppShellPageIntro(
          eyebrow: 'Feedback',
          title: 'Tags e Status',
          subtitle:
              'Diferenca entre badges informativas e estados semanticos para '
              'uso consistente no design system.',
        ),
        SizedBox(height: tokens.sectionSpacing),
        const _BadgesShowcaseCard(),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'AppTagChip',
          subtitle:
              'Use para contexto, metadata, filtros ativos e labels '
              'auxiliares.',
          child: Wrap(
            spacing: tokens.gapSm,
            runSpacing: tokens.gapSm,
            children: const <Widget>[
              AppTagChip(label: 'Loja Centro'),
              AppTagChip(label: 'Atualizado agora'),
              AppTagChip(label: '12 filtros'),
              AppTagChip(
                label: 'Matriz',
                icon: Icons.storefront_outlined,
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'AppStatusBadge',
          subtitle:
              'Use quando o texto comunica um estado semantico como sucesso, '
              'erro, aviso ou informacao.',
          child: Wrap(
            spacing: tokens.gapSm,
            runSpacing: tokens.gapSm,
            children: const <Widget>[
              AppStatusBadge(
                label: 'EM ANALISE',
                variant: AppStatusBadgeVariant.info,
              ),
              AppStatusBadge(
                label: 'ATIVO',
                variant: AppStatusBadgeVariant.success,
              ),
              AppStatusBadge(
                label: 'PENDENTE',
                variant: AppStatusBadgeVariant.warning,
              ),
              AppStatusBadge(
                label: 'BLOQUEADO',
                variant: AppStatusBadgeVariant.error,
              ),
              AppStatusBadge(label: 'RASCUNHO'),
            ],
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'Quando usar cada um',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const _BadgeUsageRow(
                title: 'Tag informativa',
                description:
                    'Contexto passivo, contagem, loja ativa, filtros e labels '
                    'de apoio.',
                badge: AppTagChip(label: '3 filtros'),
              ),
              SizedBox(height: tokens.contentSpacing),
              const _BadgeUsageRow(
                title: 'Status semantico',
                description:
                    'Situacoes de sucesso, aviso, erro ou estado operacional.',
                badge: AppStatusBadge(
                  label: 'PENDENTE',
                  variant: AppStatusBadgeVariant.warning,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BadgesShowcaseCard extends StatelessWidget {
  const _BadgesShowcaseCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return AppSectionCardWithHeading(
      padding: EdgeInsets.fromLTRB(
        tokens.contentSpacing,
        tokens.contentSpacing,
        tokens.contentSpacing,
        tokens.contentSpacing + tokens.gapSm,
      ),
      titleWidget: _BadgesShowcaseHeading(theme: theme, tokens: tokens),
      subtitle:
          'Guia rapido para distinguir metadata contextual de estados com '
          'significado semantico.',
      headingTrailing: const _BadgesShowcaseBadge(),
      headingBottom: const _BadgesShowcaseLegend(),
      style: AppSectionCardWithHeadingStyle(
        headerBottomSpacing: tokens.sectionSpacing,
      ),
      child: Wrap(
        spacing: tokens.gapSm,
        runSpacing: tokens.gapSm,
        children: const <Widget>[
          AppTagChip(label: 'Relatorio mensal'),
          AppTagChip(label: 'Ultima sync'),
          AppStatusBadge(
            label: 'SUCESSO',
            variant: AppStatusBadgeVariant.success,
          ),
          AppStatusBadge(
            label: 'ERRO',
            variant: AppStatusBadgeVariant.error,
          ),
        ],
      ),
    );
  }
}

class _BadgesShowcaseHeading extends StatelessWidget {
  const _BadgesShowcaseHeading({
    required this.theme,
    required this.tokens,
  });

  final ThemeData theme;
  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Label Pattern',
          style: theme.appTypography.utilityOverline.copyWith(
            color: cs.primary,
          ),
        ),
        SizedBox(height: tokens.gapXs),
        Row(
          children: <Widget>[
            Icon(Icons.label_rounded, color: cs.primary, size: 18),
            SizedBox(width: tokens.gapSm),
            Expanded(
              child: Text(
                'Tags e Status',
                style: theme.appTypography.sectionHeaderH2.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BadgesShowcaseBadge extends StatelessWidget {
  const _BadgesShowcaseBadge();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.primaryContainer.withValues(alpha: 0.52),
        borderRadius: BorderRadius.circular(tokens.formFieldRadius + 6),
        border: Border.all(color: cs.primary.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.gapMd,
          vertical: tokens.gapXs,
        ),
        child: Text(
          'New',
          style: theme.appTypography.utilityOverline.copyWith(
            color: cs.primary,
          ),
        ),
      ),
    );
  }
}

class _BadgesShowcaseLegend extends StatelessWidget {
  const _BadgesShowcaseLegend();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return Wrap(
      spacing: tokens.gapSm,
      runSpacing: tokens.gapSm,
      children: const <Widget>[
        _BadgesLegendChip(label: 'Metadata'),
        _BadgesLegendChip(label: 'Status'),
        _BadgesLegendChip(label: 'Semantic'),
      ],
    );
  }
}

class _BadgesLegendChip extends StatelessWidget {
  const _BadgesLegendChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(tokens.formFieldRadius + 4),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.gapMd,
          vertical: tokens.gapXs,
        ),
        child: Text(
          label,
          style: theme.appTypography.utilityOverline.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _BadgeUsageRow extends StatelessWidget {
  const _BadgeUsageRow({
    required this.title,
    required this.description,
    required this.badge,
  });

  final String title;
  final String description;
  final Widget badge;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        badge,
        SizedBox(width: tokens.gapMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: theme.appTypography.sectionHeaderH2.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: tokens.gapXs),
              Text(
                description,
                style: theme.appTypography.body.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
