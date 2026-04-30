import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';

/// [DraggableScrollableSheet.minChildSize] fraction so fixed header and footer
/// fit before the flex list receives space (avoids [Column] overflow at min extent).
double draggableSheetMinChildFractionForChrome({
  required double viewportHeight,
  required double minChromePixels,
  double minClamp = 0.48,
  double maxClamp = 0.94,
}) {
  if (viewportHeight <= 0) {
    return minClamp;
  }
  return (minChromePixels / viewportHeight).clamp(minClamp, maxClamp);
}

/// Thin drag affordance for modal bottom sheets when the route does not use
/// the Material built-in drag handle.
///
/// Sits slightly below the sheet’s top radius so the pill reads as centered in
/// the grab zone; the sheet remains draggable via the parent sheet.
class BottomSheetCompactDragHandle extends StatelessWidget {
  const BottomSheetCompactDragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      excludeSemantics: true,
      child: Padding(
        padding: EdgeInsets.only(
          top: tokens.gapMd,
          bottom: tokens.gapSm,
        ),
        child: Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}
