import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/auth/presentation/controllers/register_page_controller.dart';
import 'package:colmeia/features/auth/presentation/widgets/auth_email_text_field.dart';
import 'package:colmeia/features/auth/presentation/widgets/auth_form_text_field.dart';
import 'package:colmeia/features/auth/presentation/widgets/auth_password_text_field.dart';
import 'package:colmeia/features/auth/presentation/widgets/register/register_form_actions.dart';
import 'package:colmeia/features/auth/presentation/widgets/register/register_header_section.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/forms/app_form_validators.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/backgrounds/honeycomb_hex_background.dart';
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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _storeController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _storeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthController controller) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await controller.register(
      fullName: _nameController.text,
      email: _emailController.text,
      storeName: _storeController.text,
      password: _passwordController.text,
    );

    if (!mounted) {
      return;
    }

    if (controller.successMessage case final String successMessage) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
      controller.clearTransientFeedback();
      context.goTo(AppRoute.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final page = context.watch<RegisterPageController>();
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return Scaffold(
      body: HoneycombHexBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: tokens.authLoginContentMaxWidth,
              ),
              child: AppSkeleton(
                enabled: false,
                child: Padding(
                  padding: EdgeInsets.all(tokens.authLoginScrollPaddingHorizontal),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: <Widget>[
                        const RegisterHeaderSection(),
                        SizedBox(height: tokens.authLoginGapBetweenFields),
                        AuthFormTextField(
                          controller: _nameController,
                          label: 'Nome completo',
                          icon: Icons.person_outline,
                          validator: AppFormValidators.fullName,
                        ),
                        SizedBox(height: tokens.contentSpacing),
                        AuthEmailTextField(
                          controller: _emailController,
                          label: 'E-mail corporativo',
                          icon: Icons.alternate_email,
                          emptyMessage: 'Informe o e-mail corporativo.',
                        ),
                        SizedBox(height: tokens.contentSpacing),
                        AuthFormTextField(
                          controller: _storeController,
                          label: 'Loja principal',
                          icon: Icons.store_mall_directory_outlined,
                          validator: AppFormValidators.storeName,
                        ),
                        SizedBox(height: tokens.contentSpacing),
                        AuthPasswordTextField(
                          controller: _passwordController,
                          label: 'Senha',
                          icon: Icons.lock_outline,
                          obscureText: page.obscurePassword,
                          onToggleObscure: page.toggleObscurePassword,
                        ),
                        SizedBox(height: tokens.contentSpacing),
                        AuthPasswordTextField(
                          controller: _confirmPasswordController,
                          label: 'Confirmar senha',
                          icon: Icons.lock_reset_outlined,
                          obscureText: page.obscureConfirmPassword,
                          onToggleObscure: page.toggleObscureConfirmPassword,
                          onFieldSubmitted: (_) => _submit(auth),
                          validator: (value) =>
                              AppFormValidators.confirmPassword(
                                value,
                                password: _passwordController.text,
                              ),
                        ),
                        if (auth.errorMessage
                            case final String errorMessage) ...<Widget>[
                          SizedBox(height: tokens.contentSpacing),
                          InlineAlertBanner(message: errorMessage),
                        ],
                        SizedBox(height: tokens.authLoginGapBetweenFields),
                        RegisterFormActions(
                          isLoading: auth.isLoading,
                          onSubmit: () => _submit(auth),
                          onBackToLogin: () => context.goTo(AppRoute.login),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
