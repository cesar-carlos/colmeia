import 'dart:async';

import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/forms/app_dropdown_field.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:flutter/material.dart';

/// Compact horizontal filter bar rendered inside the grid card.
///
/// Renders each supported filter as a compact, labeled field and applies
/// changes immediately via [onFiltersChanged] — no submit button required.
///
/// Supported types: [AppReportFilterType.text], [AppReportFilterType.search],
/// [AppReportFilterType.singleSelect], [AppReportFilterType.dateRange] and
/// [AppReportFilterType.date]. Other types are silently skipped; use
/// `AppReportFiltersPanel` for complex sets including multiSelect, toggle or
/// numericRange.
class AppReportInlineFiltersBar extends StatefulWidget {
  const AppReportInlineFiltersBar({
    required this.filters,
    required this.onFiltersChanged,
    super.key,
    this.initialValues = const <String, Object?>{},
    this.isLoading = false,
    this.debounceDuration = Duration.zero,
    this.showAdvancedFiltersButton = false,
    this.onOpenAdvancedFilters,
  });

  final List<AppReportFilterDescriptor> filters;
  final ValueChanged<Map<String, Object?>> onFiltersChanged;
  final Map<String, Object?> initialValues;
  final bool isLoading;
  final Duration debounceDuration;
  final bool showAdvancedFiltersButton;
  final VoidCallback? onOpenAdvancedFilters;

  @override
  State<AppReportInlineFiltersBar> createState() =>
      _AppReportInlineFiltersBarState();
}

class _AppReportInlineFiltersBarState extends State<AppReportInlineFiltersBar> {
  late final Map<String, TextEditingController> _textControllers;
  final Map<String, Timer> _textDebouncers = <String, Timer>{};
  late Map<String, Object?> _currentValues;

  static bool _isTextType(AppReportFilterDescriptor f) =>
      f.type == AppReportFilterType.text ||
      f.type == AppReportFilterType.search;

  static bool _supportsInline(AppReportFilterType type) => switch (type) {
    AppReportFilterType.text => true,
    AppReportFilterType.search => true,
    AppReportFilterType.singleSelect => true,
    AppReportFilterType.dateRange => true,
    AppReportFilterType.date => true,
    _ => false,
  };

  @override
  void initState() {
    super.initState();
    _currentValues = Map<String, Object?>.from(widget.initialValues);
    _textControllers = <String, TextEditingController>{
      for (final f in widget.filters.where(_isTextType))
        f.name: TextEditingController(
          text: widget.initialValues[f.name] as String? ?? '',
        ),
    };
  }

