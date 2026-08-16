import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/actions/app_primary_button.dart';
import 'package:colmeia/shared/widgets/actions/app_secondary_button.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/app_tag_chip.dart';
import 'package:colmeia/shared/widgets/forms/app_dropdown_field.dart';
import 'package:colmeia/shared/widgets/forms/app_form_builder_date_picker_field.dart';
import 'package:colmeia/shared/widgets/forms/app_form_builder_dropdown_field.dart';
import 'package:colmeia/shared/widgets/forms/app_form_builder_text_field.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

/// Generic filters panel that renders form fields from a list of
/// [AppReportFilterDescriptor] declarations.
///
/// Supports: text, singleSelect, multiSelect, date, dateRange,
/// numericRange, toggle, search.
class AppReportFiltersPanel extends StatefulWidget {
  const AppReportFiltersPanel({
    required this.filters,
    required this.onApply,
    super.key,
    this.title,
    this.initialValues = const <String, Object?>{},
    this.onClear,
    this.startExpanded = true,
  });

  final List<AppReportFilterDescriptor> filters;
  final ValueChanged<Map<String, Object?>> onApply;
  final String? title;
  final Map<String, Object?> initialValues;
  final VoidCallback? onClear;
  final bool startExpanded;

  @override
  State<AppReportFiltersPanel> createState() => _AppReportFiltersPanelState();
}

