import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/features/auth/application/usecases/request_password_recovery_use_case.dart';
import 'package:colmeia/features/auth/presentation/controllers/password_recovery_request_page_controller.dart';
import 'package:colmeia/features/auth/presentation/widgets/auth_email_text_field.dart';
import 'package:colmeia/features/auth/presentation/widgets/login/login_brand_header.dart';
import 'package:colmeia/features/auth/presentation/widgets/login/login_footer.dart';
import 'package:colmeia/features/auth/presentation/widgets/login/login_glass_card.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/backgrounds/app_hex_screen_body.dart';
import 'package:colmeia/shared/widgets/feedback/inline_alert_banner.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PasswordRecoveryRequestPage extends StatelessWidget {
  const PasswordRecoveryRequestPage({
    required this.requestPasswordRecoveryUseCase,
    super.key,
  });

  final RequestPasswordRecoveryUseCase requestPasswordRecoveryUseCase;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PasswordRecoveryRequestPageController(
        requestPasswordRecoveryUseCase: requestPasswordRecoveryUseCase,
      ),
      child: const _PasswordRecoveryRequestPageBody(),
    );
  }
}

class _PasswordRecoveryRequestPageBody extends StatefulWidget {
  const _PasswordRecoveryRequestPageBody();

  @override
  State<_PasswordRecoveryRequestPageBody> createState() =>
      _PasswordRecoveryRequestPageBodyState();
}

class _PasswordRecoveryRequestPageBodyState
    extends State<_PasswordRecoveryRequestPageBody> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await context.read<PasswordRecoveryRequestPageController>().submit(
          email: _emailController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PasswordRecoveryRequestPageController>();
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
                            'Recuperar acesso',
                            style: theme.textTheme.headlineSmall,
                          ),
                          SizedBox(height: tokens.gapSm),
                          Text(
                            'Informe o e-mail da conta cliente. Se a conta '
                            'existir, a API enviara as instrucoes de '
                            'recuperacao.',
                            style: theme.textTheme.bodyMedium,
                          ),
                          SizedBox(height: tokens.authLoginGapMajorSection),
                          AuthEmailTextField(
                            controller: _emailController,
                            enabled: !controller.isLoading,
                            label: 'E-mail da conta',
                            icon: Icons.alternate_email_rounded,
                          ),
                          if (controller.errorMessage case final String message)
                            ...<Widget>[
                              SizedBox(height: tokens.contentSpacing),
                              InlineAlertBanner(message: message),
                            ],
                          if (controller.successMessage
                              case final String message) ...<Widget>[
                            SizedBox(height: tokens.contentSpacing),
                            _SuccessBanner(message: message),
                          ],
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
                                  : const Text('Solicitar recuperacao'),
                            ),
                          ),
                          SizedBox(height: tokens.gapSm),
                          Wrap(
                            spacing: tokens.gapSm,
                            runSpacing: tokens.gapSm,
                            children: <Widget>[
                              TextButton(
                                onPressed: () => context.goTo(AppRoute.login),
                                child: const Text('Voltar ao login'),
                              ),
                              TextButton(
                                onPressed: () => context.goTo(
                                  AppRoute.passwordRecoveryReset,
                                ),
                                child: const Text('Ja tenho o token'),
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

class _SuccessBanner extends StatelessWidget {
  const _SuccessBanner({
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
            Icons.mark_email_read_outlined,
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
