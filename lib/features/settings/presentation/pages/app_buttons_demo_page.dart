import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/actions/app_destructive_button.dart';
import 'package:colmeia/shared/widgets/actions/app_flat_button.dart';
import 'package:colmeia/shared/widgets/actions/app_primary_button.dart';
import 'package:colmeia/shared/widgets/actions/app_secondary_button.dart';
import 'package:colmeia/shared/widgets/actions/app_text_action_button.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';

/// Demos for primary, secondary, flat and text action buttons (fake actions).
class AppButtonsDemoPage extends StatelessWidget {
  const AppButtonsDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    void showTap(String name) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$name pressionado')),
      );
    }

    return ListView(
      padding: EdgeInsets.all(tokens.contentSpacing),
      children: <Widget>[
        const AppShellPageIntro(
          eyebrow: 'Acoes',
          title: 'Botoes',
          subtitle:
              'Estados habilitado, desabilitado, loading e com/sem icone.',
        ),
        SizedBox(height: tokens.sectionSpacing),
        _ButtonShowcaseCard(onTap: showTap),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'AppPrimaryButton',
          subtitle: 'CTA principal — âmbar sólido (primary / onPrimary).',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppPrimaryButton(
                label: 'Continuar',
                onPressed: () => showTap('Primary padrao'),
              ),
              SizedBox(height: tokens.gapSm),
              AppPrimaryButton(
                label: 'Com icone',
                icon: const Icon(Icons.check_rounded),
                onPressed: () => showTap('Primary com icone'),
              ),
              SizedBox(height: tokens.gapSm),
              AppPrimaryButton(
                label: 'Largura total',
                fillWidth: true,
                onPressed: () => showTap('Primary largura total'),
              ),
              SizedBox(height: tokens.gapSm),
              const AppPrimaryButton(
                label: 'Desabilitado',
                onPressed: null,
              ),
              SizedBox(height: tokens.gapSm),
              AppPrimaryButton(
                label: 'Carregando',
                isLoading: true,
                onPressed: () => showTap('Primary loading'),
              ),
              SizedBox(height: tokens.gapSm),
              AppPrimaryButton(
                label: 'Loading com rotulo',
                isLoading: true,
                showLabelWhileLoading: true,
                onPressed: () => showTap('Primary loading rotulo'),
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'AppSecondaryButton',
          subtitle:
              'Outline (padrão) e variante tonal para superfícies ocupadas.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppSecondaryButton(
                label: 'Cancelar',
                onPressed: () => showTap('Secondary outline padrao'),
              ),
              SizedBox(height: tokens.gapSm),
              AppSecondaryButton(
                label: 'Exportar',
                icon: const Icon(Icons.ios_share_outlined),
                onPressed: () => showTap('Secondary outline com icone'),
              ),
              SizedBox(height: tokens.gapSm),
              const AppSecondaryButton(
                label: 'Desabilitado',
                onPressed: null,
              ),
              SizedBox(height: tokens.gapSm),
              AppSecondaryButton(
                label: 'Carregando',
                isLoading: true,
                onPressed: () => showTap('Secondary outline loading'),
              ),
              SizedBox(height: tokens.gapMd),
              AppSecondaryButton(
                variant: AppSecondaryButtonVariant.tonal,
                label: 'Tonal',
                onPressed: () => showTap('Secondary tonal'),
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'AppDestructiveButton',
          subtitle: 'Exclusão ou reversão irreversível — error / onError.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppDestructiveButton(
                label: 'Excluir',
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: () => showTap('Destructive padrao'),
              ),
              SizedBox(height: tokens.gapSm),
              const AppDestructiveButton(
                label: 'Desabilitado',
                onPressed: null,
              ),
              SizedBox(height: tokens.gapSm),
              AppDestructiveButton(
                label: 'Carregando',
                isLoading: true,
                onPressed: () => showTap('Destructive loading'),
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'AppFlatButton',
          subtitle: 'Ghost/flat para açoes de baixa ênfase.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppFlatButton(
                label: 'Ghost Button',
                onPressed: () => showTap('Flat padrao'),
              ),
              SizedBox(height: tokens.gapSm),
              AppFlatButton(
                label: 'Ghost com icone',
                icon: const Icon(Icons.close_rounded),
                onPressed: () => showTap('Flat com icone'),
              ),
              SizedBox(height: tokens.gapSm),
              AppFlatButton(
                isLoading: true,
                onPressed: () => showTap('Flat loading'),
                label: 'Carregando',
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'AppTextActionButton',
          subtitle: 'Text button.',
          child: Wrap(
            spacing: tokens.gapSm,
            runSpacing: tokens.gapSm,
            children: <Widget>[
              AppTextActionButton(
                label: 'Detalhes',
                onPressed: () => showTap('Text padrao'),
              ),
              AppTextActionButton(
                label: 'Ajuda',
                icon: const Icon(Icons.help_outline_rounded),
                onPressed: () => showTap('Text com icone'),
              ),
              const AppTextActionButton(
                label: 'Desabilitado',
                onPressed: null,
              ),
              AppTextActionButton(
                isLoading: true,
                label: 'Salvando',
                onPressed: () => showTap('Text loading'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ButtonShowcaseCard extends StatelessWidget {
  const _ButtonShowcaseCard({required this.onTap});

  final void Function(String name) onTap;

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
      titleWidget: _ButtonShowcaseHeading(theme: theme, tokens: tokens),
      subtitle:
          'Combinacao recomendada para CTA principal, acao secundaria, ghost e '
          'estado critico.',
      headingTrailing: const _ButtonShowcaseBadge(),
      headingBottom: const _ButtonShowcaseLegend(),
      style: AppSectionCardWithHeadingStyle(
        headerBottomSpacing: tokens.sectionSpacing,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppPrimaryButton(
            label: 'Primary Action',
            fillWidth: true,
            icon: const Icon(Icons.rocket_launch_outlined, size: 18),
            onPressed: () => onTap('Primary showcase'),
          ),
          SizedBox(height: tokens.gapSm),
          AppSecondaryButton(
            label: 'Secondary Outline',
            fillWidth: true,
            onPressed: () => onTap('Secondary showcase'),
          ),
          SizedBox(height: tokens.gapSm),
          AppFlatButton(
            label: 'Ghost Button',
            icon: const Icon(Icons.close_rounded, size: 18),
            onPressed: () => onTap('Ghost showcase'),
          ),
          SizedBox(height: tokens.gapMd),
          Row(
            children: <Widget>[
              Expanded(
                child: AppDestructiveButton(
                  label: 'Destructive',
                  onPressed: () => onTap('Destructive showcase'),
                ),
              ),
              SizedBox(width: tokens.gapSm),
              const Expanded(
                child: AppFlatButton(
                  label: 'Disabled',
                  onPressed: null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ButtonShowcaseHeading extends StatelessWidget {
  const _ButtonShowcaseHeading({required this.theme, required this.tokens});

  final ThemeData theme;
  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Recommended Stack',
          style: theme.appTypography.utilityOverline.copyWith(
            color: cs.primary,
          ),
        ),
        SizedBox(height: tokens.gapXs),
        Row(
          children: <Widget>[
            Icon(Icons.ads_click_outlined, color: cs.primary, size: 18),
            SizedBox(width: tokens.gapSm),
            Expanded(
              child: Text(
                'Action Buttons',
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

class _ButtonShowcaseBadge extends StatelessWidget {
  const _ButtonShowcaseBadge();

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
          'Preview',
          style: theme.appTypography.utilityOverline.copyWith(
            color: cs.primary,
          ),
        ),
      ),
    );
  }
}

class _ButtonShowcaseLegend extends StatelessWidget {
  const _ButtonShowcaseLegend();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return Wrap(
      spacing: tokens.gapSm,
      runSpacing: tokens.gapSm,
      children: const <Widget>[
        _ButtonShowcaseLegendChip(label: 'Solid'),
        _ButtonShowcaseLegendChip(label: 'Outline'),
        _ButtonShowcaseLegendChip(label: 'Ghost'),
        _ButtonShowcaseLegendChip(label: 'Critical'),
      ],
    );
  }
}

class _ButtonShowcaseLegendChip extends StatelessWidget {
  const _ButtonShowcaseLegendChip({required this.label});

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
