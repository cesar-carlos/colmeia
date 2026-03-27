import 'dart:async';

import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

/// Perfil detalhado (Stitch: "Perfil do Usuário - Detalhado").
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _pushNotificationsEnabled = true;

  void _showSoonSnack(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = context.watch<CurrentUserContextController>();
    final authController = context.watch<AuthController>();
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;
    final scope = controller.userScope;
    final emailDisplay = scope.corporateEmail.trim().isEmpty
        ? 'Indisponível no momento'
        : scope.corporateEmail;
    final phoneDisplay = scope.phone.trim().isEmpty
        ? 'Toque para cadastrar'
        : scope.phone;

    return ListView(
      padding: EdgeInsets.all(tokens.contentSpacing),
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Colmeia BI',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  SizedBox(height: tokens.gapXs),
                  Text(
                    'Perfil',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _showSoonSnack(
                'Edição de perfil estará disponível em uma próxima versão.',
              ),
              child: const Text('Editar'),
            ),
          ],
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCard(
          color: cs.surfaceContainerLow,
          child: Column(
            children: <Widget>[
              CircleAvatar(
                radius: 44,
                backgroundColor: cs.primaryContainer,
                foregroundColor: cs.onPrimaryContainer,
                child: Text(
                  _initials(scope.name),
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(height: tokens.contentSpacing),
              Text(
                scope.name,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: tokens.gapXs),
              Text(
                scope.roleLabel,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              SizedBox(height: tokens.gapMd),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: tokens.gapSm,
                runSpacing: tokens.gapSm,
                children: <Widget>[
                  Chip(
                    avatar: Icon(
                      Icons.storefront_outlined,
                      size: 18,
                      color: cs.primary,
                    ),
                    label: Text(controller.activeStore.name),
                  ),
                  Chip(
                    label: Text(
                      '${controller.permissions.length} permissões',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (controller.errorMessage case final String errorMessage) ...<Widget>[
          SizedBox(height: tokens.sectionSpacing),
          AppSectionCard(
            color: Color.alphaBlend(
              cs.errorContainer.withValues(alpha: 0.35),
              cs.surfaceContainerLowest,
            ),
            child: Text(
              errorMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onErrorContainer,
              ),
            ),
          ),
        ],
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const _ProfileSectionTitle(
                icon: Icons.person_outline_rounded,
                title: 'Dados pessoais',
              ),
              SizedBox(height: tokens.contentSpacing),
              _ProfileInteractiveField(
                label: 'Nome completo',
                value: scope.name,
                onTap: () => _showSoonSnack(
                  'Alteração de nome será habilitada após integração com RH.',
                ),
              ),
              SizedBox(height: tokens.gapMd),
              _ProfileStaticField(
                label: 'E-mail corporativo',
                value: emailDisplay,
                trailing: Icon(
                  Icons.lock_outline_rounded,
                  size: 20,
                  color: cs.onSurfaceVariant,
                ),
              ),
              SizedBox(height: tokens.gapMd),
              _ProfileInteractiveField(
                label: 'Telefone',
                value: phoneDisplay,
                onTap: () => _showSoonSnack(
                  'Cadastro de telefone ficará disponível em breve.',
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const _ProfileSectionTitle(
                icon: Icons.security_rounded,
                title: 'Segurança',
              ),
              SizedBox(height: tokens.contentSpacing),
              _ProfileInteractiveField(
                label: 'Senha de acesso',
                value: 'Alterar senha',
                emphasizeValue: true,
                onTap: () => _showSoonSnack(
                  'Fluxo de redefinição de senha será integrado ao IAM.',
                ),
              ),
              SizedBox(height: tokens.gapMd),
              InkWell(
                onTap: () => _showSoonSnack(
                  'Gerencie o 2FA pelo portal corporativo de segurança.',
                ),
                borderRadius: BorderRadius.circular(tokens.formFieldRadius),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: tokens.gapSm),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.vibration_rounded,
                        size: 22,
                        color: cs.primary,
                      ),
                      SizedBox(width: tokens.gapMd),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Autenticação 2FA',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: tokens.gapXs),
                            Text(
                              'Camada extra para operações sensíveis.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _StatusPill(
                        label: 'ATIVO',
                        foreground: cs.onTertiaryContainer,
                        background: cs.tertiaryContainer,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const _ProfileSectionTitle(
                icon: Icons.tune_rounded,
                title: 'Preferências',
              ),
              SizedBox(height: tokens.contentSpacing),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.language_rounded, color: cs.primary),
                title: Text(
                  'Idioma',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Text(
                  'PT-BR',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              SizedBox(height: tokens.gapMd),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: Icon(
                  Icons.notifications_outlined,
                  color: cs.primary,
                ),
                title: Text(
                  'Notificações',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  'Alertas operacionais e avisos de relatório.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                value: _pushNotificationsEnabled,
                onChanged: (value) {
                  setState(() => _pushNotificationsEnabled = value);
                },
              ),
              SizedBox(height: tokens.gapMd),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.dark_mode_outlined, color: cs.primary),
                title: Text(
                  'Modo escuro',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  theme.brightness == Brightness.dark
                      ? 'Tema escuro em uso.'
                      : 'Tema claro em uso (acompanha o dispositivo).',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Permissões liberadas',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: tokens.gapMd),
              Wrap(
                spacing: tokens.gapSm,
                runSpacing: tokens.gapSm,
                children: controller.permissions
                    .map((permission) => Chip(label: Text(permission.label)))
                    .toList(growable: false),
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        SizedBox(
          width: double.infinity,
          child: FilledButton.tonalIcon(
            onPressed: authController.isLoading
                ? null
                : () {
                    unawaited(context.read<AuthController>().signOut());
                  },
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sair da conta'),
          ),
        ),
        SizedBox(height: tokens.contentSpacing),
        FutureBuilder<PackageInfo>(
          future: PackageInfo.fromPlatform(),
          builder: (context, snapshot) {
            final info = snapshot.data;
            if (info == null) {
              return const SizedBox.shrink();
            }
            return Text(
              'Versão ${info.version} (Build ${info.buildNumber})',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            );
          },
        ),
      ],
    );
  }
}

String _initials(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) {
    return '?';
  }
  final parts = trimmed.split(RegExp(r'\s+'));
  if (parts.length == 1) {
    final word = parts.single;
    return word.length >= 2
        ? word.substring(0, 2).toUpperCase()
        : word.toUpperCase();
  }
  final first = parts.first;
  final last = parts.last;
  return '${first.characters.first}${last.characters.first}'.toUpperCase();
}

class _ProfileSectionTitle extends StatelessWidget {
  const _ProfileSectionTitle({
    required this.icon,
    required this.title,
  });

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tokens = theme.extension<AppThemeTokens>()!;

    return Row(
      children: <Widget>[
        Icon(icon, size: 22, color: cs.primary),
        SizedBox(width: tokens.gapSm),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ProfileInteractiveField extends StatelessWidget {
  const _ProfileInteractiveField({
    required this.label,
    required this.value,
    required this.onTap,
    this.emphasizeValue = false,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final bool emphasizeValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(tokens.formFieldRadius),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: tokens.gapXs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: tokens.gapXs),
                    Text(
                      value,
                      style: emphasizeValue
                          ? theme.textTheme.titleSmall?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w700,
                            )
                          : theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: cs.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileStaticField extends StatelessWidget {
  const _ProfileStaticField({
    required this.label,
    required this.value,
    this.trailing,
  });

  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;
    final trailingWidget = trailing;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: tokens.gapXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: tokens.gapXs),
                Text(
                  value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ?trailingWidget,
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.foreground,
    required this.background,
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.gapSm,
        vertical: tokens.gapXs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(tokens.cardRadius),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}
