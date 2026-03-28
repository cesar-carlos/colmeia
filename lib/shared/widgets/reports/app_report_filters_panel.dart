import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
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
    this.initialValues = const <String, Object?>{},
    this.onClear,
    this.startExpanded = true,
  });

  final List<AppReportFilterDescriptor> filters;
  final ValueChanged<Map<String, Object?>> onApply;
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final hasFilters = widget.filters.isNotEmpty;
    final requiredCount = widget.filters.where((f) => f.required).length;

    return AppSectionCard(
      color: theme.colorScheme.surfaceContainerLow,
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
                        'Filtros',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: tokens.gapXs),
                      Wrap(
                        spacing: tokens.gapSm,
                        runSpacing: tokens.gapSm,
                        children: <Widget>[
                          Chip(
                            label: Text('${widget.filters.length} campos'),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                          if (requiredCount > 0)
                            Chip(
                              label: Text('$requiredCount obrigatórios'),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (hasFilters)
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
          if (_expanded && hasFilters) ...<Widget>[
            SizedBox(height: tokens.contentSpacing),
            FormBuilder(
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
                        child: OutlinedButton(
                          onPressed: () {
                            _formKey.currentState?.reset();
                            widget.onClear?.call();
                          },
                          child: const Text('Limpar'),
                        ),
                      ),
                      SizedBox(width: tokens.gapMd),
                      Expanded(
                        child: FilledButton(
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
                          child: const Text('Aplicar filtros'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
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
        return FormBuilderTextField(
          name: descriptor.name,
          initialValue: initialValue as String?,
          decoration: InputDecoration(
            labelText: descriptor.label,
            hintText: descriptor.hint,
            helperText: descriptor.required ? 'Obrigatório' : 'Opcional',
            prefixIcon: descriptor.type == AppReportFilterType.search
                ? const Icon(Icons.search_rounded)
                : null,
          ),
          validator: requiredValidator,
        );

      case AppReportFilterType.singleSelect:
        return FormBuilderDropdown<String>(
          name: descriptor.name,
          initialValue: initialValue as String?,
          decoration: InputDecoration(
            labelText: descriptor.label,
            helperText: descriptor.required ? 'Obrigatório' : 'Opcional',
          ),
          items: descriptor.options.map((o) {
            return DropdownMenuItem<String>(
              value: o.value,
              child: Text(o.label),
            );
          }).toList(),
          validator: requiredValidator,
        );

      case AppReportFilterType.multiSelect:
        return FormBuilderFilterChips<String>(
          name: descriptor.name,
          initialValue: initialValue is List<String> ? initialValue : null,
          decoration: InputDecoration(
            labelText: descriptor.label,
            helperText: descriptor.required ? 'Obrigatório' : 'Opcional',
          ),
          options: descriptor.options.map((o) {
            return FormBuilderChipOption<String>(
              value: o.value,
              child: Text(o.label),
            );
          }).toList(),
          validator: descriptor.required
              ? FormBuilderValidators.compose(
                  <String? Function(List<String>?)>[
                    FormBuilderValidators.required(),
                  ],
                )
              : null,
        );

      case AppReportFilterType.date:
        return FormBuilderDateTimePicker(
          name: descriptor.name,
          initialValue: initialValue as DateTime?,
          inputType: InputType.date,
          format: AppBrFormatters.shortDateFormat,
          decoration: InputDecoration(
            labelText: descriptor.label,
            helperText: descriptor.required ? 'Obrigatório' : 'Opcional',
          ),
          validator: descriptor.required
              ? FormBuilderValidators.compose(
                  <String? Function(DateTime?)>[
                    FormBuilderValidators.required(),
                  ],
                )
              : null,
        );

      case AppReportFilterType.dateRange:
        return FormBuilderDateRangePicker(
          name: descriptor.name,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          format: AppBrFormatters.shortDateFormat,
          decoration: InputDecoration(
            labelText: descriptor.label,
            helperText: descriptor.required ? 'Obrigatório' : 'Opcional',
          ),
        );

      case AppReportFilterType.numericRange:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              descriptor.label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: <Widget>[
                Expanded(
                  child: FormBuilderTextField(
                    name: '${descriptor.name}_min',
                    decoration: InputDecoration(
                      labelText: 'De',
                      hintText: descriptor.minValue?.toString(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FormBuilderTextField(
                    name: '${descriptor.name}_max',
                    decoration: InputDecoration(
                      labelText: 'Até',
                      hintText: descriptor.maxValue?.toString(),
                    ),
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
