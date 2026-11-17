import 'package:colmeia/core/layout/app_breakpoints.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:material_ui/material_ui.dart';

class AppResponsiveFieldPair extends StatelessWidget {
  const AppResponsiveFieldPair({
    required this.first,
    required this.second,
    required this.spacing,
    super.key,
  });

  final Widget first;
  final Widget second;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final fontSize = Theme.of(context).appTypography.body.fontSize!;
    final textScale =
        MediaQuery.textScalerOf(context).scale(fontSize) / fontSize;
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked =
            constraints.maxWidth <
            AppBreakpoints.reportColumnHideNarrow * textScale;
        return Flex(
          direction: stacked ? Axis.vertical : Axis.horizontal,
          crossAxisAlignment: stacked
              ? CrossAxisAlignment.stretch
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(flex: stacked ? 0 : 1, child: first),
            SizedBox(
              width: stacked ? 0 : spacing,
              height: stacked ? spacing : 0,
            ),
            Expanded(flex: stacked ? 0 : 1, child: second),
          ],
        );
      },
    );
  }
}
