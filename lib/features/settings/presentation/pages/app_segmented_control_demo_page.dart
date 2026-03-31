import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/forms/app_segmented_control.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';

class AppSegmentedControlDemoPage extends StatefulWidget {
  const AppSegmentedControlDemoPage({super.key});

  @override
  State<AppSegmentedControlDemoPage> createState() =>
      _AppSegmentedControlDemoPageState();
}

class _AppSegmentedControlDemoPageState
    extends State<AppSegmentedControlDemoPage> {
  _SalesWindow _salesWindow = _SalesWindow.week;
  _SalesChannel _salesChannel = _SalesChannel.all;
  _OverviewMetric _overviewMetric = _OverviewMetric.revenue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return ListView(
      padding: EdgeInsets.all(tokens.contentSpacing),
      children: <Widget>[
        const AppShellPageIntro(
          eyebrow: 'Controles',
          title: 'Segmented Control',
          subtitle:
              'Selecao unica para filtros inline com estilo consistente em '
              'light e dark mode.',
        ),
        SizedBox(height: tokens.sectionSpacing),
        _SegmentedControlShowcaseCard(
          salesWindow: _salesWindow,
          onSalesWindowChanged: (value) {
            setState(() => _salesWindow = value);
          },
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'Filtro de canal',
          subtitle:
              'Uso ideal para filtros curtos e frequentes dentro da mesma '
              'superficie.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AppSegmentedControl<_SalesChannel>(
                options: const <AppSegmentedControlOption<_SalesChannel>>[
                  AppSegmentedControlOption(
                    value: _SalesChannel.all,
                    label: 'Todos canais',
                  ),
                  AppSegmentedControlOption(
                    value: _SalesChannel.store,
                    label: 'Loja fisica',
                  ),
                  AppSegmentedControlOption(
                    value: _SalesChannel.digital,
                    label: 'Digital',
                  ),
                ],
                value: _salesChannel,
                onChanged: (value) {
                  setState(() => _salesChannel = value);
                },
              ),
              SizedBox(height: tokens.contentSpacing),
              _SegmentedSelectionFeedback(
                label: 'Canal selecionado',
                value: switch (_salesChannel) {
                  _SalesChannel.all => 'Todos canais',
                  _SalesChannel.store => 'Loja fisica',
                  _SalesChannel.digital => 'Digital',
                },
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'Overflow horizontal',
          subtitle:
              'Quando houver labels maiores, o controle mantem leitura e '
              'permite scroll horizontal.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              AppSegmentedControl<_OverviewMetric>(
                options: const <AppSegmentedControlOption<_OverviewMetric>>[
                  AppSegmentedControlOption(
                    value: _OverviewMetric.revenue,
                    label: 'Receita liquida',
                  ),
                  AppSegmentedControlOption(
                    value: _OverviewMetric.margin,
                    label: 'Margem operacional',
                  ),
                  AppSegmentedControlOption(
                    value: _OverviewMetric.ticket,
                    label: 'Ticket medio',
                  ),
                  AppSegmentedControlOption(
                    value: _OverviewMetric.conversion,
                    label: 'Conversao de vendas',
                  ),
                ],
                value: _overviewMetric,
                onChanged: (value) {
                  setState(() => _overviewMetric = value);
                },
              ),
              SizedBox(height: tokens.contentSpacing),
              _SegmentedSelectionFeedback(
                label: 'Metrica em foco',
                value: switch (_overviewMetric) {
                  _OverviewMetric.revenue => 'Receita liquida',
                  _OverviewMetric.margin => 'Margem operacional',
                  _OverviewMetric.ticket => 'Ticket medio',
                  _OverviewMetric.conversion => 'Conversao de vendas',
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SegmentedControlShowcaseCard extends StatelessWidget {
  const _SegmentedControlShowcaseCard({
    required this.salesWindow,
    required this.onSalesWindowChanged,
  });

  final _SalesWindow salesWindow;
  final ValueChanged<_SalesWindow> onSalesWindowChanged;

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
      titleWidget: _SegmentedControlShowcaseHeading(
        theme: theme,
        tokens: tokens,
      ),
      subtitle:
          'Padrao recomendado para filtros textuais de selecao unica, com '
          'ênfase sutil e leitura rapida.',
      headingTrailing: const _SegmentedControlShowcaseBadge(),
      headingBottom: const _SegmentedControlShowcaseLegend(),
      style: AppSectionCardWithHeadingStyle(
        headerBottomSpacing: tokens.sectionSpacing,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          AppSegmentedControl<_SalesWindow>(
            expandToFill: true,
            options: const <AppSegmentedControlOption<_SalesWindow>>[
              AppSegmentedControlOption(
                value: _SalesWindow.week,
                label: 'Ultima semana',
              ),
              AppSegmentedControlOption(
                value: _SalesWindow.month,
                label: 'Ultimo mes',
              ),
              AppSegmentedControlOption(
                value: _SalesWindow.quarter,
                label: 'Trimestre',
              ),
            ],
            value: salesWindow,
            onChanged: onSalesWindowChanged,
          ),
          SizedBox(height: tokens.contentSpacing),
          _SegmentedSelectionFeedback(
            label: 'Recorte ativo',
            value: switch (salesWindow) {
              _SalesWindow.week => 'Ultima semana',
              _SalesWindow.month => 'Ultimo mes',
              _SalesWindow.quarter => 'Trimestre',
            },
          ),
        ],
      ),
    );
  }
}

class _SegmentedControlShowcaseHeading extends StatelessWidget {
  const _SegmentedControlShowcaseHeading({
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
          'Filter Pattern',
          style: theme.appTypography.utilityOverline.copyWith(
            color: cs.primary,
          ),
        ),
        SizedBox(height: tokens.gapXs),
        Row(
          children: <Widget>[
            Icon(Icons.tune_rounded, color: cs.primary, size: 18),
            SizedBox(width: tokens.gapSm),
            Expanded(
              child: Text(
                'Segmented Control',
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

class _SegmentedControlShowcaseBadge extends StatelessWidget {
  const _SegmentedControlShowcaseBadge();

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

class _SegmentedControlShowcaseLegend extends StatelessWidget {
  const _SegmentedControlShowcaseLegend();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return Wrap(
      spacing: tokens.gapSm,
      runSpacing: tokens.gapSm,
      children: const <Widget>[
        _SegmentedControlLegendChip(label: 'Single Select'),
        _SegmentedControlLegendChip(label: 'Inline Filter'),
        _SegmentedControlLegendChip(label: 'Scrollable'),
      ],
    );
  }
}

class _SegmentedControlLegendChip extends StatelessWidget {
  const _SegmentedControlLegendChip({required this.label});

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

class _SegmentedSelectionFeedback extends StatelessWidget {
  const _SegmentedSelectionFeedback({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: theme.appTypography.utilityOverline.copyWith(
            color: cs.primary,
          ),
        ),
        SizedBox(height: tokens.gapXs),
        Text(
          value,
          style: theme.appTypography.sectionHeaderH2.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

enum _SalesWindow {
  week,
  month,
  quarter,
}

enum _SalesChannel {
  all,
  store,
  digital,
}

enum _OverviewMetric {
  revenue,
  margin,
  ticket,
  conversion,
}
