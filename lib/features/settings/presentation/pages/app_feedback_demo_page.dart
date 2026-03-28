import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/feedback/inline_alert_banner.dart';
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
        AppSectionCardWithHeading(
          title: 'AppInlineErrorPanel',
          subtitle: 'Card com titulo e acao; plain sem cartao.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const AppInlineErrorPanel(
                title: 'Nao foi possivel sincronizar',
                message: 'Verifique a conexao e tente novamente. '
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
          title: 'AppSkeleton',
          subtitle: 'Ative ou desative o efeito para comparar.',
          headingBottom: SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Skeleton ativo'),
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
