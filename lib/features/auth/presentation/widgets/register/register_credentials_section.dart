import 'package:colmeia/features/auth/presentation/widgets/auth_password_text_field.dart';
import 'package:colmeia/features/auth/presentation/widgets/register/register_form_section_title.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/forms/app_form_validators.dart';
import 'package:flutter/material.dart';

class RegisterCredentialsSection extends StatelessWidget {
  const RegisterCredentialsSection({
    required this.passwordController,
    required this.confirmPasswordController,
    required this.obscurePassword,
    required this.obscureConfirmPassword,
    required this.onToggleObscurePassword,
    required this.onToggleObscureConfirmPassword,
    required this.onConfirmSubmitted,
    super.key,
  });

  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool obscurePassword;
  final bool obscureConfirmPassword;
  final VoidCallback onToggleObscurePassword;
  final VoidCallback onToggleObscureConfirmPassword;
  final void Function(String) onConfirmSubmitted;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const RegisterFormSectionTitle(title: 'Senha de acesso'),
        Text(
          'Defina uma senha para acessar o app após aprovação da solicitação.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
        SizedBox(height: tokens.gapMd),
        AuthPasswordTextField(
          controller: passwordController,
          label: 'Senha',
          icon: Icons.lock_outline,
          obscureText: obscurePassword,
          onToggleObscure: onToggleObscurePassword,
          textInputAction: TextInputAction.next,
          validator: AppFormValidators.password,
        ),
        SizedBox(height: tokens.contentSpacing),
        AuthPasswordTextField(
          controller: confirmPasswordController,
          label: 'Confirmar senha',
          icon: Icons.lock_reset_outlined,
          obscureText: obscureConfirmPassword,
          onToggleObscure: onToggleObscureConfirmPassword,
          onFieldSubmitted: onConfirmSubmitted,
          validator: (value) => AppFormValidators.confirmPassword(
            value,
            password: passwordController.text,
          ),
        ),
        SizedBox(height: tokens.sectionSpacing),
      ],
    );
  }
}
