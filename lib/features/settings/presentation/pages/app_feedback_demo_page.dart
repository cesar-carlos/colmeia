import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/actions/app_primary_button.dart';
import 'package:colmeia/shared/widgets/actions/app_secondary_button.dart';
import 'package:colmeia/shared/widgets/app_dialog.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/feedback/inline_alert_banner.dart';
import 'package:colmeia/shared/widgets/forms/app_switch_field.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';

/// Demos for error panels, alert banner and skeleton loading (interactive).
class AppFeedbackDemoPage extends StatefulWidget {
  const AppFeedbackDemoPage({super.key});

  @override
  State<AppFeedbackDemoPage> createState() => _AppFeedbackDemoPageState();
}

class _AppFeedbackDemoPageState extends State<AppFeedbackDemoPage> {
  bool _skeletonEnabled = true;

  Future<void> _showDialogDemo() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AppConfirmDialog(
          title: 'Confirm Deployment?',
          confirmLabel: 'Confirm',
          message:
              'This will push Hive_Alpha config to production clusters. '
              'This action cannot be undone.',
          onConfirm: () => Navigator.of(dialogContext).pop(),
          onCancel: () => Navigator.of(dialogContext).pop(),
          onClose: () => Navigator.of(dialogContext).pop(),
        );
      },
    );
  }

  Future<void> _showDestructiveDialogDemo() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AppDestructiveDialog(
          title: 'Delete Deployment?',
          confirmLabel: 'Delete',
          message:
              'This will permanently remove the Hive_Alpha deployment metadata '
              'from the workspace.',
          onConfirm: () => Navigator.of(dialogContext).pop(),
          onCancel: () => Navigator.of(dialogContext).pop(),
          onClose: () => Navigator.of(dialogContext).pop(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;

    return ListView(
      padding: EdgeInsets.all(tokens.contentSpacing),
      children: <Widget>[
        const AppShellPageIntro(
          eyebrow: 'Feedback',
          title: 'Erros, alertas e skeleton',
          subtitle:
              'Variantes de painel de erro, banner e estado de carregamento.',
        ),
        SizedBox(height: tokens.sectionSpacing),
        _FeedbackShowcaseCard(
          skeletonEnabled: _skeletonEnabled,
          onChanged: (value) {
            setState(() {
              _skeletonEnabled = value;
            });
          },
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'AppInlineErrorPanel',
          subtitle: 'Card com titulo e acao; plain sem cartao.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const AppInlineErrorPanel(
                title: 'Nao foi possivel sincronizar',
                message:
                    'Verifique a conexao e tente novamente. '
                    'Codigo fake: E-204.',
                onRetry: _noopRetry,
              ),
              SizedBox(height: tokens.gapMd),
              const AppInlineErrorPanel(
                message: 'Aviso em linha simples, sem cartao (variante plain).',
                variant: AppInlineErrorPanelVariant.plain,
              ),
              SizedBox(height: tokens.gapMd),
              const AppInlineErrorPanel(
                variant: AppInlineErrorPanelVariant.plain,
                title: 'Titulo opcional',
                message: 'Plain com titulo e botao de retry.',
                onRetry: _noopRetry,
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'InlineAlertBanner',
          subtitle:
              'Superficie de alerta; ajuste icone e mensagem conforme o caso.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const InlineAlertBanner(
                message: 'Operacao concluida com ressalvas.',
                icon: Icons.info_outline_rounded,
              ),
              SizedBox(height: tokens.gapSm),
              const InlineAlertBanner(
                message: 'Limite do periodo atingido.',
                icon: Icons.warning_amber_rounded,
              ),
              SizedBox(height: tokens.gapSm),
              const InlineAlertBanner(
                message: 'Falha ao salvar alteracoes.',
              ),
              SizedBox(height: tokens.gapSm),
              const InlineAlertBanner(
                message: 'Sincronizado com sucesso.',
                icon: Icons.check_circle_outline_rounded,
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'AppDialog',
          subtitle:
              'Dialog compartilhado para confirmacoes, alertas e acoes '
              'sensiveis no mesmo padrao visual do app.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const AppDialogSurface(
                title: 'Confirm Deployment?',
                message:
                    'This will push Hive_Alpha config to production clusters. '
                    'This action cannot be undone.',
                actions: <Widget>[
                  _FeedbackDialogGhostButton(label: 'Cancel'),
                  _FeedbackDialogPrimaryButton(label: 'Confirm'),
                ],
                onClose: _noopRetry,
              ),
              SizedBox(height: tokens.gapMd),
              Row(
                children: <Widget>[
                  Expanded(
                    child: AppPrimaryButton(
                      onPressed: _showDialogDemo,
                      label: 'Abrir confirm',
                    ),
                  ),
                  SizedBox(width: tokens.gapMd),
                  Expanded(
                    child: AppSecondaryButton(
                      variant: AppSecondaryButtonVariant.tonal,
                      onPressed: _showDestructiveDialogDemo,
                      label: 'Abrir destructive',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'AppSkeleton',
          subtitle: 'Ative ou desative o efeito para comparar.',
          headingBottom: AppSwitchField(
            label: 'Skeleton ativo',
            helperText:
                'Liga ou desliga o placeholder mantendo o mesmo layout.',
            value: _skeletonEnabled,
            onChanged: (value) {
              setState(() {
                _skeletonEnabled = value;
              });
            },
          ),
          child: AppSkeleton(
            enabled: _skeletonEnabled,
            child: AppSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    height: 20,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: tokens.gapSm),
                  Container(
                    height: 14,
                    width: 180,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: tokens.gapMd),
                  Row(
                    children: <Widget>[
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: tokens.gapMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Container(
                              height: 16,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            SizedBox(height: tokens.gapXs),
                            Container(
                              height: 12,
                              width: 120,
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

void _noopRetry() {}

class _FeedbackDialogGhostButton extends StatelessWidget {
  const _FeedbackDialogGhostButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AppSecondaryButton(
        onPressed: () {},
        label: label,
      ),
    );
  }
}

class _FeedbackDialogPrimaryButton extends StatelessWidget {
  const _FeedbackDialogPrimaryButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AppPrimaryButton(
        onPressed: () {},
        label: label,
      ),
    );
  }
}

class _FeedbackShowcaseCard extends StatelessWidget {
  const _FeedbackShowcaseCard({
    required this.skeletonEnabled,
    required this.onChanged,
  });

  final bool skeletonEnabled;
  final ValueChanged<bool> onChanged;

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
      titleWidget: _FeedbackShowcaseHeading(theme: theme, tokens: tokens),
      subtitle:
          'Superficies de erro, aviso, dialog e loading para estados inline do '
          'produto.',
      headingTrailing: const _FeedbackShowcaseBadge(),
      headingBottom: const _FeedbackShowcaseLegend(),
      style: AppSectionCardWithHeadingStyle(
        headerBottomSpacing: tokens.sectionSpacing,
      ),
      child: AppSwitchField(
        label: 'Skeleton ativo',
        helperText: 'Liga ou desliga o placeholder mantendo o mesmo layout.',
        value: skeletonEnabled,
        onChanged: onChanged,
      ),
    );
  }
}

class _FeedbackShowcaseHeading extends StatelessWidget {
  const _FeedbackShowcaseHeading({required this.theme, required this.tokens});

  final ThemeData theme;
  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'State Surfaces',
          style: theme.appTypography.utilityOverline.copyWith(
            color: cs.primary,
          ),
        ),
        SizedBox(height: tokens.gapXs),
        Row(
          children: <Widget>[
            Icon(
              Icons.notifications_active_outlined,
              color: cs.primary,
              size: 18,
            ),
            SizedBox(width: tokens.gapSm),
            Expanded(
              child: Text(
                'Feedback Patterns',
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

class _FeedbackShowcaseBadge extends StatelessWidget {
  const _FeedbackShowcaseBadge();

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

class _FeedbackShowcaseLegend extends StatelessWidget {
  const _FeedbackShowcaseLegend();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return Wrap(
      spacing: tokens.gapSm,
      runSpacing: tokens.gapSm,
      children: const <Widget>[
        _FeedbackLegendChip(label: 'Error'),
        _FeedbackLegendChip(label: 'Banner'),
        _FeedbackLegendChip(label: 'Dialog'),
        _FeedbackLegendChip(label: 'Skeleton'),
      ],
    );
  }
}

class _FeedbackLegendChip extends StatelessWidget {
  const _FeedbackLegendChip({required this.label});

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
