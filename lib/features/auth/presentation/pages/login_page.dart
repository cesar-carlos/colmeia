import 'dart:async';

import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/auth/presentation/controllers/login_page_controller.dart';
import 'package:colmeia/features/auth/presentation/widgets/login/login_brand_header.dart';
import 'package:colmeia/features/auth/presentation/widgets/login/login_email_form_field.dart';
import 'package:colmeia/features/auth/presentation/widgets/login/login_footer.dart';
import 'package:colmeia/features/auth/presentation/widgets/login/login_glass_card.dart';
import 'package:colmeia/features/auth/presentation/widgets/login/login_password_form_field.dart';
import 'package:colmeia/features/auth/presentation/widgets/login/login_primary_button.dart';
import 'package:colmeia/features/auth/presentation/widgets/login/login_remember_me_row.dart';
import 'package:colmeia/features/auth/presentation/widgets/login/login_request_access_row.dart';
import 'package:colmeia/features/auth/presentation/widgets/login/login_welcome_section.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/backgrounds/app_hex_screen_body.dart';
import 'package:colmeia/shared/widgets/feedback/inline_alert_banner.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LoginPageController(),
      child: const _LoginPageBody(),
    );
  }
}

class _LoginPageBody extends StatefulWidget {
  const _LoginPageBody();

  @override
  State<_LoginPageBody> createState() => _LoginPageBodyState();
}

class _LoginPageBodyState extends State<_LoginPageBody> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController(
    text: kDebugMode ? 'camila@example.com' : '',
  );
  final TextEditingController _passwordController = TextEditingController(
    text: kDebugMode ? '123456' : '',
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(
        context.read<LoginPageController>().loadRememberMePreference(),
      );
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthController controller) async {
    if (!_formKey.currentState!.validate()) return;

    await controller.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (mounted && controller.isAuthenticated) {
      context.goTo(AppRoute.dashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final page = context.watch<LoginPageController>();
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final isBlocked = auth.isLoading || auth.isRestoringSession;

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
                            const LoginWelcomeSection(),
                            SizedBox(height: tokens.authLoginGapMajorSection),
                            LoginEmailFormField(
                              controller: _emailController,
                              enabled: !isBlocked,
                            ),
                            SizedBox(height: tokens.authLoginGapBetweenFields),
                            LoginPasswordFormField(
                              controller: _passwordController,
                              obscure: page.obscurePassword,
                              enabled: !isBlocked,
                              onToggleObscure: page.toggleObscurePassword,
                              onSubmitted: () => _submit(auth),
                            ),
                            SizedBox(height: tokens.authLoginGapAfterPassword),
                            LoginRememberMeRow(
                              value: page.rememberMe,
                              onChanged: (v) => page.setRememberMe(
                                value: v ?? false,
                              ),
                            ),
                            if (auth.errorMessage
                                case final String message) ...<Widget>[
                              SizedBox(height: tokens.contentSpacing),
                              InlineAlertBanner(message: message),
                            ],
                            SizedBox(height: tokens.authLoginGapMajorSection),
                            LoginPrimaryButton(
                              label: auth.isRestoringSession
                                  ? 'Restaurando sessão...'
                                  : 'Entrar no Dashboard',
                              isLoading: isBlocked,
                              onPressed: () => _submit(auth),
                            ),
                            SizedBox(height: tokens.authLoginGapAfterPrimary),
                            LoginRequestAccessRow(
                              onTap: auth.isLoading
                                  ? null
                                  : () => context.goTo(AppRoute.register),
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
