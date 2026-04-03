import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/auth/presentation/controllers/register_page_controller.dart';
import 'package:colmeia/features/auth/presentation/widgets/auth_email_text_field.dart';
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

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => RegisterPageController(),
      child: const _RegisterPageBody(),
    );
  }
}

class _RegisterPageBody extends StatefulWidget {
  const _RegisterPageBody();

  @override
  State<_RegisterPageBody> createState() => _RegisterPageBodyState();
}

class _RegisterPageBodyState extends State<_RegisterPageBody> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _ownerEmailController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _ownerEmailController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthController auth, RegisterPageController page) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await auth.register(
      ownerEmail: _ownerEmailController.text.trim(),
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text,
      password: _passwordController.text,
      mobile: _mobileController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    final submission = auth.registrationSubmission;
    if (submission == null) {
      return;
    }

    auth
      ..clearTransientFeedback()
      ..clearRegistrationSubmission();
    context.goTo(
      AppRoute.registrationStatus,
      queryParameters: submission.approvalToken == null
          ? const <String, String>{}
          : <String, String>{'token': submission.approvalToken!},
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final page = context.watch<RegisterPageController>();
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final blocked = auth.isLoading;

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
                      child: AutofillGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Criar conta de cliente',
                              style: theme.textTheme.headlineSmall,
                            ),
                            SizedBox(height: tokens.gapSm),
                            Text(
                              'Seu cadastro ficara pendente de aprovacao do '
                              'responsavel informado. Assim que ele aprovar, '
                              'voce podera entrar na conta.',
                              style: theme.textTheme.bodyMedium,
                            ),
                            SizedBox(height: tokens.authLoginGapMajorSection),
                            AuthEmailTextField(
                              controller: _ownerEmailController,
                              label: 'E-mail do responsavel',
                              icon: Icons.supervisor_account_outlined,
                              enabled: !blocked,
                              emptyMessage: 'Informe o e-mail do responsavel.',
                            ),
                            SizedBox(height: tokens.authLoginGapBetweenFields),
                            AuthFormTextField(
                              controller: _firstNameController,
                              label: 'Nome',
                              icon: Icons.badge_outlined,
                              enabled: !blocked,
                              validator: (value) =>
                                  AppFormValidators.requiredText(
                                    value,
                                    message: 'Informe seu nome.',
                                  ),
                            ),
                            SizedBox(height: tokens.authLoginGapBetweenFields),
                            AuthFormTextField(
                              controller: _lastNameController,
                              label: 'Sobrenome',
                              icon: Icons.person_outline,
                              enabled: !blocked,
                              validator: (value) =>
                                  AppFormValidators.requiredText(
                                    value,
                                    message: 'Informe seu sobrenome.',
                                  ),
                            ),
                            SizedBox(height: tokens.authLoginGapBetweenFields),
                            AuthEmailTextField(
                              controller: _emailController,
                              label: 'E-mail da conta',
                              icon: Icons.alternate_email,
                              enabled: !blocked,
                              emptyMessage: 'Informe o e-mail da conta.',
                            ),
                            SizedBox(height: tokens.authLoginGapBetweenFields),
                            AuthFormTextField(
                              controller: _mobileController,
                              label: 'Celular (opcional)',
                              icon: Icons.phone_android_outlined,
                              enabled: !blocked,
                              keyboardType: TextInputType.phone,
                            ),
                            SizedBox(height: tokens.authLoginGapBetweenFields),
                            AuthPasswordTextField(
                              controller: _passwordController,
                              label: 'Senha',
                              icon: Icons.lock_outline,
                              enabled: !blocked,
                              obscureText: page.obscurePassword,
                              onToggleObscure: page.toggleObscurePassword,
                              textInputAction: TextInputAction.next,
                              validator: (value) => AppFormValidators.password(
                                value,
                                minLength: 8,
                              ),
                            ),
                            SizedBox(height: tokens.authLoginGapBetweenFields),
                            AuthPasswordTextField(
                              controller: _confirmPasswordController,
                              label: 'Confirmar senha',
                              icon: Icons.lock_reset_outlined,
                              enabled: !blocked,
                              obscureText: page.obscureConfirmPassword,
                              onToggleObscure:
                                  page.toggleObscureConfirmPassword,
                              onFieldSubmitted: (_) => _submit(auth, page),
                              validator: (value) =>
                                  AppFormValidators.confirmPassword(
                                    value,
                                    password: _passwordController.text,
                                  ),
                            ),
                            SizedBox(height: tokens.authLoginGapMajorSection),
                            if (auth.errorMessage
                                case final String errorMessage) ...<Widget>[
                              InlineAlertBanner(message: errorMessage),
                              SizedBox(height: tokens.contentSpacing),
                            ],
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: blocked
                                    ? null
                                    : () => _submit(auth, page),
                                child: blocked
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Solicitar cadastro'),
                              ),
                            ),
                            SizedBox(height: tokens.gapSm),
                            Center(
                              child: TextButton(
                                onPressed: blocked
                                    ? null
                                    : () => context.goTo(AppRoute.login),
                                child: const Text('Voltar para o login'),
                              ),
                            ),
                          ],
                        ),
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
