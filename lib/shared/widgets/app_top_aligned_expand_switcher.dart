import 'package:colmeia/shared/design_system/app_motion_tokens.dart';
import 'package:flutter/material.dart';

/// Fade + top-anchored height expand/collapse for overlay menus and panels.
class AppTopAlignedExpandSwitcher extends StatelessWidget {
  const AppTopAlignedExpandSwitcher({
    required this.expanded,
    required this.child,
    super.key,
  });

  final bool expanded;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final motion = context.appMotion;

    return AnimatedSwitcher(
      duration: motion.overlayMenuExpandCollapse,
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            alignment: Alignment.topCenter,
            child: child,
          ),
        );
      },
      child: expanded ? child : const SizedBox.shrink(),
    );
  }
}
