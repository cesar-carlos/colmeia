import 'dart:async';

import 'package:colmeia/app/router/app_navigation.dart';

import 'package:colmeia/app/router/app_routes.dart';

import 'package:colmeia/features/auth/domain/entities/client_registration_status.dart';

import 'package:colmeia/features/auth/presentation/controllers/registration_status_page_controller.dart';

import 'package:colmeia/features/auth/presentation/helpers/auth_registration_failure_mapper.dart';

import 'package:colmeia/features/auth/presentation/widgets/auth_email_text_field.dart';

import 'package:colmeia/features/auth/presentation/widgets/auth_form_text_field.dart';

import 'package:colmeia/features/auth/presentation/widgets/auth_password_text_field.dart';

import 'package:colmeia/features/auth/presentation/widgets/login/login_brand_header.dart';

import 'package:colmeia/features/auth/presentation/widgets/login/login_footer.dart';

import 'package:colmeia/features/auth/presentation/widgets/login/login_glass_card.dart';

import 'package:colmeia/features/auth/presentation/widgets/login/login_primary_button.dart';

import 'package:colmeia/l10n/app_localizations.dart';

import 'package:colmeia/shared/design_system/app_theme_tokens.dart';

import 'package:colmeia/shared/forms/app_form_validators.dart';

import 'package:colmeia/shared/forms/registration_form_policy.dart';

import 'package:colmeia/shared/widgets/backgrounds/app_hex_screen_body.dart';

import 'package:colmeia/shared/widgets/feedback/inline_alert_banner.dart';

import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

class RegistrationStatusPage extends StatelessWidget {
  const RegistrationStatusPage({
    required this.controller,

    super.key,
  });

  final RegistrationStatusPageController controller;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => controller,

      child: const _RegistrationStatusPageBody(),
    );
  }
}

class _RegistrationStatusPageBody extends StatefulWidget {
  const _RegistrationStatusPageBody();

  @override
  State<_RegistrationStatusPageBody> createState() =>
      _RegistrationStatusPageBodyState();
}

