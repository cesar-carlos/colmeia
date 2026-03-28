import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';

class AppSectionCard extends StatelessWidget {
  const AppSectionCard({
    required this.child,
    super.key,
    this.padding,
    this.color,
    this.borderRadius,
    this.borderSide,
    this.decoration,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  /// When null, [Card] uses [ThemeData.cardTheme] (tonal surface).
  ///
  /// Ignored when [decoration] is non-null (the card uses a transparent
  /// material so the decoration paints the background).
  final Color? color;

  /// When null with [borderSide], defaults to [AppThemeTokens.cardRadius].
  /// When both are null, [Card.shape] comes from [ThemeData.cardTheme].
  final BorderRadiusGeometry? borderRadius;

  /// Outline for the card shape; width zero draws no visible stroke.
  final BorderSide? borderSide;

  /// Optional background (gradient, image, etc.). When set, [color] is not
  /// applied to [Card]; align corners with [borderRadius] / theme radius.
  final Decoration? decoration;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(
      context,
    ).extension<AppThemeTokens>()!;

    final ShapeBorder? shape = (borderRadius != null || borderSide != null)
        ? RoundedRectangleBorder(
            borderRadius:
                borderRadius ?? BorderRadius.circular(tokens.cardRadius),
            side: borderSide ?? BorderSide.none,
          )
        : null;

    final resolvedPadding =
        padding ?? EdgeInsets.all(tokens.contentSpacing);

    final paddedChild = Padding(
      padding: resolvedPadding,
      child: child,
    );

    final hasDecoration = decoration != null;
    final cardChild = hasDecoration
        ? DecoratedBox(
            decoration: decoration!,
            child: paddedChild,
          )
        : paddedChild;

    return Card(
      color: hasDecoration ? Colors.transparent : color,
      surfaceTintColor: hasDecoration ? Colors.transparent : null,
      shape: shape,
      clipBehavior: hasDecoration ? Clip.antiAlias : Clip.none,
      child: cardChild,
    );
  }
}