  @override
  void didUpdateWidget(covariant AppReportInlineFiltersBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValues != widget.initialValues) {
      _currentValues = Map<String, Object?>.from(widget.initialValues);
      for (final entry in _textControllers.entries) {
        final newText = widget.initialValues[entry.key] as String? ?? '';
        if (entry.value.text != newText) {
          entry.value.text = newText;
        }
      }
    }
  }

  @override
  void dispose() {
    for (final timer in _textDebouncers.values) {
      timer.cancel();
    }
    for (final c in _textControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _hasActiveFilters => _currentValues.values.any((v) {
    return switch (v) {
      null => false,
      final String s => s.trim().isNotEmpty,
      final Iterable<Object?> list => list.isNotEmpty,
      _ => true,
    };
  });

  void _clearAll() {
    for (final timer in _textDebouncers.values) {
      timer.cancel();
    }
    setState(() {
      _currentValues = <String, Object?>{};
      for (final c in _textControllers.values) {
        c.clear();
      }
    });
    widget.onFiltersChanged(const <String, Object?>{});
  }

  void _emit(Map<String, Object?> updated) {
    setState(() => _currentValues = updated);
    widget.onFiltersChanged(Map<String, Object?>.from(updated));
  }

  void _emitTextChange(String name, String text) {
    final updated = Map<String, Object?>.from(_currentValues);
    if (text.trim().isEmpty) {
      updated.remove(name);
    } else {
      updated[name] = text;
    }

    final debounce = widget.debounceDuration;
    if (debounce == Duration.zero) {
      _emit(updated);
      return;
    }

    setState(() => _currentValues = updated);
    _textDebouncers[name]?.cancel();
    _textDebouncers[name] = Timer(debounce, () {
      if (!mounted) {
        return;
      }
      widget.onFiltersChanged(Map<String, Object?>.from(updated));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;

    final supported = widget.filters
        .where((f) => _supportsInline(f.type))
        .toList(growable: false);
    final hasAdvancedFilters =
        widget.showAdvancedFiltersButton &&
        widget.filters.any((f) => !_supportsInline(f.type));

    if (supported.isEmpty && !hasAdvancedFilters) {
      return const SizedBox.shrink();
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: tokens.contentSpacing,
          vertical: tokens.gapMd,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 600;
            return isNarrow
                ? _buildWrapped(context, tokens, supported, hasAdvancedFilters)
                : _buildScrollable(
                    context,
                    tokens,
                    supported,
                    hasAdvancedFilters,
                  );
          },
        ),
      ),
    );
  }

  Widget _buildScrollable(
    BuildContext context,
    AppThemeTokens tokens,
    List<AppReportFilterDescriptor> filters,
    bool hasAdvancedFilters,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          ...filters.indexed.expand<Widget>((entry) {
            final i = entry.$1;
            final f = entry.$2;
            return <Widget>[
              if (i > 0) SizedBox(width: tokens.gapMd),
              _InlineFilterField(
                descriptor: f,
                currentValues: _currentValues,
                textController: _textControllers[f.name],
                isLoading: widget.isLoading,
                onChanged: _emit,
                onTextChanged: (text) => _emitTextChange(f.name, text),
              ),
            ];
          }),
          if (_hasActiveFilters) ...<Widget>[
            SizedBox(width: tokens.gapSm),
            _ClearButton(onClear: _clearAll),
          ],
          if (hasAdvancedFilters) ...<Widget>[
            SizedBox(width: tokens.gapSm),
            _AdvancedFiltersButton(onPressed: widget.onOpenAdvancedFilters),
          ],
        ],
      ),
    );
  }

  Widget _buildWrapped(
    BuildContext context,
    AppThemeTokens tokens,
    List<AppReportFilterDescriptor> filters,
    bool hasAdvancedFilters,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: tokens.gapMd,
          runSpacing: tokens.gapMd,
          children: filters
              .map(
                (f) => _InlineFilterField(
                  descriptor: f,
                  currentValues: _currentValues,
                  textController: _textControllers[f.name],
                  isLoading: widget.isLoading,
                  onChanged: _emit,
                  onTextChanged: (text) => _emitTextChange(f.name, text),
                ),
              )
              .toList(growable: false),
        ),
        if (_hasActiveFilters) ...<Widget>[
          SizedBox(height: tokens.gapSm),
          Align(
            alignment: Alignment.centerRight,
            child: _ClearButton(onClear: _clearAll),
          ),
        ],
        if (hasAdvancedFilters) ...<Widget>[
          SizedBox(height: tokens.gapSm),
          Align(
            alignment: Alignment.centerRight,
            child: _AdvancedFiltersButton(
              onPressed: widget.onOpenAdvancedFilters,
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Individual field
// ---------------------------------------------------------------------------

class _InlineFilterField extends StatelessWidget {
  const _InlineFilterField({
    required this.descriptor,
    required this.currentValues,
    required this.onChanged,
    required this.onTextChanged,
    this.textController,
    this.isLoading = false,
  });

  final AppReportFilterDescriptor descriptor;
  final Map<String, Object?> currentValues;
  final TextEditingController? textController;
  final bool isLoading;
  final ValueChanged<Map<String, Object?>> onChanged;
  final ValueChanged<String> onTextChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typography = theme.appTypography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            descriptor.label.toUpperCase(),
            style: typography.utilityOverline.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
              fontSize: 10,
            ),
          ),
        ),
        _buildInput(context),
      ],
    );
  }

  Widget _buildInput(BuildContext context) => switch (descriptor.type) {
    AppReportFilterType.text ||
    AppReportFilterType.search => _buildTextField(context),
    AppReportFilterType.singleSelect => _buildDropdown(context),
    AppReportFilterType.dateRange => _buildDateRangeButton(context),
    AppReportFilterType.date => _buildDateButton(context),
    _ => const SizedBox.shrink(),
  };

  Widget _buildTextField(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = textController;
    if (controller == null) return const SizedBox.shrink();

    return SizedBox(
      width: 220,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          return AppTextField(
            controller: controller,
            enabled: !isLoading,
            hintText: descriptor.hint ?? l10n.reportInlineFiltersHint,
            prefixIcon: Icons.search_rounded,
            density: AppTextFieldDensity.compact,
            suffix: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close_rounded, size: 16),
                    tooltip: l10n.reportFiltersClearTooltip,
                    onPressed: isLoading
                        ? null
                        : () {
                            controller.clear();
                            onTextChanged('');
                          },
                  )
                : null,
            onChanged: onTextChanged,
          );
        },
      ),
    );
  }

  Widget _buildDropdown(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentValue = currentValues[descriptor.name] as String?;
    final allOptions = <AppDropdownOption<String>>[
      AppDropdownOption<String>(
        value: '',
        label: l10n.reportInlineFiltersAllOption,
      ),
      ...descriptor.options.map(
        (o) => AppDropdownOption<String>(value: o.value, label: o.label),
      ),
    ];

    return SizedBox(
      width: 180,
      child: AppDropdownField<String>(
        value: currentValue ?? '',
        options: allOptions,
        enabled: !isLoading,
        density: AppTextFieldDensity.compact,
        onChanged: (v) {
          final updated = Map<String, Object?>.from(currentValues);
          if (v == null || v.isEmpty) {
            updated.remove(descriptor.name);
          } else {
            updated[descriptor.name] = v;
          }
          onChanged(updated);
        },
      ),
    );
  }

  Widget _buildDateRangeButton(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final current = currentValues[descriptor.name] as DateTimeRange?;
    final label = current != null
        ? '${_fmtDate(current.start)} – ${_fmtDate(current.end)}'
        : l10n.reportInlineFiltersSelectPeriod;

    return GestureDetector(
      onTap: isLoading
          ? null
          : () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                initialDateRange: current,
                builder: (ctx, child) => Theme(data: theme, child: child!),
              );
              if (picked != null) {
                final updated = Map<String, Object?>.from(currentValues)
                  ..[descriptor.name] = picked;
                onChanged(updated);
              }
            },
      child: _CompactDateButton(
        tokens: tokens,
        icon: Icons.date_range_rounded,
        label: label,
        hasValue: current != null,
        width: 210,
        typography: typography,
        theme: theme,
      ),
    );
  }

  Widget _buildDateButton(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final current = currentValues[descriptor.name] as DateTime?;
    final label = current != null
        ? _fmtDate(current)
        : l10n.reportInlineFiltersSelectDate;

    return GestureDetector(
      onTap: isLoading
          ? null
          : () async {
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                initialDate: current ?? DateTime.now(),
              );
              if (picked != null) {
                final updated = Map<String, Object?>.from(currentValues)
                  ..[descriptor.name] = picked;
                onChanged(updated);
              }
            },
      child: _CompactDateButton(
        tokens: tokens,
        icon: Icons.calendar_today_rounded,
        label: label,
        hasValue: current != null,
        width: 160,
        typography: typography,
        theme: theme,
      ),
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year}';
}

