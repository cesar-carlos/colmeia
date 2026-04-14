import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:flutter/material.dart';

/// Constrains page-level content to [AppBreakpoints.pageContentMaxWidth]
/// and centers it on desktop when the persistent rail is shown
/// ([AppBreakpoints.useRail]).
/// Applied globally by the authenticated app shell for routed content.
class AppContentConstraint extends StatelessWidget {
  const AppContentConstraint({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!AppBreakpoints.useRail(context)) return child;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: AppBreakpoints.pageContentMaxWidth,
        ),
        child: child,
      ),
    );
  }
}
