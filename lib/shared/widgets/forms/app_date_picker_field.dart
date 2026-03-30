import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class AppDatePickerField extends StatelessWidget {
  const AppDatePickerField({
    required this.onChanged,
    super.key,
    this.label,
    this.helperText,
    this.placeholderText,
    this.pickerTitle,
    this.value,
    this.firstDate,
    this.lastDate,
    this.enabled = true,
    this.errorText,
    this.density = AppTextFieldDensity.comfortable,
  });

  final ValueChanged<DateTime?> onChanged;
  final String? label;
  final String? helperText;
  final String? placeholderText;
  final String? pickerTitle;
  final DateTime? value;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool enabled;
  final String? errorText;
  final AppTextFieldDensity density;

  @override
  Widget build(BuildContext context) {
    return _AppPickerFieldBody(
      label: label,
      helperText: helperText,
      placeholderText: placeholderText ?? 'Selecione uma data',
      displayValue: _formatSingleDate(value),
      errorText: errorText,
      enabled: enabled,
      density: density,
      onTap: () async {
        final selectedDate = await showAppDatePickerSheet(
          context: context,
          title: pickerTitle,
          initialValue: value,
          firstDate: firstDate,
          lastDate: lastDate,
        );
        onChanged(selectedDate);
      },
      onClear: value == null ? null : () => onChanged(null),
    );
  }
}

class AppDateRangePickerField extends StatelessWidget {
  const AppDateRangePickerField({
    required this.onChanged,
    super.key,
    this.label,
    this.helperText,
    this.placeholderText,
    this.pickerTitle,
    this.value,
    this.firstDate,
    this.lastDate,
    this.enabled = true,
    this.errorText,
    this.density = AppTextFieldDensity.comfortable,
  });

  final ValueChanged<DateTimeRange?> onChanged;
  final String? label;
  final String? helperText;
  final String? placeholderText;
  final String? pickerTitle;
  final DateTimeRange? value;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool enabled;
  final String? errorText;
  final AppTextFieldDensity density;

  @override
  Widget build(BuildContext context) {
    return _AppPickerFieldBody(
      label: label,
      helperText: helperText,
      placeholderText: placeholderText ?? 'Selecione o intervalo desejado',
      displayValue: _formatDateRange(value),
      errorText: errorText,
      enabled: enabled,
      density: density,
      onTap: () async {
        final selectedRange = await showAppDateRangePickerSheet(
          context: context,
          title: pickerTitle,
          initialValue: value,
          firstDate: firstDate,
          lastDate: lastDate,
        );
        onChanged(selectedRange);
      },
      onClear: value == null ? null : () => onChanged(null),
    );
  }
}

Future<DateTime?> showAppDatePickerSheet({
  required BuildContext context,
  String? title,
  DateTime? initialValue,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  return showModalBottomSheet<DateTime?>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    clipBehavior: Clip.antiAlias,
    builder: (context) {
      return _AppDatePickerSheet(
        title: title ?? 'Selecionar data',
        initialValue: initialValue,
        firstDate: firstDate,
        lastDate: lastDate,
      );
    },
  );
}

Future<DateTimeRange?> showAppDateRangePickerSheet({
  required BuildContext context,
  String? title,
  DateTimeRange? initialValue,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  return showModalBottomSheet<DateTimeRange?>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    clipBehavior: Clip.antiAlias,
    builder: (context) {
      return _AppDateRangePickerSheet(
        title: title ?? 'Selecionar período',
        initialValue: initialValue,
        firstDate: firstDate,
        lastDate: lastDate,
      );
    },
  );
}

class _AppPickerFieldBody extends StatelessWidget {
  const _AppPickerFieldBody({
    required this.placeholderText,
    required this.enabled,
    required this.density,
    required this.onTap,
    this.label,
    this.helperText,
    this.displayValue,
    this.errorText,
    this.onClear,
  });

