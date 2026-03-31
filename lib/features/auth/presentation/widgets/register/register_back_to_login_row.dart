import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/actions/app_text_action_button.dart';
import 'package:flutter/material.dart';

class RegisterBackToLoginRow extends StatelessWidget {
  const RegisterBackToLoginRow({this.onTap, super.key});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;

    return Center(
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: tokens.gapXs,
        children: <Widget>[
          Text(
            'Ja tem conta?',
            style: typography.caption.copyWith(color: cs.onSurfaceVariant),
          ),
          AppTextActionButton(
            label: 'Entrar',
            onPressed: onTap,
            semanticsLabel: 'Voltar para entrar',
          ),
        ],
      ),
    );
  }
}
