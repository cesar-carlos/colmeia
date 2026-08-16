import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/actions/app_primary_button.dart';
import 'package:colmeia/shared/widgets/actions/app_secondary_button.dart';
import 'package:colmeia/shared/widgets/reports/app_report_column.dart';
import 'package:flutter/material.dart';

/// Opens a bottom sheet where the user can toggle column visibility.
Future<Set<String>?> showAppReportColumnChooser<T>({
  required BuildContext context,
  required List<AppReportColumn<T>> columns,
  required Set<String> currentlyVisible,
}) {
  return showModalBottomSheet<Set<String>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _AppReportColumnChooserSheet<T>(
      columns: columns,
      currentlyVisible: currentlyVisible,
    ),
  );
}

class _AppReportColumnChooserSheet<T> extends StatefulWidget {
  const _AppReportColumnChooserSheet({
    required this.columns,
    required this.currentlyVisible,
  });

  final List<AppReportColumn<T>> columns;
  final Set<String> currentlyVisible;

  @override
  State<_AppReportColumnChooserSheet<T>> createState() =>
      _AppReportColumnChooserSheetState<T>();
}

class _AppReportColumnChooserSheetState<T>
    extends State<_AppReportColumnChooserSheet<T>> {
  late Set<String> _visible;

  @override
  void initState() {
    super.initState();
    _visible = Set<String>.from(widget.currentlyVisible);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final l10n = AppLocalizations.of(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (ctx, scrollController) {
        return Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.fromLTRB(
                tokens.contentSpacing,
                tokens.gapMd,
                tokens.contentSpacing,
                0,
              ),
              child: Row(
                children: <Widget>[
                  Text(
                    l10n.reportColumnsTooltip,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _visible = widget.columns
                            .where((c) => c.visibleByDefault)
                            .map((c) => c.key)
                            .toSet();
                      });
                    },
                    child: Text(l10n.reportColumnChooserReset),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: widget.columns.length,
                itemBuilder: (_, index) {
                  final col = widget.columns[index];
                  return CheckboxListTile(
                    title: Text(col.label),
                    value: _visible.contains(col.key),
                    onChanged: (checked) {
                      setState(() {
                        if (checked ?? false) {
                          _visible.add(col.key);
                        } else {
                          if (_visible.length > 1) {
                            _visible.remove(col.key);
                          }
                        }
                      });
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: EdgeInsets.all(tokens.contentSpacing),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: AppSecondaryButton(
                      fillWidth: true,
                      onPressed: () => Navigator.of(context).pop(),
                      label: l10n.reportColumnChooserCancel,
                    ),
                  ),
                  SizedBox(width: tokens.gapMd),
                  Expanded(
                    child: AppPrimaryButton(
                      fillWidth: true,
                      onPressed: () => Navigator.of(context).pop(_visible),
                      label: l10n.reportColumnChooserApply,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
