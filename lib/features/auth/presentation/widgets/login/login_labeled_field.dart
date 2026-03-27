import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';

/// Label row (icon + uppercase text + optional trailing) followed by a field.
/// Matches Stitch label style: small uppercase, tracking, onSurfaceVariant.
class LoginLabeledField extends StatelessWidget {
  const LoginLabeledField({
    required this.label,
    required this.icon,
    required this.child,
    super.key,
    this.trailing,
  });

  final String label;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, size: 16, color: cs.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  label.toUpperCase(),
                  style: tt.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            trailing ?? const SizedBox.shrink(),
          ],
        ),
        SizedBox(height: tokens.gapSm),
        child,
      ],
    );
  }
}
