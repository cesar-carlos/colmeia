import 'package:flutter/material.dart';

/// Plot on top (typically in an [Expanded]) plus a compact pan hint under the
/// chart, without a fixed-height footer slot.
///
/// Used by category-axis pan layouts in the Syncfusion comparison bar chart
/// and combo chart engines so footnote spacing stays consistent across chart
/// types.
class ChartPanFootnoteColumn extends StatelessWidget {
  const ChartPanFootnoteColumn({
    required this.plot,
    required this.footnoteText,
    super.key,
  });

  final Widget plot;
  final String footnoteText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Expanded(child: plot),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
          child: Text(
            footnoteText,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}
