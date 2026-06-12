import 'package:flutter/material.dart';

class HorizontalProgressChartHeader extends StatelessWidget {
  const HorizontalProgressChartHeader({
    required this.titleWidget,
    required this.title,
    required this.titleStyle,
    required this.titleTextAlign,
    required this.bottomSpacing,
    super.key,
    this.headerTrailing,
  });

  final Widget? titleWidget;
  final String? title;
  final TextStyle? titleStyle;
  final TextAlign? titleTextAlign;
  final double bottomSpacing;
  final Widget? headerTrailing;

  @override
  Widget build(BuildContext context) {
    final trailing = headerTrailing;
    final custom = titleWidget;
    if (custom != null) {
      return Padding(
        padding: EdgeInsets.only(bottom: bottomSpacing),
        child: trailing == null
            ? custom
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(child: custom),
                  trailing,
                ],
              ),
      );
    }

    final resolvedTitle = title?.trim();
    if (resolvedTitle == null || resolvedTitle.isEmpty) {
      return trailing ?? const SizedBox.shrink();
    }

    final titleText = Text(
      resolvedTitle,
      style: titleStyle,
      textAlign: titleTextAlign,
    );

    return Padding(
      padding: EdgeInsets.only(bottom: bottomSpacing),
      child: trailing == null
          ? titleText
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(child: titleText),
                trailing,
              ],
            ),
    );
  }
}
