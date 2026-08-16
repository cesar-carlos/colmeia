import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Disables descendant [Tooltip] semantics on Windows inside map overlay cards.
///
/// On Windows, [IconButton] + [Tooltip] publish tooltip semantics through the
/// overlay layer. That fights marker detail [ExcludeSemantics] boundaries and
/// triggers `accessibility_bridge.cc` AXTree errors when hovering branch map
/// cards.
class AppBrazilStoreSalesMapOverlayTooltipScope extends StatelessWidget {
  const AppBrazilStoreSalesMapOverlayTooltipScope({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TooltipVisibility(
      visible: defaultTargetPlatform != TargetPlatform.windows,
      child: child,
    );
  }
}

/// Icon control for map overlay rows: avoids [IconButton] tooltips on Windows.
/// Pass [onPressed] as null to disable the button.
class AppBrazilStoreSalesMapWindowsSafeOverlayIconButton
    extends StatelessWidget {
  const AppBrazilStoreSalesMapWindowsSafeOverlayIconButton({
    required this.icon,
    required this.onPressed,
    required this.tooltipMessage,
    required this.dimension,
    super.key,
    this.iconSize,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltipMessage;
  final double dimension;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    if (defaultTargetPlatform == TargetPlatform.windows) {
      final colors = Theme.of(context).colorScheme;
      final resolvedIconSize = iconSize ?? dimension * 0.56;
      final isDisabled = onPressed == null;
      return Semantics(
        button: true,
        enabled: !isDisabled,
        label: tooltipMessage,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox(
              width: dimension,
              height: dimension,
              child: Icon(
                icon,
                size: resolvedIconSize,
                color: isDisabled
                    ? colors.onSurface.withValues(alpha: 0.38)
                    : colors.onSurface,
              ),
            ),
          ),
        ),
      );
    }

    return Tooltip(
      message: tooltipMessage,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: iconSize),
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: BoxConstraints.tightFor(
          width: dimension,
          height: dimension,
        ),
      ),
    );
  }
}
