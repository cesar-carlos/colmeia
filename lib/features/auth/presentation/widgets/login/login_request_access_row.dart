import 'package:colmeia/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class LoginRequestAccessRow extends StatelessWidget {
  const LoginRequestAccessRow({this.onTap, super.key});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Center(
      child: RichText(
        text: TextSpan(
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          children: <InlineSpan>[
            TextSpan(text: l10n.authLoginNewHerePrefix),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: GestureDetector(
                onTap: onTap,
                child: Text(
                  l10n.authLoginRequestAccessAction,
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
