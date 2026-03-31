import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/actions/app_text_action_button.dart';
import 'package:colmeia/shared/widgets/app_editorial_media_card.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/app_tag_chip.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';

class AppEditorialMediaCardDemoPage extends StatelessWidget {
  const AppEditorialMediaCardDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return ListView(
      padding: EdgeInsets.all(tokens.contentSpacing),
      children: <Widget>[
        const AppShellPageIntro(
          eyebrow: 'Cards editoriais',
          title: 'AppEditorialMediaCard',
          subtitle:
              'Card com hero visual no topo e bloco editorial abaixo, pensado '
              'para funcionar bem em light e dark.',
        ),
        SizedBox(height: tokens.sectionSpacing),
        const _EditorialMediaShowcaseCard(),
        SizedBox(height: tokens.sectionSpacing),
        const AppSectionCardWithHeading(
          title: 'Exemplo base',
          subtitle:
              'Estrutura inspirada na referencia: bloco visual superior e '
              'conteudo textual abaixo.',
          child: AppEditorialMediaCard(
            title: 'Visual Metaphor',
            description:
                'Imagery should focus on architectural precision, clean lines, '
                'and high-contrast technology motifs.',
            hero: _VisualBrandArtwork(),
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'Com CTA no rodape',
          subtitle:
              'Use o footer para acao secundaria, link contextual ou metadata.',
          child: AppEditorialMediaCard(
            title: 'Data Density',
            description:
                'Use this pattern to introduce analytical cards with a '
                'stronger '
                'visual hook before the user dives into the dataset.',
            hero: const _DataDensityArtwork(),
            footer: Align(
              alignment: Alignment.centerLeft,
              child: AppTextActionButton(
                label: 'View full dataset',
                icon: const Icon(Icons.arrow_forward_rounded),
                onPressed: () {},
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _EditorialMediaShowcaseCard extends StatelessWidget {
  const _EditorialMediaShowcaseCard();

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
      titleWidget: _EditorialMediaShowcaseHeading(theme: theme, tokens: tokens),
      subtitle:
          'Padrao para cards narrativos com imagem/arte no topo e explicacao '
          'objetiva logo abaixo.',
      headingTrailing: const _EditorialMediaShowcaseBadge(),
      headingBottom: const _EditorialMediaShowcaseLegend(),
      style: AppSectionCardWithHeadingStyle(
        headerBottomSpacing: tokens.sectionSpacing,
      ),
      child: Wrap(
        spacing: tokens.gapSm,
        runSpacing: tokens.gapSm,
        children: const <Widget>[
          AppTagChip(label: 'Hero visual'),
          AppTagChip(label: 'Titulo + descricao'),
          AppTagChip(label: 'Suporte a footer'),
          AppTagChip(label: 'Light e dark'),
        ],
      ),
    );
  }
}

class _EditorialMediaShowcaseHeading extends StatelessWidget {
  const _EditorialMediaShowcaseHeading({
    required this.theme,
    required this.tokens,
  });

  final ThemeData theme;
  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Editorial Surface',
          style: theme.appTypography.utilityOverline.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        SizedBox(height: tokens.gapXs),
        Row(
          children: <Widget>[
            Icon(
              Icons.photo_library_outlined,
              color: theme.colorScheme.primary,
              size: 18,
            ),
            SizedBox(width: tokens.gapSm),
            Expanded(
              child: Text(
                'Card com Hero Visual',
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

class _EditorialMediaShowcaseBadge extends StatelessWidget {
  const _EditorialMediaShowcaseBadge();

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

class _EditorialMediaShowcaseLegend extends StatelessWidget {
  const _EditorialMediaShowcaseLegend();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return Wrap(
      spacing: tokens.gapSm,
      runSpacing: tokens.gapSm,
      children: const <Widget>[
        _EditorialLegendChip(label: 'Visual primeiro'),
        _EditorialLegendChip(label: 'Leitura curta'),
        _EditorialLegendChip(label: 'Apropriado para storytelling'),
      ],
    );
  }
}

class _EditorialLegendChip extends StatelessWidget {
  const _EditorialLegendChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(tokens.formFieldRadius + 8),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.gapMd,
          vertical: tokens.gapXs,
        ),
        child: Text(
          label,
          style: theme.appTypography.caption.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _VisualBrandArtwork extends StatelessWidget {
  const _VisualBrandArtwork();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final baseBackground = theme.brightness == Brightness.dark
        ? cs.surfaceContainerLowest
        : cs.surfaceContainerLowest;

    return DecoratedBox(
      decoration: BoxDecoration(color: baseBackground),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned(
            left: -36,
            top: -12,
            bottom: 16,
            width: 132,
            child: Transform.rotate(
              angle: -0.18,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: cs.tertiary.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
            ),
          ),
          Positioned(
            right: -44,
            top: -8,
            bottom: 8,
            width: 144,
            child: Transform.rotate(
              angle: 0.22,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: cs.tertiary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(32),
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              width: 260,
              height: 158,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    cs.tertiary.withValues(alpha: 0.92),
                    cs.tertiary.withValues(alpha: 0.72),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Center(
                child: Text(
                  'VISUAL\nBRAND\nSTYLE',
                  textAlign: TextAlign.center,
                  style: theme.appTypography.sectionHeaderH2.copyWith(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w700,
                    height: 1.08,
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
                width: 56,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.58),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DataDensityArtwork extends StatelessWidget {
  const _DataDensityArtwork();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? cs.surface
            : cs.surfaceContainerLowest,
      ),
      child: Padding(
        padding: EdgeInsets.all(tokens.contentSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.table_rows_rounded, color: cs.primary),
                SizedBox(width: tokens.gapSm),
                Expanded(
                  child: Text(
                    'Data Density',
                    style: theme.appTypography.sectionHeaderH2.copyWith(
                      color: cs.onSurface,
                      fontSize: theme.textTheme.titleLarge?.fontSize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(tokens.formFieldRadius),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: tokens.gapSm,
                      vertical: tokens.gapXs,
                    ),
                    child: Text(
                      'ERP GRID',
                      style: theme.appTypography.utilityOverline.copyWith(
                        color: cs.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: tokens.contentSpacing),
            Container(
              height: 82,
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(tokens.formFieldRadius),
              ),
              child: Column(
                children: <Widget>[
                  _DataDensityRow(
                    label: 'ENTITY',
                    status: 'STATUS',
                    value: 'VALUE',
                    theme: theme,
                    isHeader: true,
                  ),
                  _DataDensityRow(
                    label: 'Hive_Core_Alpha',
                    status: 'OPTIMAL',
                    value: r'$45,200.00',
                    theme: theme,
                  ),
                  _DataDensityRow(
                    label: 'Cloud_Node_Delta',
                    status: 'WARNING',
                    value: r'$12,850.50',
                    theme: theme,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DataDensityRow extends StatelessWidget {
  const _DataDensityRow({
    required this.label,
    required this.status,
    required this.value,
    required this.theme,
    this.isHeader = false,
  });

  final String label;
  final String status;
  final String value;
  final ThemeData theme;
  final bool isHeader;

  @override
  Widget build(BuildContext context) {
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;

    final rowStyle = isHeader
        ? theme.appTypography.utilityOverline.copyWith(
            color: cs.onSurfaceVariant,
          )
        : theme.appTypography.caption.copyWith(
            color: cs.onSurface,
            fontWeight: FontWeight.w600,
          );

    final row = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.gapSm,
        vertical: tokens.gapSm,
      ),
      child: Row(
        children: <Widget>[
          Expanded(flex: 4, child: Text(label, style: rowStyle)),
          Expanded(
            flex: 2,
            child: isHeader
                ? Text(status, style: rowStyle)
                : Align(
                    alignment: Alignment.centerLeft,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: _statusColor(cs).withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        child: Text(
                          status,
                          style: theme.appTypography.utilityOverline.copyWith(
                            color: _statusColor(cs),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(value, style: rowStyle),
            ),
          ),
        ],
      ),
    );

    if (isHeader) {
      return row;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.2)),
        ),
      ),
      child: row,
    );
  }

  Color _statusColor(ColorScheme cs) {
    return switch (status) {
      'OPTIMAL' => Colors.tealAccent.shade700,
      'WARNING' => cs.primary,
      'CRITICAL' => cs.error,
      _ => cs.onSurfaceVariant,
    };
  }
}
