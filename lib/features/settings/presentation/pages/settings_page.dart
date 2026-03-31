import 'dart:async';

import 'package:colmeia/app/theme/app_theme_mode_controller.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/core/preferences/app_user_preferences_store.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/settings/presentation/routes/settings_routes.dart';
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/actions/app_flat_button.dart';
import 'package:colmeia/shared/widgets/app_editorial_media_card.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/app_status_badge.dart';
import 'package:colmeia/shared/widgets/app_tag_chip.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_user_initials.dart';
import 'package:colmeia/shared/widgets/navigation/app_tab_view.dart';
import 'package:colmeia/shared/widgets/navigation/show_app_sign_out_dialog.dart';
import 'package:colmeia/shared/widgets/profile/app_profile_interactive_field.dart';
import 'package:colmeia/shared/widgets/profile/app_profile_section_title.dart';
import 'package:colmeia/shared/widgets/profile/app_profile_static_field.dart';
import 'package:colmeia/shared/widgets/profile/app_profile_status_pill.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
    final typography = sheetTheme.appTypography;
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
                    style: typography.sectionHeaderH2.copyWith(
                      fontSize: sheetTheme.textTheme.titleLarge?.fontSize,
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
                    style: typography.caption.copyWith(
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
    final typography = theme.appTypography;
    final cs = theme.colorScheme;
    final scope = controller.userScope;
    final emailEmpty = scope.corporateEmail.trim().isEmpty;
    final emailDisplay = emailEmpty
        ? 'Indisponível no momento'
        : scope.corporateEmail;
    final phoneEmpty = scope.phone.trim().isEmpty;
    final phoneDisplay = phoneEmpty ? 'Toque para cadastrar' : scope.phone;

    return ListView(
      padding: context.pageScrollPadding(tokens),
      children: <Widget>[
        AppSkeleton(
          enabled: controller.isLoading,
          child: AppEditorialMediaCard(
            heroHeight: 172,
            heroBackgroundColor: cs.surfaceContainerLowest,
            title: scope.name,
            description:
                '${scope.roleLabel}. Gerencie seus dados pessoais, segurança e '
                'preferências em um único lugar.',
            footer: Wrap(
              spacing: tokens.gapSm,
              runSpacing: tokens.gapSm,
              children: <Widget>[
                AppTagChip(
                  icon: Icons.storefront_outlined,
                  label: controller.activeStore.name,
                  foregroundColor: cs.primary,
                  backgroundColor: cs.primaryContainer.withValues(
                    alpha: 0.58,
                  ),
                  borderColor: cs.primary.withValues(alpha: 0.16),
                ),
                AppTagChip(
                  label: '${controller.permissions.length} permissões',
                ),
              ],
            ),
            hero: _SettingsProfileHeroArtwork(
              initials: appShellUserInitials(scope.name),
              roleLabel: scope.roleLabel,
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
        AppSectionCardWithHeading(
          title: 'Conta',
          subtitle:
              'Dados pessoais, seguranca e preferencias organizados em abas '
              'para consulta mais rapida.',
          child: AppTabView(
            items: <AppTabViewItem>[
              AppTabViewItem(
                label: 'Dados pessoais',
                child: _SettingsProfileTab(
                  name: scope.name,
                  emailDisplay: emailDisplay,
                  emailEmpty: emailEmpty,
                  phoneDisplay: phoneDisplay,
                  phoneEmpty: phoneEmpty,
                  onNameTap: () => _showSoonSnack(
                    'Alteração de nome será habilitada após integração com RH.',
                  ),
                  onPhoneTap: () => _showSoonSnack(
                    'Cadastro de telefone ficará disponível em breve.',
                  ),
                ),
              ),
              AppTabViewItem(
                label: 'Seguranca',
                child: _SettingsSecurityTab(
                  onPasswordTap: () => _showSoonSnack(
                    'Fluxo de redefinição de senha será integrado ao IAM.',
                  ),
                  onTwoFactorTap: () => _showSoonSnack(
                    'Gerencie o 2FA pelo portal corporativo de segurança.',
                  ),
                ),
              ),
              AppTabViewItem(
                label: 'Preferencias',
                child: _SettingsPreferencesTab(
                  pushNotificationsEnabled: _pushNotificationsEnabled,
                  themePreferenceLabel: _themePreferenceLabel(themeMode),
                  onPushNotificationsChanged: _persistPushNotifications,
                  onAppearanceTap: _showThemeModePicker,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'Permissões liberadas',
          child: controller.permissions.isEmpty
              ? Text(
                  'Nenhuma permissão listada para o seu perfil neste momento. '
                  'Se precisar de acesso adicional, fale com o administrador '
                  'da sua operação.',
                  style: typography.body.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                )
              : Wrap(
                  spacing: tokens.gapSm,
                  runSpacing: tokens.gapSm,
                  children: controller.permissions
                      .map(
                        (permission) => AppTagChip(label: permission.label),
                      )
                      .toList(growable: false),
                ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSectionCardWithHeading(
          title: 'Demos de componentes',
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.widgets_outlined, color: cs.primary),
            title: Text(
              'Biblioteca de demos',
              style: typography.sectionHeaderH2.copyWith(
                fontSize: theme.textTheme.titleSmall?.fontSize,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              'Graficos, metricas, secoes e paginacao em telas separadas.',
              style: typography.caption.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: cs.onSurfaceVariant,
            ),
            onTap: () => context.push(sharedComponentsDemoIndexLocation),
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
              style: typography.caption.copyWith(
                color: cs.onSurfaceVariant,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _SettingsProfileTab extends StatelessWidget {
  const _SettingsProfileTab({
    required this.name,
    required this.emailDisplay,
    required this.emailEmpty,
    required this.phoneDisplay,
    required this.phoneEmpty,
    required this.onNameTap,
    required this.onPhoneTap,
  });

  final String name;
  final String emailDisplay;
  final bool emailEmpty;
  final String phoneDisplay;
  final bool phoneEmpty;
  final VoidCallback onNameTap;
  final VoidCallback onPhoneTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const AppProfileSectionTitle(
          icon: Icons.person_outline_rounded,
          title: 'Dados pessoais',
        ),
        SizedBox(height: tokens.contentSpacing),
        AppProfileInteractiveField(
          label: 'Nome completo',
          value: name,
          onTap: onNameTap,
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
          onTap: onPhoneTap,
        ),
      ],
    );
  }
}

class _SettingsProfileHeroArtwork extends StatelessWidget {
  const _SettingsProfileHeroArtwork({
    required this.initials,
    required this.roleLabel,
  });

  final String initials;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final cs = theme.colorScheme;

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Positioned(
          left: -28,
          top: 8,
          bottom: 18,
          width: 124,
          child: Transform.rotate(
            angle: -0.18,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: cs.tertiary.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(tokens.cardRadius + 8),
              ),
            ),
          ),
        ),
        Positioned(
          right: -34,
          top: -10,
          bottom: 8,
          width: 146,
          child: Transform.rotate(
            angle: 0.22,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: cs.tertiary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(tokens.cardRadius + 12),
              ),
            ),
          ),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              CircleAvatar(
                radius: 42,
                backgroundColor: cs.primaryContainer,
                foregroundColor: cs.onPrimaryContainer,
                child: Text(
                  initials,
                  style: typography.displayH1.copyWith(
                    fontSize: theme.textTheme.headlineSmall?.fontSize,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(height: tokens.gapSm),
              Text(
                'ACCOUNT',
                style: typography.utilityOverline.copyWith(
                  color: cs.primary,
                ),
              ),
              SizedBox(height: tokens.gapXs),
              Text(
                roleLabel,
                textAlign: TextAlign.center,
                style: typography.caption.copyWith(
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

class _SettingsSecurityTab extends StatelessWidget {
  const _SettingsSecurityTab({
    required this.onPasswordTap,
    required this.onTwoFactorTap,
  });

  final VoidCallback onPasswordTap;
  final VoidCallback onTwoFactorTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final cs = theme.colorScheme;

    return Column(
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
          onTap: onPasswordTap,
        ),
        SizedBox(height: tokens.gapMd),
        InkWell(
          onTap: onTwoFactorTap,
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
                        style: typography.sectionHeaderH2.copyWith(
                          fontSize: theme.textTheme.titleSmall?.fontSize,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: tokens.gapXs),
                      Text(
                        'Camada extra para operações sensíveis.',
                        style: typography.caption.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const AppProfileStatusPill(
                  label: 'ATIVO',
                  variant: AppStatusBadgeVariant.success,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsPreferencesTab extends StatelessWidget {
  const _SettingsPreferencesTab({
    required this.pushNotificationsEnabled,
    required this.themePreferenceLabel,
    required this.onPushNotificationsChanged,
    required this.onAppearanceTap,
  });

  final bool pushNotificationsEnabled;
  final String themePreferenceLabel;
  final ValueChanged<bool> onPushNotificationsChanged;
  final VoidCallback onAppearanceTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final cs = theme.colorScheme;

    return Column(
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
            style: typography.sectionHeaderH2.copyWith(
              fontSize: theme.textTheme.titleSmall?.fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: Text(
            'PT-BR',
            style: typography.utilityOverline.copyWith(
              color: cs.onSurfaceVariant,
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
            style: typography.sectionHeaderH2.copyWith(
              fontSize: theme.textTheme.titleSmall?.fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            'Preferência salva neste aparelho.',
            style: typography.caption.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          value: pushNotificationsEnabled,
          onChanged: onPushNotificationsChanged,
        ),
        SizedBox(height: tokens.gapMd),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.dark_mode_outlined, color: cs.primary),
          title: Text(
            'Aparência',
            style: typography.sectionHeaderH2.copyWith(
              fontSize: theme.textTheme.titleSmall?.fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            themePreferenceLabel,
            style: typography.caption.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: cs.onSurfaceVariant,
          ),
          onTap: onAppearanceTap,
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
