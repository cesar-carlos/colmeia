import 'dart:async';

import 'package:colmeia/app/theme/app_theme_mode_controller.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/preferences/app_user_preferences_store.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/actions/app_flat_button.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/navigation/show_app_sign_out_dialog.dart';
import 'package:colmeia/shared/widgets/profile/app_profile_interactive_field.dart';
import 'package:colmeia/shared/widgets/profile/app_profile_section_title.dart';
import 'package:colmeia/shared/widgets/profile/app_profile_static_field.dart';
import 'package:colmeia/shared/widgets/profile/app_profile_status_pill.dart';
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
  late bool _pushNotificationsEnabled;

  @override
  void initState() {
    super.initState();
    _pushNotificationsEnabled =
        getIt<AppUserPreferencesStore>().pushNotificationsEnabled;
  }

  Future<void> _persistPushNotifications(bool value) async {
    await getIt<AppUserPreferencesStore>().setPushNotificationsEnabled(
      enabled: value,
    );
    if (mounted) {
      setState(() => _pushNotificationsEnabled = value);
    }
  }

  void _showSoonSnack(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showThemeModePicker() async {
    final themeCtrl = context.read<AppThemeModeController>();
    final rootContext = context;
    final sheetTheme = Theme.of(rootContext);
    final tokens = sheetTheme.extension<AppThemeTokens>()!;
    final cs = sheetTheme.colorScheme;

    await showModalBottomSheet<void>(
      context: rootContext,
      showDragHandle: true,
      builder: (sheetContext) {
        Widget option(ThemeMode mode, String title, String subtitle) {
          final selected = themeCtrl.themeMode == mode;
          return ListTile(
            leading: Icon(
              selected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: selected ? cs.primary : cs.onSurfaceVariant,
            ),
            title: Text(title),
            subtitle: Text(subtitle),
            onTap: () {
              unawaited(themeCtrl.setThemeMode(mode));
              Navigator.of(sheetContext).pop();
            },
          );
        }

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(bottom: tokens.gapMd),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    tokens.contentSpacing,
                    tokens.gapSm,
                    tokens.contentSpacing,
                    tokens.gapXs,
                  ),
                  child: Text(
                    'Tema do app',
                    style: sheetTheme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: tokens.contentSpacing,
                  ),
                  child: Text(
                    'Escolha se o app segue o sistema ou usa um tema fixo.',
                    style: sheetTheme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                SizedBox(height: tokens.gapSm),
                option(
                  ThemeMode.system,
                  'Sistema',
                  'Mesmo tema do dispositivo (claro ou escuro).',
                ),
                option(
                  ThemeMode.light,
                  'Claro',
                  'Sempre interface clara.',
                ),
                option(
                  ThemeMode.dark,
                  'Escuro',
                  'Sempre interface escura.',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = context.watch<CurrentUserContextController>();
    final authController = context.watch<AuthController>();
    final themeMode = context.watch<AppThemeModeController>().themeMode;
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;
    final scope = controller.userScope;
    final emailEmpty = scope.corporateEmail.trim().isEmpty;
    final emailDisplay = emailEmpty
        ? 'Indisponível no momento'
        : scope.corporateEmail;
    final phoneEmpty = scope.phone.trim().isEmpty;
    final phoneDisplay = phoneEmpty ? 'Toque para cadastrar' : scope.phone;

    return ListView(
      padding: EdgeInsets.all(tokens.contentSpacing),
      children: <Widget>[
        AppSkeleton(
          enabled: controller.isLoading,
          child: AppSectionCard(
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
        ),
        if (controller.errorMessage case final String errorMessage) ...<Widget>[
          SizedBox(height: tokens.sectionSpacing),
          AppInlineErrorPanel(
            title: 'Nao foi possivel carregar o perfil',
            message: errorMessage,
            onRetry: () {
              unawaited(controller.reloadUserContext());
            },
          ),
        ],
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const AppProfileSectionTitle(
                icon: Icons.person_outline_rounded,
                title: 'Dados pessoais',
              ),
              SizedBox(height: tokens.contentSpacing),
              AppProfileInteractiveField(
                label: 'Nome completo',
                value: scope.name,
                onTap: () => _showSoonSnack(
                  'Alteração de nome será habilitada após integração com RH.',
                ),
              ),
              SizedBox(height: tokens.gapMd),
              AppProfileStaticField(
                label: 'E-mail corporativo',
                value: emailDisplay,
                valueMuted: emailEmpty,
                trailing: Icon(
                  Icons.lock_outline_rounded,
                  size: 20,
                  color: cs.onSurfaceVariant,
                ),
              ),
              SizedBox(height: tokens.gapMd),
              AppProfileInteractiveField(
                label: 'Telefone',
                value: phoneDisplay,
                isPlaceholder: phoneEmpty,
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
              const AppProfileSectionTitle(
                icon: Icons.security_rounded,
                title: 'Segurança',
              ),
              SizedBox(height: tokens.contentSpacing),
              AppProfileInteractiveField(
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
                      AppProfileStatusPill(
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
              const AppProfileSectionTitle(
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
                  'Preferência salva neste aparelho.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                value: _pushNotificationsEnabled,
                onChanged: _persistPushNotifications,
              ),
              SizedBox(height: tokens.gapMd),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.dark_mode_outlined, color: cs.primary),
                title: Text(
                  'Aparência',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  _themePreferenceLabel(themeMode),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: cs.onSurfaceVariant,
                ),
                onTap: _showThemeModePicker,
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
              if (controller.permissions.isEmpty)
                Text(
                  'Nenhuma permissão listada para o seu perfil neste momento. '
                  'Se precisar de acesso adicional, fale com o administrador '
                  'da sua operação.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                )
              else
                Wrap(
                  spacing: tokens.gapSm,
                  runSpacing: tokens.gapSm,
                  children: controller.permissions
                      .map(
                        (permission) => Chip(label: Text(permission.label)),
                      )
                      .toList(growable: false),
                ),
            ],
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppFlatButton(
          icon: const Icon(Icons.logout_rounded),
          label: 'Sair da conta',
          semanticsLabel: 'Sair da conta',
          onPressed: authController.isLoading
              ? null
              : () async {
                  final confirmed = await showAppSignOutConfirmDialog(context);
                  if (!context.mounted || !confirmed) {
                    return;
                  }
                  await context.read<AuthController>().signOut();
                },
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

String _themePreferenceLabel(ThemeMode mode) {
  return switch (mode) {
    ThemeMode.system => 'Seguindo o dispositivo.',
    ThemeMode.light => 'Tema claro fixo.',
    ThemeMode.dark => 'Tema escuro fixo.',
  };
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
  final a = first.runes.isEmpty ? 0x3f : first.runes.first;
  final b = last.runes.isEmpty ? 0x3f : last.runes.first;
  return '${String.fromCharCode(a)}${String.fromCharCode(b)}'.toUpperCase();
}
