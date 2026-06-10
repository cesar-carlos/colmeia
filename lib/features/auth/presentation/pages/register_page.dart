import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/features/auth/presentation/controllers/register_page_controller.dart';
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

class RegisterPage extends StatelessWidget {
  const RegisterPage({
    required this.controller,
    super.key,
  });

  final RegisterPageController controller;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => controller,
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

  Future<void> _submit(RegisterPageController page) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final l10n = AppLocalizations.of(context);
    await page.register(
      ownerEmail: _ownerEmailController.text.trim(),
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      email: _emailController.text,
      password: _passwordController.text,
      mobile: _mobileController.text.trim(),
      genericSuccessMessage: l10n.authRegisterGenericSuccess,
      invalidEmailMessage: l10n.authEmailFieldInvalid,
      mapFailure: (failure) => mapAuthRegistrationFailure(failure, l10n),
    );

    if (!mounted) {
      return;
    }

    final submission = page.submission;
    if (submission == null) {
      return;
    }

    if (submission.canPollStatus) {
      page
        ..clearTransientFeedback()
        ..clearSubmission();
      context.goTo(AppRoute.registrationStatus);
      return;
    }

    page.clearSubmission();
  }

  @override
  Widget build(BuildContext context) {
    final page = context.watch<RegisterPageController>();
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final blocked = page.isLoading;
    final l10n = AppLocalizations.of(context);
    final submission = page.submission;
    final showDuplicateCta =
        submission != null && submission.duplicate && !submission.canPollStatus;

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
                              l10n.authRegisterTitle,
                              style: theme.textTheme.headlineSmall,
                            ),
                            SizedBox(height: tokens.gapSm),
                            Text(
                              l10n.authRegisterSubtitle,
                              style: theme.textTheme.bodyMedium,
                            ),
                            SizedBox(height: tokens.authLoginGapMajorSection),
                            AuthEmailTextField(
                              controller: _ownerEmailController,
                              label: l10n.authRegisterOwnerEmailLabel,
                              icon: Icons.supervisor_account_outlined,
                              enabled: !blocked,
                              emptyMessage: l10n.authRegisterOwnerEmailRequired,
                              invalidMessage: l10n.authEmailFieldInvalid,
                              semanticsLabel: l10n.authRegisterOwnerEmailLabel,
                            ),
                            SizedBox(height: tokens.authLoginGapBetweenFields),
                            AuthFormTextField(
                              controller: _firstNameController,
                              label: l10n.authRegisterFirstNameLabel,
                              icon: Icons.badge_outlined,
                              enabled: !blocked,
                              semanticsLabel: l10n.authRegisterFirstNameLabel,
                              validator: (value) =>
                                  AppFormValidators.personName(
                                    value,
                                    requiredMessage:
                                        l10n.authRegisterFirstNameRequired,
                                    tooLongMessage:
                                        l10n.authRegisterFirstNameTooLong,
                                  ),
                            ),
                            SizedBox(height: tokens.authLoginGapBetweenFields),
                            AuthFormTextField(
                              controller: _lastNameController,
                              label: l10n.authRegisterLastNameLabel,
                              icon: Icons.person_outline,
                              enabled: !blocked,
                              semanticsLabel: l10n.authRegisterLastNameLabel,
                              validator: (value) =>
                                  AppFormValidators.personName(
                                    value,
                                    requiredMessage:
                                        l10n.authRegisterLastNameRequired,
                                    tooLongMessage:
                                        l10n.authRegisterLastNameTooLong,
                                  ),
                            ),
                            SizedBox(height: tokens.authLoginGapBetweenFields),
                            AuthEmailTextField(
                              controller: _emailController,
                              label: l10n.authRegisterAccountEmailLabel,
                              icon: Icons.alternate_email,
                              enabled: !blocked,
                              emptyMessage:
                                  l10n.authRegisterAccountEmailRequired,
                              invalidMessage: l10n.authEmailFieldInvalid,
                              semanticsLabel:
                                  l10n.authRegisterAccountEmailLabel,
                            ),
                            SizedBox(height: tokens.authLoginGapBetweenFields),
                            AuthFormTextField(
                              controller: _mobileController,
                              label: l10n.authRegisterMobileLabel,
                              icon: Icons.phone_android_outlined,
                              enabled: !blocked,
                              keyboardType: TextInputType.phone,
                              semanticsLabel: l10n.authRegisterMobileLabel,
                              validator: (value) =>
                                  AppFormValidators.optionalBrazilianMobile(
                                    value,
                                    invalidMessage:
                                        l10n.authRegisterMobileInvalid,
                                  ),
                            ),
                            SizedBox(height: tokens.authLoginGapBetweenFields),
                            AuthPasswordTextField(
                              controller: _passwordController,
                              label: l10n.authRegisterPasswordLabel,
                              icon: Icons.lock_outline,
                              enabled: !blocked,
                              obscureText: page.obscurePassword,
                              onToggleObscure: page.toggleObscurePassword,
                              textInputAction: TextInputAction.next,
                              semanticsLabel: l10n.authRegisterPasswordLabel,
                              validator: (value) => AppFormValidators.password(
                                value,
                                requiredMessage: l10n.authPasswordRequired,
                                tooShortMessage: l10n.authPasswordTooShort,
                                tooLongMessage: l10n.authPasswordTooLong(
                                  RegistrationFormPolicy.passwordMaxLength,
                                ),
                                needsUppercaseMessage:
                                    l10n.authPasswordNeedsUppercase,
                                needsNumberMessage:
                                    l10n.authPasswordNeedsNumber,
                              ),
                            ),
                            SizedBox(height: tokens.authLoginGapBetweenFields),
                            AuthPasswordTextField(
                              controller: _confirmPasswordController,
                              label: l10n.authRegisterConfirmPasswordLabel,
                              icon: Icons.lock_reset_outlined,
                              enabled: !blocked,
                              obscureText: page.obscureConfirmPassword,
                              onToggleObscure:
                                  page.toggleObscureConfirmPassword,
                              onFieldSubmitted: (_) => _submit(page),
                              semanticsLabel:
                                  l10n.authRegisterConfirmPasswordLabel,
                              validator: (value) =>
                                  AppFormValidators.confirmPassword(
                                    value,
                                    password: _passwordController.text,
                                    requiredMessage:
                                        l10n.authConfirmPasswordRequired,
                                    mismatchMessage: l10n.authPasswordsMismatch,
                                  ),
                            ),
                            SizedBox(height: tokens.authLoginGapMajorSection),
                            if (page.successMessage
                                case final String successMessage) ...<Widget>[
                              InlineAlertBanner(
                                kind: InlineAlertBannerKind.success,
                                message: successMessage,
                              ),
                              SizedBox(height: tokens.contentSpacing),
                            ],
                            if (showDuplicateCta) ...<Widget>[
                              InlineAlertBanner(
                                kind: InlineAlertBannerKind.warning,
                                title: l10n.authRegisterDuplicateTitle,
                                message: l10n.authRegisterDuplicateMessage,
                              ),
                              SizedBox(height: tokens.gapSm),
                              LoginPrimaryButton(
                                label: l10n.authRegisterDuplicateCheckStatus,
                                onPressed: blocked
                                    ? null
                                    : () => context.goTo(
                                        AppRoute.registrationStatus,
                                      ),
                              ),
                              SizedBox(height: tokens.contentSpacing),
                            ],
                            if (page.errorMessage
                                case final String errorMessage) ...<Widget>[
                              InlineAlertBanner(message: errorMessage),
                              SizedBox(height: tokens.contentSpacing),
                            ],
                            LoginPrimaryButton(
                              label: l10n.authRegisterSubmitButton,
                              isLoading: blocked,
                              onPressed: blocked ? null : () => _submit(page),
                            ),
                            SizedBox(height: tokens.gapSm),
                            Center(
                              child: TextButton(
                                onPressed: blocked
                                    ? null
                                    : () => context.goTo(AppRoute.login),
                                child: Text(l10n.authRegisterBackToLogin),
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
