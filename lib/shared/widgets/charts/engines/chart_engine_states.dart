import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:flutter/material.dart';

Widget buildChartLoadingState({
  required BuildContext context,
  required double height,
  required Color indicatorColor,
  required String label,
}) {
  final theme = Theme.of(context);
  final colors = theme.appColors;
  final typography = theme.appTypography;

  return SizedBox(
    height: height,
    child: Center(
      child: Semantics(
        container: true,
        liveRegion: true,
        label: label,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircularProgressIndicator(color: indicatorColor),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: typography.body.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget buildChartEmptyState({
  required BuildContext context,
  required double height,
  required String message,
  Widget? placeholder,
}) {
  final theme = Theme.of(context);
  final colors = theme.appColors;
  final typography = theme.appTypography;

  return SizedBox(
    height: height,
    child: Center(
      child:
          placeholder ??
          Text(
            message,
            textAlign: TextAlign.center,
            style: typography.body.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
    ),
  );
}
