import 'package:colmeia/shared/widgets/app_status_badge.dart';
import 'package:flutter/material.dart';

class AppProfileStatusPill extends StatelessWidget {
  const AppProfileStatusPill({
    required this.label,
    super.key,
    this.foreground,
    this.background,
    this.borderColor,
    this.variant = AppStatusBadgeVariant.neutral,
  });

  final String label;
  final Color? foreground;
  final Color? background;
  final Color? borderColor;
  final AppStatusBadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    return AppStatusBadge(
      label: label,
      variant: variant,
      foregroundColor: foreground,
      backgroundColor: background,
      borderColor: borderColor,
    );
  }
}
