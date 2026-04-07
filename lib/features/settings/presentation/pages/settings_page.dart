import 'dart:async';

import 'package:colmeia/app/theme/app_theme_mode_controller.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/core/preferences/app_user_preferences_store.dart';
import 'package:colmeia/features/auth/application/usecases/change_password_use_case.dart';
import 'package:colmeia/features/auth/application/usecases/update_current_user_profile_use_case.dart';
import 'package:colmeia/features/auth/application/usecases/upload_client_thumbnail_use_case.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/auth/presentation/widgets/auth_form_text_field.dart';
import 'package:colmeia/features/auth/presentation/widgets/auth_password_text_field.dart';
import 'package:colmeia/features/settings/presentation/controllers/client_account_settings_controller.dart';
import 'package:colmeia/features/settings/presentation/routes/settings_routes.dart';
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';
import 'package:colmeia/features/user_context/presentation/localization/user_permission_l10n.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/forms/app_form_validators.dart';
import 'package:colmeia/shared/widgets/actions/app_flat_button.dart';
import 'package:colmeia/shared/widgets/actions/app_primary_button.dart';
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
import 'package:image_picker/image_picker.dart';
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
  late final ClientAccountSettingsController _accountSettingsController;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _pushNotificationsEnabled =
        getIt<AppUserPreferencesStore>().pushNotificationsEnabled;
    _accountSettingsController = ClientAccountSettingsController(
      updateCurrentUserProfileUseCase: getIt<UpdateCurrentUserProfileUseCase>(),
      uploadClientThumbnailUseCase: getIt<UploadClientThumbnailUseCase>(),
      changePasswordUseCase: getIt<ChangePasswordUseCase>(),
    );
  }

  @override
  void dispose() {
    _accountSettingsController.dispose();
    super.dispose();
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
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _evictThumbnailCache(String? thumbnailUrl) async {
    final resolvedUrl = thumbnailUrl?.trim();
    if (resolvedUrl == null || resolvedUrl.isEmpty) {
      return;
    }

    imageCache.evict(NetworkImage(resolvedUrl));
  }

  Future<void> _showEditProfileSheet(
    CurrentUserContextController userContextController,
  ) async {
    final scope = userContextController.userScope;
    final firstNameController = TextEditingController(text: scope.firstName);
    final lastNameController = TextEditingController(text: scope.lastName);
    final phoneController = TextEditingController(text: scope.phone);
    final formKey = GlobalKey<FormState>();
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    _accountSettingsController.clearFeedback();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return ListenableBuilder(
          listenable: _accountSettingsController,
          builder: (context, _) {
            final isSaving = _accountSettingsController.isSavingProfile;
            final errorMessage = _accountSettingsController.errorMessage;

            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                tokens.contentSpacing,
                0,
                tokens.contentSpacing,
                MediaQuery.viewInsetsOf(sheetContext).bottom +
                    tokens.contentSpacing,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    if (errorMessage != null) ...<Widget>[
                      AppInlineErrorPanel(
                        title: 'Nao foi possivel salvar',
                        message: errorMessage,
                        variant: AppInlineErrorPanelVariant.plain,
                      ),
                      SizedBox(height: tokens.contentSpacing),
                    ],
                    AuthFormTextField(
                      controller: firstNameController,
                      enabled: !isSaving,
                      label: 'Nome',
                      icon: Icons.person_outline_rounded,
                      validator: (value) => AppFormValidators.requiredText(
                        value,
                        message: 'Informe seu nome.',
                      ),
                    ),
                    SizedBox(height: tokens.gapMd),
                    AuthFormTextField(
                      controller: lastNameController,
                      enabled: !isSaving,
                      label: 'Sobrenome',
                      icon: Icons.badge_outlined,
                      validator: (value) => AppFormValidators.requiredText(
                        value,
                        message: 'Informe seu sobrenome.',
                      ),
                    ),
                    SizedBox(height: tokens.gapMd),
                    AuthFormTextField(
                      controller: phoneController,
                      enabled: !isSaving,
                      label: 'Telefone',
                      icon: Icons.phone_android_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: tokens.contentSpacing),
                    AppPrimaryButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) {
                          return;
                        }
                        final success = await _accountSettingsController
                            .updateProfile(
                              firstName: firstNameController.text.trim(),
                              lastName: lastNameController.text.trim(),
                              mobile: phoneController.text.trim(),
                            );
                        if (!mounted || !sheetContext.mounted) {
                          return;
                        }
                        if (!success) {
                          return;
                        }

                        Navigator.of(sheetContext).pop();
                        await userContextController.reloadUserContext();
                        _showSoonSnack(
                          _accountSettingsController.successMessage ??
                              'Conta atualizada com sucesso.',
                        );
                      },
                      label: 'Salvar alteracoes',
                      fillWidth: true,
                      isLoading: isSaving,
                      showLabelWhileLoading: true,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
  }

  Future<void> _showChangePasswordSheet() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    var obscureCurrent = true;
    var obscureNext = true;
    var obscureConfirm = true;
    _accountSettingsController.clearFeedback();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return ListenableBuilder(
              listenable: _accountSettingsController,
              builder: (context, _) {
                final isChanging =
                    _accountSettingsController.isChangingPassword;
                final errorMessage = _accountSettingsController.errorMessage;

                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    tokens.contentSpacing,
                    0,
                    tokens.contentSpacing,
                    MediaQuery.viewInsetsOf(sheetContext).bottom +
                        tokens.contentSpacing,
                  ),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        if (errorMessage != null) ...<Widget>[
                          AppInlineErrorPanel(
                            title: 'Nao foi possivel atualizar a senha',
                            message: errorMessage,
                            variant: AppInlineErrorPanelVariant.plain,
                          ),
                          SizedBox(height: tokens.contentSpacing),
                        ],
                        AuthPasswordTextField(
                          controller: currentPasswordController,
                          obscureText: obscureCurrent,
                          enabled: !isChanging,
                          onToggleObscure: () {
                            setSheetState(() {
                              obscureCurrent = !obscureCurrent;
                            });
                          },
                          label: 'Senha atual',
                          icon: Icons.lock_clock_outlined,
                        ),
                        SizedBox(height: tokens.gapMd),
                        AuthPasswordTextField(
                          controller: newPasswordController,
                          obscureText: obscureNext,
                          enabled: !isChanging,
                          onToggleObscure: () {
                            setSheetState(() {
                              obscureNext = !obscureNext;
                            });
                          },
                          label: 'Nova senha',
                          icon: Icons.lock_outline_rounded,
                          validator: (value) =>
                              AppFormValidators.password(value, minLength: 8),
                        ),
                        SizedBox(height: tokens.gapMd),
                        AuthPasswordTextField(
                          controller: confirmPasswordController,
                          obscureText: obscureConfirm,
                          enabled: !isChanging,
                          onToggleObscure: () {
                            setSheetState(() {
                              obscureConfirm = !obscureConfirm;
                            });
                          },
                          label: 'Confirmar nova senha',
                          icon: Icons.lock_reset_outlined,
                          validator: (value) =>
                              AppFormValidators.confirmPassword(
                                value,
                                password: newPasswordController.text,
                              ),
                        ),
                        SizedBox(height: tokens.contentSpacing),
                        AppPrimaryButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) {
                              return;
                            }
                            final success = await _accountSettingsController
                                .changePassword(
                                  currentPassword:
                                      currentPasswordController.text,
                                  newPassword: newPasswordController.text,
                                );
                            if (!mounted || !sheetContext.mounted) {
                              return;
                            }
                            if (!success) {
                              return;
                            }

                            Navigator.of(sheetContext).pop();
                            _showSoonSnack(
                              _accountSettingsController.successMessage ??
                                  'Senha alterada com sucesso.',
                            );
                          },
                          label: 'Atualizar senha',
                          fillWidth: true,
                          isLoading: isChanging,
                          showLabelWhileLoading: true,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );

    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  Future<void> _showThumbnailActions(
    CurrentUserContextController userContextController,
  ) async {
    final scope = userContextController.userScope;
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    _accountSettingsController.clearFeedback();

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(bottom: tokens.gapMd),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: Text(
                    scope.thumbnailUrl == null
                        ? 'Adicionar foto do perfil'
                        : 'Atualizar foto do perfil',
                  ),
                  onTap: () async {
                    Navigator.of(sheetContext).pop();
                    final file = await _imagePicker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 85,
                      maxWidth: 1200,
                    );
                    if (file == null || !mounted) {
                      return;
                    }
                    _showSoonSnack('Enviando foto do perfil...');
                    final success = await _accountSettingsController
                        .uploadThumbnail(filePath: file.path);
                    if (!mounted) {
                      return;
                    }
                    if (!success) {
                      _showSoonSnack(
                        _accountSettingsController.errorMessage ??
                            'Nao foi possivel enviar a foto.',
                      );
                      return;
                    }

                    await _evictThumbnailCache(scope.thumbnailUrl);
                    await userContextController.reloadUserContext();
                    _showSoonSnack(
                      _accountSettingsController.successMessage ??
                          'Foto atualizada com sucesso.',
                    );
                  },
                ),
                if (scope.thumbnailUrl != null)
                  ListTile(
                    leading: const Icon(Icons.delete_outline_rounded),
                    title: const Text('Remover foto'),
                    onTap: () async {
                      Navigator.of(sheetContext).pop();
                      final success = await _accountSettingsController
                          .updateProfile(
                            firstName: scope.firstName,
                            lastName: scope.lastName,
                            mobile: scope.phone,
                            removeThumbnail: true,
                          );
                      if (!mounted) {
                        return;
                      }
                      if (!success) {
                        _showSoonSnack(
                          _accountSettingsController.errorMessage ??
                              'Nao foi possivel remover a foto.',
                        );
                        return;
                      }

                      await _evictThumbnailCache(scope.thumbnailUrl);
                      await userContextController.reloadUserContext();
                      _showSoonSnack(
                        _accountSettingsController.successMessage ??
                            'Foto removida com sucesso.',
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
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
    final l10n = AppLocalizations.of(context);
    final emailEmpty = scope.corporateEmail.trim().isEmpty;
    final emailDisplay = emailEmpty
        ? 'Indisponível no momento'
        : scope.corporateEmail;
    final phoneEmpty = scope.phone.trim().isEmpty;
    final phoneDisplay = phoneEmpty ? 'Não informado' : scope.phone;

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
                '${scope.roleLabel}. Consulte os dados da sua conta, segurança '
                'e preferências em um único lugar.',
            footer: Wrap(
              spacing: tokens.gapSm,
              runSpacing: tokens.gapSm,
              children: <Widget>[
                AppTagChip(
                  icon: Icons.verified_user_outlined,
                  label: scope.roleLabel,
                  foregroundColor: cs.primary,
                  backgroundColor: cs.primaryContainer.withValues(
                    alpha: 0.58,
                  ),
                  borderColor: cs.primary.withValues(alpha: 0.16),
                ),
                AppTagChip(
                  label: authController.isAuthenticated
                      ? 'Sessão ativa'
                      : 'Sessão indisponível',
                ),
              ],
            ),
            hero: _SettingsProfileHeroArtwork(
              initials: appShellUserInitials(scope.name),
              roleLabel: scope.roleLabel,
              thumbnailUrl: scope.thumbnailUrl,
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
        AppSkeleton(
          enabled: controller.isLoading,
          child: AppSectionCardWithHeading(
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
                    thumbnailActionLabel: scope.thumbnailUrl == null
                        ? 'Adicionar foto'
                        : 'Atualizar foto',
                    onNameTap: () => _showEditProfileSheet(controller),
                    onPhoneTap: () => _showEditProfileSheet(controller),
                    onThumbnailTap: () => _showThumbnailActions(controller),
                  ),
                ),
                AppTabViewItem(
                  label: 'Seguranca',
                  child: _SettingsSecurityTab(
                    onPasswordTap: _showChangePasswordSheet,
                  ),
                ),
                AppTabViewItem(
                  label: 'Preferencias',
                  child: _SettingsPreferencesTab(
                    pushNotificationsEnabled: _pushNotificationsEnabled,
                    themePreferenceLabel: _themePreferenceLabel(themeMode),
                    onPushNotificationsChanged: _persistPushNotifications,
                    onAppearanceTap: _showThemeModePicker,
                    onComponentsTap: () => context.push(
                      sharedComponentsDemoIndexLocation,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
        AppSkeleton(
          enabled: controller.isLoading,
          child: AppSectionCardWithHeading(
            title: 'Estado da conta',
            child: controller.permissions.isEmpty
                ? Text(
                    'As permissoes detalhadas desta conta ainda nao foram '
                    'disponibilizadas pela API. O acesso funcional continua '
                    'sendo validado pelo backend.',
                    style: typography.body.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  )
                : Wrap(
                    spacing: tokens.gapSm,
                    runSpacing: tokens.gapSm,
                    children: controller.permissions
                        .map(
                          (permission) => AppTagChip(
                            label: permission.displayLabel(l10n),
                          ),
                        )
                        .toList(growable: false),
                  ),
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
    required this.thumbnailActionLabel,
    required this.onNameTap,
    required this.onPhoneTap,
    required this.onThumbnailTap,
  });

  final String name;
  final String emailDisplay;
  final bool emailEmpty;
  final String phoneDisplay;
  final bool phoneEmpty;
  final String thumbnailActionLabel;
  final VoidCallback onNameTap;
  final VoidCallback onPhoneTap;
  final VoidCallback onThumbnailTap;

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
        SizedBox(height: tokens.gapMd),
        AppProfileInteractiveField(
          label: 'Foto da conta',
          value: thumbnailActionLabel,
          emphasizeValue: true,
          onTap: onThumbnailTap,
        ),
      ],
    );
  }
}

class _SettingsProfileHeroArtwork extends StatelessWidget {
  const _SettingsProfileHeroArtwork({
    required this.initials,
    required this.roleLabel,
    this.thumbnailUrl,
  });

  final String initials;
  final String roleLabel;
  final String? thumbnailUrl;

  bool get _hasThumbnail => thumbnailUrl?.trim().isNotEmpty ?? false;

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
              Container(
                width: 84,
                height: 84,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: _hasThumbnail
                    ? Image.network(
                        thumbnailUrl!.trim(),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _SettingsProfileAvatarFallback(
                            initials: initials,
                          );
                        },
                        loadingBuilder: (context, child, progress) {
                          if (progress == null) {
                            return child;
                          }
                          return Center(
                            child: CircularProgressIndicator(
                              color: cs.primary,
                              strokeWidth: 2,
                            ),
                          );
                        },
                      )
                    : _SettingsProfileAvatarFallback(initials: initials),
              ),
              SizedBox(height: tokens.gapSm),
              Text(
                'CONTA',
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
  });

  final VoidCallback onPasswordTap;

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
        Padding(
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
                      'Disponível assim que o backend expuser a configuração '
                      'deste recurso.',
                      style: typography.caption.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const AppProfileStatusPill(
                label: 'EM BREVE',
                variant: AppStatusBadgeVariant.info,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsProfileAvatarFallback extends StatelessWidget {
  const _SettingsProfileAvatarFallback({
    required this.initials,
  });

  final String initials;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typography = theme.appTypography;
    final cs = theme.colorScheme;

    return Center(
      child: Text(
        initials,
        style: typography.displayH1.copyWith(
          color: cs.onPrimaryContainer,
          fontSize: theme.textTheme.headlineSmall?.fontSize,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SettingsPreferencesTab extends StatelessWidget {
  const _SettingsPreferencesTab({
    required this.pushNotificationsEnabled,
    required this.themePreferenceLabel,
    required this.onPushNotificationsChanged,
    required this.onAppearanceTap,
    required this.onComponentsTap,
  });

  final bool pushNotificationsEnabled;
  final String themePreferenceLabel;
  final ValueChanged<bool> onPushNotificationsChanged;
  final VoidCallback onAppearanceTap;
  final VoidCallback onComponentsTap;

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
        SizedBox(height: tokens.gapMd),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.widgets_outlined, color: cs.primary),
          title: Text(
            'Componentes do app',
            style: typography.sectionHeaderH2.copyWith(
              fontSize: theme.textTheme.titleSmall?.fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            'Abrir catalogo com os componentes e demos disponiveis para uso.',
            style: typography.caption.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          trailing: Icon(
            Icons.chevron_right_rounded,
            color: cs.onSurfaceVariant,
          ),
          onTap: onComponentsTap,
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
