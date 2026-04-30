import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';

/// Thin drag affordance for modal bottom sheets when the route does not use
/// the Material built-in drag handle.
///
/// Keeps vertical space tight; the sheet remains draggable via the parent
/// draggable scrollable sheet.
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
          top: tokens.gapXs,
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
