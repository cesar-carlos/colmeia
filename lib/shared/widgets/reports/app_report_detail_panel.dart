import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
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

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      builder: (ctx, scrollController) {
        return Column(
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
              padding: EdgeInsets.symmetric(horizontal: tokens.contentSpacing),
              child: Row(
                children: <Widget>[
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Fechar',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                padding: EdgeInsets.all(tokens.contentSpacing),
                itemCount: columns.length,
                separatorBuilder: (_, _) => Divider(
                  height: tokens.gapMd * 2,
                  color: theme.colorScheme.outlineVariant,
                ),
                itemBuilder: (_, index) {
                  final col = columns[index];
                  final value = col.valueGetter(row);
                  final displayText = col.formatValue(value);

                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(
                        width: 120,
                        child: Text(
                          col.label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      SizedBox(width: tokens.gapMd),
                      Expanded(
                        child: col.cellBuilder != null
                            ? col.cellBuilder!(context, row, value)
                            : Text(
                                displayText,
                                style: col.textStyle ??
                                    theme.textTheme.bodyMedium,
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
