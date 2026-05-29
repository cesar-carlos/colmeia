import 'dart:async' show unawaited;

import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/actions/app_primary_button.dart';
import 'package:colmeia/shared/widgets/actions/app_secondary_button.dart';
import 'package:colmeia/shared/widgets/forms/app_form_field_message.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';

AppLocalizations? _tryL10n(BuildContext context) =>
    Localizations.of<AppLocalizations>(context, AppLocalizations);

/// Popped when the user taps "Remover data/período" so it is not confused with
/// closing the sheet without applying (`null`).
final Object _appDatePickerClearSentinel = Object();

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
    final l10n = _tryL10n(context);
    return _AppPickerFieldBody(
      label: label,
      helperText: helperText,
      placeholderText:
          placeholderText ??
          l10n?.datePickerPlaceholderSelectDate ??
          'Selecione uma data',
      displayValue: _formatSingleDate(value),
      errorText: errorText,
      enabled: enabled,
      density: density,
      semanticsFallbackLabel: l10n?.datePickerSemanticsFallbackLabel ?? 'Data',
      onOpen: () async {
        final result = await showAppDatePickerSheet(
          context: context,
          title: pickerTitle,
          initialValue: value,
          firstDate: firstDate,
          lastDate: lastDate,
        );
        if (!context.mounted) {
          return;
        }
        if (result == null) {
          return;
        }
        if (identical(result, _appDatePickerClearSentinel)) {
          onChanged(null);
          return;
        }
        if (result is DateTime) {
          onChanged(result);
        }
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

    /// When non-null and [value] is non-null, shown instead of formatted dates.
    this.displayValueWhenFilledOverride,

    /// Extra phrase for accessibility when [displayValueWhenFilledOverride] hides
    /// the concrete dates (e.g. "Custom" with dates in this string).
    this.semanticsDetailWhenFilledOverride,
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
  final String? displayValueWhenFilledOverride;
  final String? semanticsDetailWhenFilledOverride;

  @override
  Widget build(BuildContext context) {
    final l10n = _tryL10n(context);
    final formatted = _formatDateRange(value);
    final useOverride = value != null && displayValueWhenFilledOverride != null;
    final semanticsDetail = useOverride
        ? (semanticsDetailWhenFilledOverride ?? formatted)
        : null;
    return _AppPickerFieldBody(
      label: label,
      helperText: helperText,
      placeholderText:
          placeholderText ??
          l10n?.dateRangePickerPlaceholderSelectPeriod ??
          'Selecione o intervalo desejado',
      displayValue: useOverride ? displayValueWhenFilledOverride : formatted,
      semanticsDetail: semanticsDetail,
      errorText: errorText,
      enabled: enabled,
      density: density,
      semanticsFallbackLabel:
          l10n?.dateRangePickerSemanticsFallbackLabel ?? 'Periodo',
      onOpen: () async {
        final result = await showAppDateRangePickerSheet(
          context: context,
          title: pickerTitle,
          initialValue: value,
          firstDate: firstDate,
          lastDate: lastDate,
        );
        if (!context.mounted) {
          return;
        }
        if (result == null) {
          return;
        }
        if (identical(result, _appDatePickerClearSentinel)) {
          onChanged(null);
          return;
        }
        if (result is DateTimeRange) {
          onChanged(result);
        }
      },
      onClear: value == null ? null : () => onChanged(null),
    );
  }
}

/// Returns the picked [DateTime], `null` if the sheet was dismissed without
/// applying, or a sentinel when the user chose "Remover data".
Future<Object?> showAppDatePickerSheet({
  required BuildContext context,
  String? title,
  DateTime? initialValue,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  return showModalBottomSheet<Object?>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    clipBehavior: Clip.antiAlias,
    builder: (sheetContext) {
      final l10n = _tryL10n(sheetContext);
      return _AppDatePickerSheet(
        title: title ?? l10n?.datePickerSheetDefaultTitle ?? 'Selecionar data',
        initialValue: initialValue,
        firstDate: firstDate,
        lastDate: lastDate,
      );
    },
  );
}

/// Returns the picked [DateTimeRange], `null` if dismissed without applying,
/// or a sentinel when the user chose "Remover período".
Future<Object?> showAppDateRangePickerSheet({
  required BuildContext context,
  String? title,
  DateTimeRange? initialValue,
  DateTime? firstDate,
  DateTime? lastDate,
}) {
  return showModalBottomSheet<Object?>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    clipBehavior: Clip.antiAlias,
    builder: (sheetContext) {
      final l10n = _tryL10n(sheetContext);
      return _AppDateRangePickerSheet(
        title:
            title ??
            l10n?.dateRangePickerSheetDefaultTitle ??
            'Selecionar período',
        initialValue: initialValue,
        firstDate: firstDate,
        lastDate: lastDate,
      );
    },
  );
}

