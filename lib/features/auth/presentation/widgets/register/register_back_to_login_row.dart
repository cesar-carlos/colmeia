import 'package:flutter/material.dart';

class RegisterBackToLoginRow extends StatelessWidget {
  const RegisterBackToLoginRow({this.onTap, super.key});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Center(
      child: RichText(
        text: TextSpan(
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          children: <InlineSpan>[
            const TextSpan(text: 'Já tem conta? '),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: GestureDetector(
                onTap: onTap,
                child: Text(
                  'Entrar',
                  style: tt.bodySmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                    decoration: TextDecoration.underline,
                    decorationColor: cs.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
