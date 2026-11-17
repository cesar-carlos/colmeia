import 'package:material_ui/material_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

ShimmerEffect appSkeletonEffect(ColorScheme colors) => ShimmerEffect(
  baseColor: colors.surfaceContainerHighest,
  highlightColor: colors.surfaceContainerHigh,
);
