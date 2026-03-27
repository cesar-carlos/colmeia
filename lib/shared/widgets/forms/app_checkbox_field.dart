import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';

/// Checkbox with label, tap target on label, optional semantics.
class AppCheckboxField extends StatelessWidget {
  const AppCheckboxField({
    required this.value,
    required this.onChanged,
    required this.label,
    super.key,
    this.enabled = true,
    this.semanticLabel,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;
  final String label;
  final bool enabled;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>();
    final side = tokens?.formControlCheckboxSide ?? 20;
    final gap = tokens?.formLabelToControlGap ?? 8;

    final checkbox = SizedBox(
      width: side,
      height: side,
      child: Checkbox(
        value: value,
        onChanged: enabled ? onChanged : null,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );

    return Semantics(
      label: semanticLabel ?? label,
      child: MergeSemantics(
        child: Row(
          children: <Widget>[
            checkbox,
            SizedBox(width: gap),
            Expanded(
              child: GestureDetector(
                onTap: enabled ? () => onChanged(!value) : null,
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: enabled
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.onSurface.withValues(alpha: 0.38),
                    fontWeight: FontWeight.w500,
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
