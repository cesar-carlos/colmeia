import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:colmeia/shared/widgets/profile/app_profile_interactive_field.dart';
import 'package:colmeia/shared/widgets/profile/app_profile_section_title.dart';
import 'package:colmeia/shared/widgets/profile/app_profile_static_field.dart';
import 'package:colmeia/shared/widgets/profile/app_profile_status_pill.dart';
import 'package:flutter/material.dart';

/// Fake profile blocks using shared profile widgets.
class AppProfileWidgetsDemoPage extends StatelessWidget {
  const AppProfileWidgetsDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;

    return ListView(
      padding: EdgeInsets.all(tokens.contentSpacing),
      children: <Widget>[
        const AppShellPageIntro(
          eyebrow: 'Perfil',
          title: 'Campos e status',
          subtitle:
              'Titulo de secao, campos estaticos, interativos e pill de '
              'status.',
        ),
        SizedBox(height: tokens.sectionSpacing),
        const AppSectionCardWithHeading(
          title: 'AppProfileSectionTitle',
          child: AppProfileSectionTitle(
            icon: Icons.badge_outlined,
            title: 'Dados da conta',
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'AppProfileStatusPill',
          subtitle: 'Cores de exemplo; backend define semantica real.',
          child: Wrap(
            spacing: tokens.gapSm,
            runSpacing: tokens.gapSm,
            children: <Widget>[
              AppProfileStatusPill(
                label: 'ATIVO',
                foreground: cs.onPrimaryContainer,
                background: cs.primaryContainer,
              ),
              AppProfileStatusPill(
                label: 'PENDENTE',
                foreground: cs.onTertiaryContainer,
                background: cs.tertiaryContainer,
              ),
              AppProfileStatusPill(
                label: 'BLOQUEADO',
                foreground: cs.onErrorContainer,
                background: cs.errorContainer,
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'AppProfileStaticField',
          subtitle: 'Somente leitura.',
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppProfileStaticField(
                label: 'ID interno',
                value: 'USR-8F2C-9910',
              ),
              AppProfileStaticField(
                label: 'Ultimo acesso',
                value: '28/03/2026 14:32',
                trailing: const Icon(Icons.lock_clock_outlined, size: 20),
              ),
              AppProfileStaticField(
                label: 'Conta em revisao',
                value: 'Aguardando aprovacao do gestor',
                valueMuted: true,
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'AppProfileInteractiveField',
          subtitle: 'Toque para feedback (fake).',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              AppProfileInteractiveField(
                label: 'Telefone',
                value: '+55 11 91234-5678',
                emphasizeValue: true,
                onTap: () => _showProfileDemoSnack(context, 'Abrir editor de telefone'),
              ),
              AppProfileInteractiveField(
                label: 'Cargo',
                value: 'Definir cargo',
                isPlaceholder: true,
                onTap: () => _showProfileDemoSnack(context, 'Escolher cargo'),
              ),
              AppProfileInteractiveField(
                label: 'Departamento',
                value: 'Operacoes',
                onTap: () => _showProfileDemoSnack(context, 'Trocar departamento'),
              ),
            ],
          ),
        ),
      ],
    );
  }

}

void _showProfileDemoSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
