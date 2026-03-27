import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';

class LoginFooter extends StatelessWidget {
  const LoginFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return Column(
      children: <Widget>[
        Text(
          '© 2026 SE7E SISTEMAS SINOP',
          style: tt.labelSmall?.copyWith(
            letterSpacing: 2,
            color: cs.outline.withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: tokens.gapXs),
        Text(
          'v1.0.0 · MVP',
          style: tt.labelSmall?.copyWith(
            letterSpacing: 2,
            color: cs.outline.withValues(alpha: 0.4),
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
