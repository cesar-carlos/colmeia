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
        FilledButton.icon(
          onPressed: isLoading ? null : onSubmit,
          icon: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.app_registration),
          label: Text(
            isLoading ? 'Enviando solicitacao...' : 'Solicitar acesso',
          ),
        ),
        SizedBox(height: tokens.gapMd),
        TextButton(
          onPressed: isLoading ? null : onBackToLogin,
          child: const Text('Ja tenho conta'),
        ),
      ],
    );
  }
}
