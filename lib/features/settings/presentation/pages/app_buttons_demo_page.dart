import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
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
        AppSectionCardWithHeading(
          title: 'AppPrimaryButton',
          subtitle: 'Filled principal.',
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
          subtitle: 'Outlined.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppSecondaryButton(
                label: 'Cancelar',
                onPressed: () => showTap('Secondary padrao'),
              ),
              SizedBox(height: tokens.gapSm),
              AppSecondaryButton(
                label: 'Exportar',
                icon: const Icon(Icons.ios_share_outlined),
                onPressed: () => showTap('Secondary com icone'),
              ),
              SizedBox(height: tokens.gapSm),
              const AppSecondaryButton(
                label: 'Desabilitado',
                onPressed: null,
              ),
              SizedBox(height: tokens.gapSm),
              AppSecondaryButton(
                isLoading: true,
                onPressed: () => showTap('Secondary loading'),
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'AppFlatButton',
          subtitle: 'Tonal, bom para drawer e barras densas.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppFlatButton(
                label: 'Acao secundaria',
                onPressed: () => showTap('Flat padrao'),
              ),
              SizedBox(height: tokens.gapSm),
              AppFlatButton(
                label: 'Com icone',
                icon: const Icon(Icons.widgets_outlined),
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