  final String? label;
  final String? helperText;
  final String placeholderText;
  final String? displayValue;
  final String? errorText;
  final bool enabled;
  final AppTextFieldDensity density;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>();
    final isEmpty = displayValue == null || displayValue!.isEmpty;
    final horizontal = tokens?.formFieldPaddingHorizontal ?? 16;
    final vertical = density == AppTextFieldDensity.compact
        ? (tokens?.formFieldPaddingVerticalCompact ?? 12)
        : (tokens?.formFieldPaddingVerticalComfortable ?? 16);

    return Semantics(
      button: enabled,
      label: _pickerSemanticsLabel(
        label: label,
        placeholderText: placeholderText,
        displayValue: displayValue,
        isEmpty: isEmpty,
      ),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(tokens?.formFieldRadius ?? 4),
        child: InputDecorator(
          isEmpty: isEmpty,
          decoration: InputDecoration(
            labelText: label,
            helperText: errorText == null ? helperText : null,
            errorText: errorText,
            enabled: enabled,
            prefixIcon: const Icon(Icons.calendar_month_outlined),
            suffixIcon: onClear == null
                ? const Icon(Icons.arrow_drop_down_rounded)
                : IconButton(
                    tooltip: 'Limpar seleção',
                    onPressed: enabled ? onClear : null,
                    icon: const Icon(Icons.close_rounded),
                  ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: horizontal,
              vertical: vertical,
            ),
          ),
          child: Text(
            isEmpty ? placeholderText : displayValue!,
            style: isEmpty
                ? theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  )
                : theme.textTheme.bodyLarge,
          ),
        ),
      ),
    );
  }
}

class _AppDatePickerSheet extends StatefulWidget {
  const _AppDatePickerSheet({
    required this.title,
    this.initialValue,
    this.firstDate,
    this.lastDate,
  });

  final String title;
  final DateTime? initialValue;
  final DateTime? firstDate;
  final DateTime? lastDate;

  @override
  State<_AppDatePickerSheet> createState() => _AppDatePickerSheetState();
}

class _AppDatePickerSheetState extends State<_AppDatePickerSheet> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return _AppPickerSheetScaffold(
      title: widget.title,
      removeSelectionLabel: 'Remover data',
      canApply: _selectedDate != null,
      onRemoveSelection: () {
        Navigator.of(context).pop();
      },
      onApply: () {
        Navigator.of(context).pop<DateTime?>(_selectedDate);
      },
      child: SfDateRangePicker(
        initialSelectedDate: _selectedDate,
        initialDisplayDate: _selectedDate ?? DateTime.now(),
        minDate: widget.firstDate,
        maxDate: widget.lastDate,
        onSelectionChanged: (args) {
          if (args.value is! DateTime) {
            return;
          }
          setState(() {
            _selectedDate = _normalizeDate(args.value as DateTime);
          });
        },
        monthViewSettings: const DateRangePickerMonthViewSettings(
          firstDayOfWeek: 1,
        ),
        showNavigationArrow: true,
        headerStyle: _buildHeaderStyle(context),
        selectionShape: DateRangePickerSelectionShape.rectangle,
        selectionColor: Theme.of(context).colorScheme.primary,
        selectionTextStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onPrimary,
          fontWeight: FontWeight.w600,
        ),
        rangeTextStyle: Theme.of(context).textTheme.bodyMedium,
        todayHighlightColor: Theme.of(context).colorScheme.primary,
        monthCellStyle: _buildMonthCellStyle(context),
      ),
    );
  }
}

class _AppDateRangePickerSheet extends StatefulWidget {
  const _AppDateRangePickerSheet({
    required this.title,
    this.initialValue,
    this.firstDate,
    this.lastDate,
  });

  final String title;
  final DateTimeRange? initialValue;
  final DateTime? firstDate;
  final DateTime? lastDate;

  @override
  State<_AppDateRangePickerSheet> createState() =>
      _AppDateRangePickerSheetState();
}

class _AppDateRangePickerSheetState extends State<_AppDateRangePickerSheet> {
  DateTimeRange? _selectedRange;

