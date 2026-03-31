import 'package:flutter/material.dart';

/// Shared [CircularProgressIndicator] sizing for action buttons (loading).
Widget buildAppActionButtonProgressIndicator({
  required Color color,
  required double size,
  required double strokeWidth,
}) {
  return SizedBox(
    width: size,
    height: size,
    child: CircularProgressIndicator(
      strokeWidth: strokeWidth,
      color: color,
    ),
  );
}

/// Wraps a Material action button with consistent [Semantics] for loading and
/// optional [semanticsLabel].
Widget wrapAppActionButtonSemantics({
  required Widget child,
  required bool isLoading,
  required VoidCallback? onPressed,
  String? semanticsLabel,
  String? labelForLoadingAnnouncement,
}) {
  final enabled = onPressed != null && !isLoading;
  if (semanticsLabel != null) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticsLabel,
      excludeSemantics: isLoading,
      child: child,
    );
  }
  if (isLoading) {
    final loadingAnnouncement = labelForLoadingAnnouncement != null
        ? 'Carregando: $labelForLoadingAnnouncement'
        : 'Carregando';
    return Semantics(
      button: true,
      enabled: enabled,
      label: loadingAnnouncement,
      excludeSemantics: true,
      child: child,
    );
  }
  return child;
}
