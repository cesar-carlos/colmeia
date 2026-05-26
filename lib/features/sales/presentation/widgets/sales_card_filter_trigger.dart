import 'package:colmeia/features/sales/presentation/widgets/sales_filter_circle_palette.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:flutter/material.dart';

const double _kSalesFilterCircleSize = 44;

class SalesCardFilterSummaryItem {
  const SalesCardFilterSummaryItem({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

class SalesCardFilterTrigger extends StatelessWidget {
  const SalesCardFilterTrigger({
    required this.summaryItems,
    required this.onTap,
    required this.buttonSemanticsLabel,
    super.key,
    this.enabled = true,
  }) : assert(summaryItems.length > 0, 'summaryItems cannot be empty');

  final List<SalesCardFilterSummaryItem> summaryItems;
  final VoidCallback onTap;
  final String buttonSemanticsLabel;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final colors = theme.appColors;
    final scheme = theme.colorScheme;

    void open() {
      if (!enabled) {
        return;
      }
      onTap();
    }

    Widget summaryBlock(SalesCardFilterSummaryItem item) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            item.label.toUpperCase(),
            style: typography.utilityOverline.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          SizedBox(height: tokens.gapXs),
          Semantics(
            button: true,
            label: '${item.label}: ${item.value}',
            child: InkWell(
              onTap: enabled ? open : null,
              borderRadius: BorderRadius.circular(tokens.formFieldRadius),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: tokens.gapXs),
                child: Text(
                  item.value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: typography.body.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return AppSectionCard(
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          Padding(
            padding: EdgeInsetsDirectional.only(
              end: _kSalesFilterCircleSize + tokens.gapSm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (var i = 0; i < summaryItems.length; i++) ...<Widget>[
                  summaryBlock(summaryItems[i]),
                  if (i < summaryItems.length - 1)
                    SizedBox(height: tokens.gapSm),
                ],
              ],
            ),
          ),
          PositionedDirectional(
            end: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: Semantics(
                button: true,
                label: buttonSemanticsLabel,
                child: Material(
                  color: SalesFilterCirclePalette.fill,
                  shape: const CircleBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: enabled ? open : null,
                    child: SizedBox(
                      width: _kSalesFilterCircleSize,
                      height: _kSalesFilterCircleSize,
                      child: Icon(
                        Icons.filter_list_rounded,
                        size: 22,
                        color: enabled
                            ? SalesFilterCirclePalette.icon
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
