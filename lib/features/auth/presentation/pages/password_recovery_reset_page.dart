import 'dart:async';

import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/features/auth/application/usecases/read_password_recovery_status_use_case.dart';
import 'package:colmeia/features/auth/application/usecases/reset_password_use_case.dart';
import 'package:colmeia/features/auth/domain/entities/client_password_recovery_status.dart';
import 'package:colmeia/features/auth/presentation/controllers/password_recovery_reset_page_controller.dart';
import 'package:colmeia/features/auth/presentation/widgets/auth_form_text_field.dart';
import 'package:colmeia/features/auth/presentation/widgets/auth_password_text_field.dart';
import 'package:colmeia/features/auth/presentation/widgets/login/login_brand_header.dart';
import 'package:colmeia/features/auth/presentation/widgets/login/login_footer.dart';
import 'package:colmeia/features/auth/presentation/widgets/login/login_glass_card.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/forms/app_form_validators.dart';
import 'package:colmeia/shared/widgets/backgrounds/app_hex_screen_body.dart';
import 'package:colmeia/shared/widgets/feedback/inline_alert_banner.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PasswordRecoveryResetPage extends StatelessWidget {
  const PasswordRecoveryResetPage({
    required this.readPasswordRecoveryStatusUseCase,
    required this.resetPasswordUseCase,
    super.key,
    this.initialToken,
  });

  final ReadPasswordRecoveryStatusUseCase readPasswordRecoveryStatusUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;
  final String? initialToken;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PasswordRecoveryResetPageController(
        readPasswordRecoveryStatusUseCase: readPasswordRecoveryStatusUseCase,
        resetPasswordUseCase: resetPasswordUseCase,
        initialToken: initialToken,
      ),
      child: const _PasswordRecoveryResetPageBody(),
    );
  }
}

class _PasswordRecoveryResetPageBody extends StatefulWidget {
  const _PasswordRecoveryResetPageBody();

  @override
  State<_PasswordRecoveryResetPageBody> createState() =>
      _PasswordRecoveryResetPageBodyState();
}

class _PasswordRecoveryResetPageBodyState
    extends State<_PasswordRecoveryResetPageBody> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _tokenController;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    final initialToken = context
        .read<PasswordRecoveryResetPageController>()
        .token;
    _tokenController = TextEditingController(text: initialToken);
    if (initialToken.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        unawaited(
          context.read<PasswordRecoveryResetPageController>().loadStatus(),
        );
      });
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    await context.read<PasswordRecoveryResetPageController>().resolveToken(
      _tokenController.text,
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final controller = context.read<PasswordRecoveryResetPageController>();
    final canReset = await controller.ensurePendingToken(_tokenController.text);
    if (!canReset) {
      return;
    }

    await controller.resetPassword(
      newPassword: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PasswordRecoveryResetPageController>();
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Redefinir senha',
                            style: theme.textTheme.headlineSmall,
                          ),
                          SizedBox(height: tokens.gapSm),
                          Text(
                            'Informe o token recebido e defina uma nova senha '
                            'para a conta cliente.',
                            style: theme.textTheme.bodyMedium,
                          ),
                          SizedBox(height: tokens.authLoginGapMajorSection),
                          AuthFormTextField(
                            controller: _tokenController,
                            enabled: !controller.isLoading,
                            label: 'Token de recuperacao',
                            icon: Icons.vpn_key_outlined,
                            onFieldSubmitted: (_) => unawaited(_loadStatus()),
                            validator: (value) =>
                                AppFormValidators.requiredText(
                                  value,
                                  message: 'Informe o token para continuar.',
                                ),
                          ),
                          SizedBox(height: tokens.gapSm),
                          OutlinedButton(
                            onPressed: controller.isLoading
                                ? null
                                : _loadStatus,
                            child: const Text('Validar token'),
                          ),
                          if (controller.errorMessage
                              case final String message) ...<Widget>[
                            SizedBox(height: tokens.contentSpacing),
                            InlineAlertBanner(message: message),
                          ],
                          if (controller.successMessage
                              case final String message) ...<Widget>[
                            SizedBox(height: tokens.contentSpacing),
                            _RecoverySuccessBanner(message: message),
                          ],
                          if (controller.status case final status?) ...<Widget>[
                            SizedBox(height: tokens.contentSpacing),
                            _PasswordRecoveryStatusCard(status: status),
                          ],
                          SizedBox(height: tokens.authLoginGapMajorSection),
                          AuthPasswordTextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            onToggleObscure: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            enabled: !controller.isLoading,
                            label: 'Nova senha',
                            icon: Icons.lock_outline_rounded,
                            validator: AppFormValidators.password,
                          ),
                          SizedBox(height: tokens.gapMd),
                          AuthPasswordTextField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            onToggleObscure: () {
                              setState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                            enabled: !controller.isLoading,
                            label: 'Confirmar nova senha',
                            icon: Icons.lock_reset_outlined,
                            validator: (value) =>
                                AppFormValidators.confirmPassword(
                                  value,
                                  password: _passwordController.text,
                                ),
                            onFieldSubmitted: (_) => unawaited(_submit()),
                          ),
                          SizedBox(height: tokens.authLoginGapMajorSection),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: controller.isLoading ? null : _submit,
                              child: controller.isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Redefinir senha'),
                            ),
                          ),
                          SizedBox(height: tokens.gapSm),
                          Wrap(
                            spacing: tokens.gapSm,
                            runSpacing: tokens.gapSm,
                            children: <Widget>[
                              TextButton(
                                onPressed: () => context.goTo(
                                  AppRoute.passwordRecovery,
                                ),
                                child: const Text('Solicitar novo token'),
                              ),
                              TextButton(
                                onPressed: () => context.goTo(AppRoute.login),
                                child: const Text('Voltar ao login'),
                              ),
                            ],
                          ),
                        ],
                      ),
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

class _PasswordRecoveryStatusCard extends StatelessWidget {
  const _PasswordRecoveryStatusCard({
    required this.status,
  });

  final ClientPasswordRecoveryStatus status;

  @override
  Widget build(BuildContext context) {
    final (kind, icon, title, message) = switch (status) {
      ClientPasswordRecoveryStatus.pending => (
        InlineAlertBannerKind.success,
        Icons.verified_user_outlined,
        'Token valido',
        'O token esta ativo. Voce ja pode definir a nova senha.',
      ),
      ClientPasswordRecoveryStatus.expired => (
        InlineAlertBannerKind.error,
        Icons.timer_off_outlined,
        'Token expirado',
        'Esse token expirou. Solicite uma nova recuperacao de acesso.',
      ),
      ClientPasswordRecoveryStatus.invalid => (
        InlineAlertBannerKind.error,
        Icons.help_outline_rounded,
        'Token invalido',
        'Nao encontramos um token valido com esse valor.',
      ),
      ClientPasswordRecoveryStatus.unknown => (
        InlineAlertBannerKind.neutral,
        Icons.help_outline_rounded,
        'Status desconhecido',
        'A API retornou um status que ainda nao foi classificado no app.',
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

class _RecoverySuccessBanner extends StatelessWidget {
  const _RecoverySuccessBanner({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(tokens.contentSpacing),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(tokens.cardRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.check_circle_outline_rounded,
            color: colorScheme.onTertiaryContainer,
          ),
          SizedBox(width: tokens.gapSm),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
