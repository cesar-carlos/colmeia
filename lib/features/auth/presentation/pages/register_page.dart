import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/auth/presentation/controllers/register_page_controller.dart';
import 'package:colmeia/features/auth/presentation/models/register_access_profile.dart';
import 'package:colmeia/features/auth/presentation/widgets/auth_email_text_field.dart';
import 'package:colmeia/features/auth/presentation/widgets/auth_form_text_field.dart';
import 'package:colmeia/features/auth/presentation/widgets/login/login_brand_header.dart';
import 'package:colmeia/features/auth/presentation/widgets/login/login_footer.dart';
import 'package:colmeia/features/auth/presentation/widgets/login/login_glass_card.dart';
import 'package:colmeia/features/auth/presentation/widgets/register/register_access_profile_section.dart';
import 'package:colmeia/features/auth/presentation/widgets/register/register_corporate_hero_section.dart';
import 'package:colmeia/features/auth/presentation/widgets/register/register_credentials_section.dart';
import 'package:colmeia/features/auth/presentation/widgets/register/register_form_actions.dart';
import 'package:colmeia/features/auth/presentation/widgets/register/register_form_section_title.dart';
import 'package:colmeia/features/auth/presentation/widgets/register/register_store_selection_section.dart';
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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _employeeIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _employeeIdController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthController auth, RegisterPageController page) async {
    if (!page.validateStoreSelection()) {
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    await auth.register(
      fullName: _nameController.text.trim(),
      email: _emailController.text,
      password: _passwordController.text,
      employeeId: _employeeIdController.text.trim(),
      accessProfileLabel: page.selectedProfile.label,
      requestedStoreIds: page.selectedStoreIds.toList(growable: false),
    );

    if (!mounted) {
      return;
    }

    if (auth.successMessage case final String successMessage) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
      auth.clearTransientFeedback();
      context.goTo(AppRoute.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final page = context.watch<RegisterPageController>();
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const RegisterCorporateHeroSection(),
                            SizedBox(height: tokens.authLoginGapMajorSection),
                            const RegisterFormSectionTitle(
                              title: 'Informações pessoais',
                            ),
                            AuthFormTextField(
                              controller: _nameController,
                              label: 'Nome completo',
                              icon: Icons.badge_outlined,
                              enabled: !blocked,
                              validator: AppFormValidators.fullName,
                            ),
                            SizedBox(height: tokens.authLoginGapBetweenFields),
                            AuthEmailTextField(
                              controller: _emailController,
                              label: 'E-mail corporativo',
                              icon: Icons.alternate_email,
                              enabled: !blocked,
                              emptyMessage: 'Informe o e-mail corporativo.',
                            ),
                            SizedBox(height: tokens.authLoginGapBetweenFields),
                            AuthFormTextField(
                              controller: _employeeIdController,
                              label: 'Matrícula (Employee ID)',
                              icon: Icons.numbers_rounded,
                              enabled: !blocked,
                              validator: AppFormValidators.employeeId,
                            ),
                            SizedBox(height: tokens.sectionSpacing),
                            RegisterAccessProfileSection(
                              groupValue: page.selectedProfile,
                              enabled: !blocked,
                              onChanged: page.setProfile,
                            ),
                            RegisterStoreSelectionSection(
                              selectedIds: page.selectedStoreIds,
                              showSelectionError:
                                  page.storeSelectionErrorVisible,
                              enabled: !blocked,
                              onToggle: page.toggleStoreSelection,
                            ),
                            RegisterCredentialsSection(
                              passwordController: _passwordController,
                              confirmPasswordController:
                                  _confirmPasswordController,
                              obscurePassword: page.obscurePassword,
                              obscureConfirmPassword:
                                  page.obscureConfirmPassword,
                              onToggleObscurePassword:
                                  page.toggleObscurePassword,
                              onToggleObscureConfirmPassword:
                                  page.toggleObscureConfirmPassword,
                              onConfirmSubmitted: (_) => _submit(auth, page),
                            ),
                            if (auth.errorMessage
                                case final String errorMessage) ...<Widget>[
                              InlineAlertBanner(message: errorMessage),
                              SizedBox(height: tokens.contentSpacing),
                            ],
                            RegisterFormActions(
                              isLoading: blocked,
                              onSubmit: () => _submit(auth, page),
                              onBackToLogin: () => context.goTo(AppRoute.login),
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
