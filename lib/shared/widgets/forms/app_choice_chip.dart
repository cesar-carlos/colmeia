import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:material_ui/material_ui.dart';

class AppChoiceChip extends StatelessWidget {
  const AppChoiceChip({
    required this.label,
    required this.selected,
    super.key,
    this.onSelected,
    this.tooltip,
    this.icon,
    this.semanticLabel,
  });

  final String label;
  final bool selected;
  final VoidCallback? onSelected;
  final String? tooltip;
  final IconData? icon;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final cs = theme.colorScheme;

    final labelColor = onSelected == null
        ? cs.onSurface.withValues(alpha: 0.38)
        : selected
        ? cs.onPrimaryContainer
        : cs.onSurfaceVariant;
    final chip = ChoiceChip(
      label: Text(label),
      avatar: icon == null
          ? null
          : Icon(
              icon,
              size: 16,
              color: labelColor,
            ),
      selected: selected,
      onSelected: onSelected == null ? null : (_) => onSelected!(),
      showCheckmark: false,
      backgroundColor: cs.surfaceContainerLowest,
      selectedColor: cs.primaryContainer,
      disabledColor: cs.surfaceContainerHighest.withValues(alpha: 0.4),
      side: BorderSide(
        color: onSelected == null
            ? cs.onSurface.withValues(alpha: 0.12)
            : selected
            ? cs.surfaceAccent
            : cs.outlineVariant.withValues(alpha: 0.4),
      ),
      shape: const StadiumBorder(),
      labelStyle: typography.caption.copyWith(
        fontSize: 14,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
        color: labelColor,
      ),
      padding: EdgeInsets.symmetric(
        horizontal: tokens.gapSm,
        vertical: tokens.gapXs,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );

    final wrappedChip = tooltip == null
        ? chip
        : Tooltip(message: tooltip, child: chip);

    if (semanticLabel == null) {
      return wrappedChip;
    }

    return Semantics(
      selected: selected,
      button: true,
      label: semanticLabel,
      child: wrappedChip,
    );
  }
}