// ---------------------------------------------------------------------------
// Helper widgets
// ---------------------------------------------------------------------------

class _CompactDateButton extends StatelessWidget {
  const _CompactDateButton({
    required this.tokens,
    required this.icon,
    required this.label,
    required this.hasValue,
    required this.width,
    required this.typography,
    required this.theme,
  });

  final AppThemeTokens tokens;
  final IconData icon;
  final String label;
  final bool hasValue;
  final double width;
  final AppTypographyTokens typography;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 36,
      padding: EdgeInsets.symmetric(horizontal: tokens.gapMd),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(tokens.formFieldRadius),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: typography.caption.copyWith(
                color: hasValue
                    ? theme.colorScheme.onSurface
                    : theme.colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClearButton extends StatelessWidget {
  const _ClearButton({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Tooltip(
      message: l10n.reportFiltersClearAllTooltip,
      child: IconButton.outlined(
        icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
        onPressed: onClear,
        style: IconButton.styleFrom(
          foregroundColor: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _AdvancedFiltersButton extends StatelessWidget {
  const _AdvancedFiltersButton({this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Tooltip(
      message: l10n.reportFiltersAdvancedButton,
      child: IconButton.filled(
        icon: const Icon(Icons.tune_rounded, size: 18),
        onPressed: onPressed,
        style: IconButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
        ),
      ),
    );
  }
}
