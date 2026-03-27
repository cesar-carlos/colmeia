import 'package:colmeia/features/auth/presentation/widgets/login/login_primary_button.dart';
import 'package:colmeia/features/auth/presentation/widgets/register/register_back_to_login_row.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';

class RegisterFormActions extends StatelessWidget {
  const RegisterFormActions({
    required this.isLoading,
    required this.onSubmit,
    required this.onBackToLogin,
    super.key,
  });

  final bool isLoading;
  final VoidCallback onSubmit;
  final VoidCallback onBackToLogin;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        LoginPrimaryButton(
          label: isLoading ? 'Enviando solicitação...' : 'Solicitar acesso',
          isLoading: isLoading,
          onPressed: isLoading ? null : onSubmit,
        ),
        SizedBox(height: tokens.authLoginGapAfterPrimary),
        RegisterBackToLoginRow(
          onTap: isLoading ? null : onBackToLogin,
        ),
      ],
    );
  }
}
