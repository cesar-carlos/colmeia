import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/actions/app_flat_button.dart';
import 'package:colmeia/shared/widgets/app_tag_chip.dart';
import 'package:colmeia/shared/widgets/reports/app_report_column.dart';
import 'package:flutter/material.dart';

/// Opens a bottom sheet showing all column values of the selected row as
/// key-value pairs. Useful on compact screens where not all columns fit.
Future<void> showAppReportDetailPanel<T>({
  required BuildContext context,
  required T row,
  required List<AppReportColumn<T>> columns,
  String title = 'Detalhes',
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _AppReportDetailSheet<T>(
      row: row,
      columns: columns,
      title: title,
    ),
  );
}

class _AppReportDetailSheet<T> extends StatelessWidget {
  const _AppReportDetailSheet({
    required this.row,
    required this.columns,
    required this.title,
  });

  final T row;
  final List<AppReportColumn<T>> columns;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final colors = theme.appColors;
    final typography = theme.appTypography;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (ctx, scrollController) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(tokens.cardRadius + 4),
            ),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Column(
            children: <Widget>[
              Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.symmetric(vertical: tokens.gapSm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: tokens.contentSpacing,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxWidth < 360;
                    final heading = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          title,
                          style: typography.sectionHeaderH2.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: tokens.gapXs),
                        Wrap(
                          spacing: tokens.gapSm,
                          runSpacing: tokens.gapSm,
                          children: <Widget>[
                            AppTagChip(label: '${columns.length} campos'),
                            const AppTagChip(label: 'Detalhe da linha'),
                          ],
                        ),
                      ],
                    );

                    if (isCompact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          heading,
                          SizedBox(height: tokens.gapSm),
                          Align(
                            alignment: Alignment.centerRight,
                            child: AppFlatButton(
                              onPressed: () => Navigator.of(context).pop(),
                              fillWidth: false,
                              child: const Icon(Icons.close_rounded),
                            ),
                          ),
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(child: heading),
                        SizedBox(width: tokens.gapMd),
                        AppFlatButton(
                          onPressed: () => Navigator.of(context).pop(),
                          fillWidth: false,
                          child: const Icon(Icons.close_rounded),
                        ),
                      ],
                    );
                  },
                ),
              ),
              SizedBox(height: tokens.gapMd),
              Divider(
                height: 1,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
              ),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: EdgeInsets.all(tokens.contentSpacing),
                  itemCount: columns.length,
                  separatorBuilder: (_, _) => SizedBox(height: tokens.gapSm),
                  itemBuilder: (_, index) {
                    final col = columns[index];
                    final value = col.valueGetter(row);
                    final displayText = col.formatValue(value);

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 420;
                        final valueWidget = col.cellBuilder != null
                            ? col.cellBuilder!(context, row, value)
                            : Text(
                                displayText,
                                style: col.textStyle ?? typography.body,
                              );

                        return DecoratedBox(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(
                              tokens.formFieldRadius,
                            ),
                            border: Border.all(
                              color: theme.colorScheme.outlineVariant
                                  .withValues(
                                    alpha: 0.32,
                                  ),
                            ),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(tokens.gapMd),
                            child: compact
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        col.label,
                                        style: typography.utilityOverline
                                            .copyWith(
                                              color: colors.onSurfaceVariant,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      SizedBox(height: tokens.gapXs),
                                      valueWidget,
                                    ],
                                  )
                                : Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      SizedBox(
                                        width: 132,
                                        child: Text(
                                          col.label,
                                          style: typography.utilityOverline
                                              .copyWith(
                                                color: colors.onSurfaceVariant,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                      SizedBox(width: tokens.gapMd),
                                      Expanded(child: valueWidget),
                                    ],
                                  ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
