import 'package:flutter/material.dart';

/// Max width for stacked value labels above a comparison bar so long ticket
/// lines ellipsize instead of wrapping into a third visual row.
const double kComparisonBarValueLabelMaxWidth = 108;

/// Builds the value label shown above comparison bar columns. Multi-line
/// strings (`\n`) render as a tight column with explicit line spacing so
/// lines do not overlap.
Widget buildComparisonBarOuterValueLabel({
  required String text,
  required TextStyle baseStyle,
  required ColorScheme colorScheme,
  Color? backgroundColor,
  double maxWidth = kComparisonBarValueLabelMaxWidth,
}) {
  final lines = text.split(RegExp(r'\r?\n'));
  final onSurface = baseStyle.color ?? colorScheme.onSurface;
  final primaryStyle = baseStyle.copyWith(
    color: onSurface,
    height: 1.2,
    fontWeight: baseStyle.fontWeight ?? FontWeight.w600,
  );
  final secondaryFontSize = (primaryStyle.fontSize ?? 12) - 1;
  final secondaryStyle = primaryStyle.copyWith(
    fontSize: secondaryFontSize > 8 ? secondaryFontSize : 11,
    fontWeight: FontWeight.w500,
    color: colorScheme.onSurfaceVariant,
    height: 1.15,
  );

  Widget content;
  if (lines.length <= 1) {
    content = Text(
      text,
      style: primaryStyle,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  } else {
    final children = <Widget>[];
    for (var i = 0; i < lines.length; i++) {
      if (i > 0) {
        children.add(const SizedBox(height: 2));
      }
      children.add(
        Text(
          lines[i],
          style: i == 0 ? primaryStyle : secondaryStyle,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
        ),
      );
    }
    content = Column(
      mainAxisSize: MainAxisSize.min,
      children: children,
    );
  }

  content = ConstrainedBox(
    constraints: BoxConstraints(maxWidth: maxWidth),
    child: content,
  );

  if (backgroundColor != null) {
    content = DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: content,
      ),
    );
  }

  return content;
}