class _RegistrationStatusPageBodyState
    extends State<_RegistrationStatusPageBody> {
  late final TextEditingController _tokenController;

  final GlobalKey<FormState> _retryFormKey = GlobalKey<FormState>();

  final TextEditingController _retryOwnerEmailController =
      TextEditingController();

  final TextEditingController _retryEmailController = TextEditingController();

  final TextEditingController _retryPasswordController =
      TextEditingController();

  final ValueNotifier<bool> _obscureRetryPassword = ValueNotifier(true);

  @override
  void initState() {
    super.initState();

    final pageController = context.read<RegistrationStatusPageController>();

    _tokenController = TextEditingController(text: pageController.token);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }

      final controller = context.read<RegistrationStatusPageController>();

      await controller.loadStoredPollToken();

      if (!mounted) {
        return;
      }

      if (controller.token.isNotEmpty) {
        _tokenController.text = controller.token;

        final l10n = AppLocalizations.of(context);

        await controller.loadStatus(
          emptyTokenMessage: l10n.authRegistrationStatusTokenRequired,

          invalidTokenMessage: l10n.authRegistrationStatusTokenInvalid,

          mapFailure: (failure) => mapAuthRegistrationFailure(failure, l10n),
        );
      }
    });
  }

  @override
  void dispose() {
    _tokenController.dispose();

    _retryOwnerEmailController.dispose();

    _retryEmailController.dispose();

    _retryPasswordController.dispose();

    _obscureRetryPassword.dispose();

    super.dispose();
  }

  Future<void> _loadStatus(RegistrationStatusPageController controller) async {
    final l10n = AppLocalizations.of(context);

    controller.setToken(_tokenController.text);

    await controller.loadStatus(
      emptyTokenMessage: l10n.authRegistrationStatusTokenRequired,

      invalidTokenMessage: l10n.authRegistrationStatusTokenInvalid,

      mapFailure: (failure) => mapAuthRegistrationFailure(failure, l10n),
    );
  }

  Future<void> _submitRetry(RegistrationStatusPageController controller) async {
    if (!_retryFormKey.currentState!.validate()) {
      return;
    }

    final l10n = AppLocalizations.of(context);

    await controller.retryRegistration(
      ownerEmail: _retryOwnerEmailController.text,

      email: _retryEmailController.text,

      password: _retryPasswordController.text,

      genericSuccessMessage: l10n.authRegistrationRetryGenericSuccess,

      emptyTokenMessage: l10n.authRegistrationStatusTokenRequired,

      invalidTokenMessage: l10n.authRegistrationStatusTokenInvalid,

      mapFailure: (failure) => mapAuthRegistrationFailure(failure, l10n),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RegistrationStatusPageController>();

    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    final theme = Theme.of(context);

    final l10n = AppLocalizations.of(context);

    final status = controller.status;

    return Scaffold(
      body: AppHexScreenBody(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: tokens.authLoginScrollPaddingHorizontal,

            vertical: tokens.authLoginScrollPaddingVertical,
          ),

          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: tokens.authLoginContentMaxWidth,
              ),

              child: Column(
                children: <Widget>[
                  const LoginBrandHeader(),

                  SizedBox(height: tokens.authLoginGapBrandToForm),

                  LoginGlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: <Widget>[
                        Text(
                          l10n.authRegistrationStatusTitle,

                          style: theme.textTheme.headlineSmall,
                        ),

                        SizedBox(height: tokens.gapSm),

                        Text(
                          l10n.authRegistrationStatusSubtitle,

                          style: theme.textTheme.bodyMedium,
                        ),

                        SizedBox(height: tokens.authLoginGapMajorSection),

                        AuthFormTextField(
                          controller: _tokenController,

                          label: l10n.authRegistrationStatusTokenLabel,

                          icon: Icons.vpn_key_outlined,

                          enabled: !controller.isLoading,

                          semanticsLabel: l10n.authRegistrationStatusTokenLabel,

                          validator: (value) =>
                              AppFormValidators.registrationPollToken(
                                value,

                                emptyMessage:
                                    l10n.authRegistrationStatusTokenRequired,

                                invalidMessage:
                                    l10n.authRegistrationStatusTokenInvalid,
                              ),

                          onFieldSubmitted: (_) =>
                              unawaited(_loadStatus(controller)),
                        ),

                        SizedBox(height: tokens.gapSm),

                        LoginPrimaryButton(
                          label: l10n.authRegistrationStatusSubmitButton,

                          isLoading: controller.isLoading,

                          onPressed: controller.isLoading
                              ? null
                              : () => unawaited(_loadStatus(controller)),
                        ),

                        if (controller.errorMessage
                            case final String message) ...<Widget>[
                          SizedBox(height: tokens.contentSpacing),

                          InlineAlertBanner(message: message),
                        ],

                        if (controller.successMessage
                            case final String message) ...<Widget>[
                          SizedBox(height: tokens.contentSpacing),

                          InlineAlertBanner(
                            kind: InlineAlertBannerKind.success,

                            message: message,
                          ),
                        ],

                        if (status != null) ...<Widget>[
                          SizedBox(height: tokens.authLoginGapMajorSection),

                          _RegistrationStatusCard(
                            status: status,

                            l10n: l10n,
                          ),

                          if (status ==
                              ClientRegistrationStatus.approved) ...<Widget>[
                            SizedBox(height: tokens.gapSm),

                            Text(
                              l10n.authRegistrationApprovedAgentAccessNote,

                              style: theme.textTheme.bodySmall,
                            ),

                            SizedBox(height: tokens.gapSm),

                            LoginPrimaryButton(
                              label: l10n.authRegistrationApprovedSignInNow,

                              onPressed: () => context.goTo(AppRoute.login),
                            ),
                          ],
                        ],

                        if (controller.canRetry) ...<Widget>[
                          SizedBox(height: tokens.authLoginGapMajorSection),

                          Text(
                            l10n.authRegistrationRetryPrompt,

                            style: theme.textTheme.bodyMedium,
                          ),

                          SizedBox(height: tokens.gapSm),

                          if (!controller.showRetryForm)
                            OutlinedButton(
                              onPressed: controller.isRetrying
                                  ? null
                                  : controller.toggleRetryForm,

                              child: Text(l10n.authRegistrationRetryAction),
                            )
                          else ...<Widget>[
                            Form(
                              key: _retryFormKey,

                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,

                                children: <Widget>[
                                  AuthEmailTextField(
                                    controller: _retryOwnerEmailController,

                                    label: l10n.authRegisterOwnerEmailLabel,

                                    icon: Icons.supervisor_account_outlined,

                                    enabled: !controller.isRetrying,

                                    emptyMessage:
                                        l10n.authRegisterOwnerEmailRequired,

                                    invalidMessage: l10n.authEmailFieldInvalid,

                                    semanticsLabel:
                                        l10n.authRegisterOwnerEmailLabel,
                                  ),

                                  SizedBox(
                                    height: tokens.authLoginGapBetweenFields,
                                  ),

                                  AuthEmailTextField(
                                    controller: _retryEmailController,

                                    label: l10n.authRegisterAccountEmailLabel,

                                    icon: Icons.alternate_email,

                                    enabled: !controller.isRetrying,

                                    emptyMessage:
                                        l10n.authRegisterAccountEmailRequired,

                                    invalidMessage: l10n.authEmailFieldInvalid,

                                    semanticsLabel:
                                        l10n.authRegisterAccountEmailLabel,
                                  ),

                                  SizedBox(
                                    height: tokens.authLoginGapBetweenFields,
                                  ),

                                  ValueListenableBuilder<bool>(
                                    valueListenable: _obscureRetryPassword,

                                    builder: (context, obscure, _) {
                                      return AuthPasswordTextField(
                                        controller: _retryPasswordController,

                                        label: l10n.authRegisterPasswordLabel,

                                        icon: Icons.lock_outline,

                                        enabled: !controller.isRetrying,

                                        obscureText: obscure,

                                        semanticsLabel:
                                            l10n.authRegisterPasswordLabel,

                                        onToggleObscure: () =>
                                            _obscureRetryPassword.value =
                                                !obscure,

                                        onFieldSubmitted: (_) => unawaited(
                                          _submitRetry(controller),
                                        ),

                                        validator: (value) =>
                                            AppFormValidators.password(
                                              value,

                                              requiredMessage:
                                                  l10n.authPasswordRequired,

                                              tooShortMessage:
                                                  l10n.authPasswordTooShort,

                                              tooLongMessage: l10n
                                                  .authPasswordTooLong(
                                                    RegistrationFormPolicy
                                                        .passwordMaxLength,
                                                  ),

                                              needsUppercaseMessage: l10n
                                                  .authPasswordNeedsUppercase,

                                              needsNumberMessage:
                                                  l10n.authPasswordNeedsNumber,
                                            ),
                                      );
                                    },
                                  ),

                                  SizedBox(height: tokens.gapSm),

                                  LoginPrimaryButton(
                                    label: l10n.authRegistrationRetrySubmit,

                                    isLoading: controller.isRetrying,

                                    onPressed: controller.isRetrying
                                        ? null
                                        : () => unawaited(
                                            _submitRetry(controller),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],

                        SizedBox(height: tokens.authLoginGapMajorSection),

                        Wrap(
                          spacing: tokens.gapSm,

                          runSpacing: tokens.gapSm,

                          children: <Widget>[
                            OutlinedButton(
                              onPressed: () => context.goTo(AppRoute.login),

                              child: Text(l10n.authRegistrationStatusGoToLogin),
                            ),

                            TextButton(
                              onPressed: () => context.goTo(AppRoute.register),

                              child: Text(
                                l10n.authRegistrationStatusCreateNew,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: tokens.authLoginGapBeforeFooter),

                  const LoginFooter(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RegistrationStatusCard extends StatelessWidget {
  const _RegistrationStatusCard({
    required this.status,

    required this.l10n,
  });

  final ClientRegistrationStatus status;

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final (kind, icon, title, message) = switch (status) {
      ClientRegistrationStatus.pending => (
        InlineAlertBannerKind.warning,

        Icons.hourglass_top_rounded,

        l10n.authRegistrationStatusPendingTitle,

        l10n.authRegistrationStatusPendingMessage,
      ),

      ClientRegistrationStatus.approved => (
        InlineAlertBannerKind.success,

        Icons.check_circle_outline_rounded,

        l10n.authRegistrationStatusApprovedTitle,

        l10n.authRegistrationStatusApprovedMessage,
      ),

      ClientRegistrationStatus.rejected => (
        InlineAlertBannerKind.error,

        Icons.cancel_outlined,

        l10n.authRegistrationStatusRejectedTitle,

        l10n.authRegistrationStatusRejectedMessage,
      ),

      ClientRegistrationStatus.expired => (
        InlineAlertBannerKind.error,

        Icons.timer_off_outlined,

        l10n.authRegistrationStatusExpiredTitle,

        l10n.authRegistrationStatusExpiredMessage,
      ),

      ClientRegistrationStatus.blocked => (
        InlineAlertBannerKind.error,

        Icons.block_outlined,

        l10n.authRegistrationStatusBlockedTitle,

        l10n.authRegistrationStatusBlockedMessage,
      ),

      ClientRegistrationStatus.unknown => (
        InlineAlertBannerKind.neutral,

        Icons.help_outline_rounded,

        l10n.authRegistrationStatusUnknownTitle,

        l10n.authRegistrationStatusUnknownMessage,
      ),
    };

    return InlineAlertBanner(
      kind: kind,

      icon: icon,

      title: title,

      message: message,
    );
  }
}