class _AppPickerFieldBody extends StatefulWidget {
  const _AppPickerFieldBody({
    required this.placeholderText,
    required this.enabled,
    required this.density,
    required this.onOpen,
    required this.semanticsFallbackLabel,
    this.label,
    this.helperText,
    this.displayValue,
    this.semanticsDetail,
    this.errorText,
    this.onClear,
  });

  final String? label;
  final String? helperText;
  final String placeholderText;
  final String? displayValue;
  final String? semanticsDetail;
  final String? errorText;
  final bool enabled;
  final AppTextFieldDensity density;
  final String semanticsFallbackLabel;
  final Future<void> Function() onOpen;
  final VoidCallback? onClear;

  @override
  State<_AppPickerFieldBody> createState() => _AppPickerFieldBodyState();
}

class _AppPickerFieldBodyState extends State<_AppPickerFieldBody> {
  bool _openInProgress = false;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode(debugLabel: 'AppPickerFieldBody');
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    if (!widget.enabled || _openInProgress) {
      return;
    }
    setState(() => _openInProgress = true);
    _focusNode.requestFocus();
    try {
      await widget.onOpen();
    } finally {
      if (mounted) {
        setState(() => _openInProgress = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final colors = theme.appColors;
    final scheme = theme.colorScheme;
    final l10n = _tryL10n(context);
    final hasError = widget.errorText?.trim().isNotEmpty ?? false;
    final isEmpty = widget.displayValue == null || widget.displayValue!.isEmpty;
    final compact = widget.density == AppTextFieldDensity.compact;

    final borderRadius = BorderRadius.circular(tokens.formFieldRadius + 2);
    final borderSide = resolveFormFieldBorderSide(
      colors: colors,
      scheme: scheme,
      enabled: widget.enabled,
      focused: _openInProgress,
      hasError: hasError,
    );
    final padding = EdgeInsets.symmetric(
      horizontal: tokens.formFieldPaddingHorizontal,
      vertical: compact
          ? tokens.formFieldPaddingVerticalCompact
          : tokens.formFieldPaddingVerticalComfortable,
    );
    final labelGap = compact ? tokens.gapXs : tokens.formLabelToControlGap;

    return Semantics(
      button: widget.enabled,
      label: _pickerSemanticsLabel(
        label: widget.label,
        placeholderText: widget.placeholderText,
        displayValue: widget.displayValue,
        semanticsDetail: widget.semanticsDetail,
        isEmpty: isEmpty,
        fallbackRoleLabel: widget.semanticsFallbackLabel,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (widget.label case final String label) ...<Widget>[
            Text(
              label.toUpperCase(),
              style: typography.utilityOverline.copyWith(
                color: hasError ? scheme.error : colors.onSurfaceVariant,
              ),
            ),
            SizedBox(height: labelGap),
          ],
          Focus(
            focusNode: _focusNode,
            skipTraversal: !widget.enabled,
            canRequestFocus: widget.enabled,
            onKeyEvent: (node, event) {
              if (!widget.enabled) {
                return KeyEventResult.ignored;
              }
              if (event is! KeyDownEvent) {
                return KeyEventResult.ignored;
              }
              if (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.numpadEnter ||
                  event.logicalKey == LogicalKeyboardKey.space) {
                unawaited(_activate());
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.enabled ? _activate : null,
                borderRadius: borderRadius,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  curve: Curves.easeOut,
                  decoration: BoxDecoration(
                    color: widget.enabled
                        ? scheme.surfaceContainerLowest
                        : scheme.surfaceContainerLow.withValues(alpha: 0.56),
                    borderRadius: borderRadius,
                    border: Border.fromBorderSide(borderSide),
                  ),
                  padding: padding,
                  child: Row(
                    children: <Widget>[
                      _LeadingCalendarChip(enabled: widget.enabled),
                      SizedBox(width: tokens.gapMd),
                      Expanded(
                        child: Text(
                          isEmpty
                              ? widget.placeholderText
                              : widget.displayValue!,
                          style: typography.body.copyWith(
                            color: widget.enabled
                                ? (isEmpty
                                      ? colors.onSurfaceVariant
                                      : colors.onSurface)
                                : colors.onSurface.withValues(alpha: 0.38),
                            fontWeight: isEmpty
                                ? FontWeight.w500
                                : FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: tokens.gapSm),
                      _TrailingPickerControl(
                        enabled: widget.enabled,
                        open: _openInProgress,
                        onClear: widget.onClear,
                        clearTooltip:
                            l10n?.datePickerClearSelectionTooltip ??
                            'Limpar seleção',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          AppFormFieldMessage(
            helperText: widget.helperText,
            errorText: widget.errorText,
          ),
        ],
      ),
    );
  }
}

class _LeadingCalendarChip extends StatelessWidget {
  const _LeadingCalendarChip({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.calendar_month_outlined,
        size: 18,
        color: enabled
            ? colors.onSurfaceVariant
            : colors.onSurface.withValues(alpha: 0.38),
      ),
    );
  }
}

class _TrailingPickerControl extends StatelessWidget {
  const _TrailingPickerControl({
    required this.enabled,
    required this.open,
    required this.onClear,
    required this.clearTooltip,
  });

  final bool enabled;
  final bool open;
  final VoidCallback? onClear;
  final String clearTooltip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.appColors;

    if (onClear != null) {
      return InkWell(
        onTap: enabled ? onClear : null,
        borderRadius: BorderRadius.circular(999),
        child: Tooltip(
          message: clearTooltip,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Icon(
              Icons.close_rounded,
              size: 20,
              color: enabled
                  ? colors.onSurfaceVariant
                  : colors.onSurface.withValues(alpha: 0.38),
            ),
          ),
        ),
      );
    }

    return AnimatedRotation(
      duration: const Duration(milliseconds: 140),
      turns: open ? 0.5 : 0,
      child: Icon(
        Icons.expand_more_rounded,
        size: 24,
        color: enabled
            ? colors.outline
            : colors.onSurface.withValues(alpha: 0.38),
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
    _selectedDate = widget.initialValue == null
        ? null
        : _normalizeDate(widget.initialValue!);
  }

  @override
  void didUpdateWidget(covariant _AppDatePickerSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      setState(() {
        _selectedDate = widget.initialValue == null
            ? null
            : _normalizeDate(widget.initialValue!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = _tryL10n(context);
    final canRemove = widget.initialValue != null || _selectedDate != null;
    return _AppPickerSheetScaffold(
      title: widget.title,
      removeSelectionLabel: l10n?.datePickerSheetRemoveDate ?? 'Remover data',
      applyButtonLabel: l10n?.datePickerSheetApply ?? 'Aplicar',
      closeButtonTooltip: l10n?.datePickerSheetCloseTooltip ?? 'Fechar',
      canRemoveSelection: canRemove,
      canApply: _selectedDate != null,
      onRemoveSelection: () {
        if (!context.mounted) {
          return;
        }
        Navigator.of(context).pop<Object?>(_appDatePickerClearSentinel);
      },
      onApply: () {
        final picked = _selectedDate;
        if (picked == null) {
          return;
        }
        if (!context.mounted) {
          return;
        }
        Navigator.of(context).pop<DateTime>(picked);
      },
      child: RepaintBoundary(
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
          selectionColor: theme.colorScheme.primary,
          selectionTextStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
          rangeTextStyle: theme.textTheme.bodyMedium,
          todayHighlightColor: theme.colorScheme.primary,
          monthCellStyle: _buildMonthCellStyle(context),
        ),
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
  void didUpdateWidget(covariant _AppDateRangePickerSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      setState(() => _selectedRange = widget.initialValue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>();
    final l10n = _tryL10n(context);
    final canRemove = widget.initialValue != null || _selectedRange != null;

    return _AppPickerSheetScaffold(
      initialChildSize: 0.74,
      minChildSize: 0.52,
      title: widget.title,
      removeSelectionLabel:
          l10n?.dateRangePickerSheetRemovePeriod ?? 'Remover período',
      applyButtonLabel: l10n?.datePickerSheetApply ?? 'Aplicar',
      closeButtonTooltip: l10n?.datePickerSheetCloseTooltip ?? 'Fechar',
      canRemoveSelection: canRemove,
      canApply: _selectedRange != null,
      onRemoveSelection: () {
        if (!context.mounted) {
          return;
        }
        Navigator.of(context).pop<Object?>(_appDatePickerClearSentinel);
      },
      onApply: () {
        final picked = _selectedRange;
        if (picked == null) {
          return;
        }
        if (!context.mounted) {
          return;
        }
        Navigator.of(context).pop<DateTimeRange>(picked);
      },
      child: RepaintBoundary(
        child: SfDateRangePicker(
          selectionMode: DateRangePickerSelectionMode.range,
          enableMultiView: true,
          viewSpacing: tokens?.gapSm ?? 8,
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
      ),
    );
  }
}

class _AppPickerSheetScaffold extends StatelessWidget {
  const _AppPickerSheetScaffold({
    required this.title,
    required this.removeSelectionLabel,
    required this.applyButtonLabel,
    required this.closeButtonTooltip,
    required this.canRemoveSelection,
    required this.canApply,
    required this.onRemoveSelection,
    required this.onApply,
    required this.child,
    this.initialChildSize = 0.62,
    this.minChildSize = 0.48,
  });

  final double initialChildSize;
  final double minChildSize;
  final String title;
  final String removeSelectionLabel;
  final String applyButtonLabel;
  final String closeButtonTooltip;
  final bool canRemoveSelection;
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
      initialChildSize: initialChildSize,
      minChildSize: minChildSize,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.fromLTRB(
                tokens.contentSpacing,
                tokens.gapSm,
                tokens.contentSpacing,
                tokens.gapSm,
              ),
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
                    tooltip: closeButtonTooltip,
                    onPressed: () {
                      if (!context.mounted) {
                        return;
                      }
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: EdgeInsets.all(tokens.contentSpacing),
                child: child,
              ),
            ),
            Padding(
              padding: EdgeInsets.all(tokens.contentSpacing),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: AppSecondaryButton(
                      fillWidth: true,
                      label: removeSelectionLabel,
                      onPressed: canRemoveSelection ? onRemoveSelection : null,
                    ),
                  ),
                  SizedBox(width: tokens.gapMd),
                  Expanded(
                    child: AppPrimaryButton(
                      fillWidth: true,
                      label: applyButtonLabel,
                      onPressed: canApply ? onApply : null,
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
  required String? semanticsDetail,
  required bool isEmpty,
  required String fallbackRoleLabel,
}) {
  final baseLabel = label ?? fallbackRoleLabel;
  if (isEmpty) {
    return '$baseLabel. $placeholderText';
  }
  final detail = semanticsDetail?.trim();
  if (detail != null && detail.isNotEmpty) {
    return '$baseLabel, ${displayValue ?? ''}, $detail';
  }
  return '$baseLabel, ${displayValue ?? ''}';
}