  @override
  void initState() {
    super.initState();
    _selectedRange = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _AppPickerSheetScaffold(
      title: widget.title,
      removeSelectionLabel: 'Remover período',
      canApply: _selectedRange != null,
      onRemoveSelection: () {
        Navigator.of(context).pop();
      },
      onApply: () {
        Navigator.of(context).pop<DateTimeRange?>(_selectedRange);
      },
      child: SfDateRangePicker(
        selectionMode: DateRangePickerSelectionMode.range,
        initialSelectedRange: _selectedRange == null
            ? null
            : PickerDateRange(
                _selectedRange!.start,
                _selectedRange!.end,
              ),
        initialDisplayDate: _selectedRange?.start ?? DateTime.now(),
        minDate: widget.firstDate,
        maxDate: widget.lastDate,
        onSelectionChanged: (args) {
          if (args.value is! PickerDateRange) {
            return;
          }
          setState(() {
            _selectedRange = _toDateTimeRange(args.value as PickerDateRange);
          });
        },
        monthViewSettings: const DateRangePickerMonthViewSettings(
          firstDayOfWeek: 1,
        ),
        showNavigationArrow: true,
        headerStyle: _buildHeaderStyle(context),
        selectionShape: DateRangePickerSelectionShape.rectangle,
        selectionColor: theme.colorScheme.primary,
        startRangeSelectionColor: theme.colorScheme.primary,
        endRangeSelectionColor: theme.colorScheme.primary,
        rangeSelectionColor: theme.colorScheme.primaryContainer,
        selectionTextStyle: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onPrimary,
          fontWeight: FontWeight.w600,
        ),
        rangeTextStyle: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
        ),
        todayHighlightColor: theme.colorScheme.primary,
        monthCellStyle: _buildMonthCellStyle(context),
      ),
    );
  }
}

class _AppPickerSheetScaffold extends StatelessWidget {
  const _AppPickerSheetScaffold({
    required this.title,
    required this.removeSelectionLabel,
    required this.canApply,
    required this.onRemoveSelection,
    required this.onApply,
    required this.child,
  });

  final String title;
  final String removeSelectionLabel;
  final bool canApply;
  final VoidCallback onRemoveSelection;
  final VoidCallback onApply;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      minChildSize: 0.64,
      maxChildSize: 0.94,
      builder: (context, scrollController) {
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
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: EdgeInsets.all(tokens.contentSpacing),
                children: <Widget>[
                  child,
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(tokens.contentSpacing),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onRemoveSelection,
                      child: Text(removeSelectionLabel),
                    ),
                  ),
                  SizedBox(width: tokens.gapMd),
                  Expanded(
                    child: FilledButton(
                      onPressed: canApply ? onApply : null,
                      child: const Text('Aplicar'),
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

DateRangePickerHeaderStyle _buildHeaderStyle(BuildContext context) {
  final theme = Theme.of(context);
  return DateRangePickerHeaderStyle(
    textAlign: TextAlign.center,
    textStyle: theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: theme.colorScheme.onSurface,
    ),
  );
}

DateRangePickerMonthCellStyle _buildMonthCellStyle(BuildContext context) {
  final theme = Theme.of(context);
  return DateRangePickerMonthCellStyle(
    textStyle: theme.textTheme.bodyMedium,
    todayTextStyle: theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.w700,
    ),
    disabledDatesTextStyle: theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.32),
    ),
  );
}

DateTime _normalizeDate(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

DateTimeRange? _toDateTimeRange(PickerDateRange value) {
  final startDate = value.startDate;
  final endDate = value.endDate;
  if (startDate == null || endDate == null) {
    return null;
  }

  return DateTimeRange(
    start: _normalizeDate(startDate),
    end: _normalizeDate(endDate),
  );
}

String? _formatSingleDate(DateTime? value) {
  if (value == null) {
    return null;
  }
  return AppBrFormatters.shortDate(value);
}

String? _formatDateRange(DateTimeRange? value) {
  if (value == null) {
    return null;
  }
  return '${AppBrFormatters.shortDate(value.start)} - '
      '${AppBrFormatters.shortDate(value.end)}';
}

String _pickerSemanticsLabel({
  required String? label,
  required String placeholderText,
  required String? displayValue,
  required bool isEmpty,
}) {
  final baseLabel = label ?? 'Data';
  if (isEmpty) {
    return '$baseLabel. $placeholderText';
  }
  return '$baseLabel, ${displayValue ?? ''}';
}