class _AppReportFiltersPanelState extends State<AppReportFiltersPanel> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.startExpanded;
  }

  @override
  void didUpdateWidget(covariant AppReportFiltersPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mapEquals(oldWidget.initialValues, widget.initialValues)) {
      _scheduleSyncFormValues();
    }
  }

  void _scheduleSyncFormValues() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _formKey.currentState?.reset();
      _formKey.currentState?.patchValue(widget.initialValues);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final l10n = AppLocalizations.of(context);
    final hasFilters = widget.filters.isNotEmpty;
    final requiredCount = widget.filters.where((f) => f.required).length;
    final activeCount = widget.filters
        .where(
          (filter) => _hasActiveValue(
            filter,
            widget.initialValues,
          ),
        )
        .length;

    return AppSectionCard(
      color: theme.colorScheme.surfaceContainerLow,
      borderSide: BorderSide(
        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          InkWell(
            onTap: hasFilters
                ? () => setState(() => _expanded = !_expanded)
                : null,
            borderRadius: BorderRadius.circular(tokens.cardRadius),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        widget.title ?? l10n.reportFiltersTitle,
                        style: typography.sectionHeaderH2.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: tokens.gapXs),
                      Text(
                        l10n.reportFiltersDescription,
                        style: typography.caption.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: tokens.gapSm),
                      Wrap(
                        spacing: tokens.gapSm,
                        runSpacing: tokens.gapSm,
                        children: <Widget>[
                          AppTagChip(
                            label: l10n.reportFiltersFieldCount(
                              widget.filters.length,
                            ),
                          ),
                          if (requiredCount > 0)
                            AppTagChip(
                              label: l10n.reportFiltersRequiredCount(
                                requiredCount,
                              ),
                            ),
                          if (activeCount > 0)
                            AppTagChip(
                              label: l10n.reportFiltersActiveCount(
                                activeCount,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (hasFilters)
                  AnimatedRotation(
                    turns: _expanded ? -0.5 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 250),
            sizeCurve: Curves.easeOutCubic,
            crossFadeState: _expanded && hasFilters
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            secondChild: const SizedBox(width: double.infinity),
            firstChild: Padding(
              padding: EdgeInsets.only(top: tokens.contentSpacing),
              child: FormBuilder(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    ...widget.filters.asMap().entries.map((entry) {
                      final isLast = entry.key == widget.filters.length - 1;
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: isLast ? tokens.gapMd : tokens.contentSpacing,
                        ),
                        child: _FilterField(
                          descriptor: entry.value,
                          initialValues: widget.initialValues,
                        ),
                      );
                    }),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: AppSecondaryButton(
                            onPressed: () {
                              _formKey.currentState?.reset();
                              widget.onClear?.call();
                            },
                            label: l10n.reportFiltersClearAction,
                          ),
                        ),
                        SizedBox(width: tokens.gapMd),
                        Expanded(
                          child: AppPrimaryButton(
                            onPressed: () {
                              final valid =
                                  _formKey.currentState?.saveAndValidate() ??
                                  false;
                              if (!valid) return;
                              widget.onApply(
                                _formKey.currentState?.value ??
                                    <String, Object?>{},
                              );
                            },
                            label: l10n.reportFiltersApplyAction,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static bool _hasActiveValue(
    AppReportFilterDescriptor filter,
    Map<String, Object?> values,
  ) => filter.hasActiveValue(values);
}

class _FilterField extends StatelessWidget {
  const _FilterField({
    required this.descriptor,
    required this.initialValues,
  });

  final AppReportFilterDescriptor descriptor;
  final Map<String, Object?> initialValues;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final typography = theme.appTypography;
    final l10n = AppLocalizations.of(context);
    final helperText = descriptor.required
        ? l10n.reportFilterRequired
        : l10n.reportFilterOptional;
    final initialValue =
        initialValues[descriptor.name] ?? descriptor.initialValue;
    final requiredValidator = descriptor.required
        ? FormBuilderValidators.compose(<String? Function(Object?)>[
            FormBuilderValidators.required(),
          ])
        : null;

    switch (descriptor.type) {
      case AppReportFilterType.text:
      case AppReportFilterType.search:
        return AppFormBuilderTextField(
          name: descriptor.name,
          initialValue: initialValue as String?,
          label: descriptor.label,
          hintText: descriptor.hint,
          helperText: helperText,
          prefixIcon: descriptor.type == AppReportFilterType.search
              ? Icons.search_rounded
              : null,
          validator: requiredValidator,
        );

      case AppReportFilterType.singleSelect:
        return AppFormBuilderDropdownField<String>(
          name: descriptor.name,
          label: descriptor.label,
          hintText: l10n.reportFilterSelectOption,
          helperText: helperText,
          initialValue: initialValue as String?,
          options: descriptor.options
              .map(
                (o) => AppDropdownOption<String>(
                  value: o.value,
                  label: o.label,
                ),
              )
              .toList(growable: false),
          validator: requiredValidator,
        );

      case AppReportFilterType.multiSelect:
        return AppFormBuilderMultiSelectSearchField<String>(
          name: descriptor.name,
          initialValue: initialValue is List
              ? initialValue.whereType<String>().toList(growable: false)
              : null,
          label: descriptor.label,
          helperText: helperText,
          searchHintText: l10n.reportFilterSearchTagsHint,
          options: descriptor.options
              .map(
                (o) => AppDropdownOption<String>(
                  value: o.value,
                  label: o.label,
                ),
              )
              .toList(growable: false),
          validator: descriptor.required
              ? FormBuilderValidators.compose(
                  <String? Function(List<String>?)>[
                    FormBuilderValidators.required(),
                  ],
                )
              : null,
        );

      case AppReportFilterType.date:
        return AppFormBuilderDatePickerField(
          name: descriptor.name,
          label: descriptor.label,
          helperText: helperText,
          pickerTitle: descriptor.label,
          initialValue: initialValue as DateTime?,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          validator: descriptor.required
              ? FormBuilderValidators.compose(
                  <String? Function(DateTime?)>[
                    FormBuilderValidators.required(),
                  ],
                )
              : null,
        );

      case AppReportFilterType.dateRange:
        return AppFormBuilderDateRangePickerField(
          name: descriptor.name,
          label: descriptor.label,
          helperText: helperText,
          pickerTitle: descriptor.label,
          initialValue: initialValue as DateTimeRange?,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          validator: descriptor.required
              ? FormBuilderValidators.compose(
                  <String? Function(DateTimeRange?)>[
                    FormBuilderValidators.required(),
                  ],
                )
              : null,
        );

      case AppReportFilterType.numericRange:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              descriptor.label,
              style: typography.utilityOverline.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: tokens.gapXs),
            Row(
              children: <Widget>[
                Expanded(
                  child: AppFormBuilderTextField(
                    name: '${descriptor.name}_min',
                    initialValue: initialValues['${descriptor.name}_min']
                        ?.toString(),
                    label: l10n.reportFilterRangeFrom,
                    hintText: descriptor.minValue?.toString(),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                SizedBox(width: tokens.gapSm),
                Expanded(
                  child: AppFormBuilderTextField(
                    name: '${descriptor.name}_max',
                    initialValue: initialValues['${descriptor.name}_max']
                        ?.toString(),
                    label: l10n.reportFilterRangeTo,
                    hintText: descriptor.maxValue?.toString(),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );

      case AppReportFilterType.toggle:
        return FormBuilderSwitch(
          name: descriptor.name,
          activeColor: theme.colorScheme.primary,
          title: Text(descriptor.label),
          subtitle: descriptor.hint != null
              ? Text(
                  descriptor.hint!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              : null,
          initialValue: initialValue as bool? ?? false,
        );
    }
  }
}
