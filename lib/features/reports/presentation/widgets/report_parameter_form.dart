import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/features/reports/domain/entities/report_parameter_descriptor.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/forms/app_form_builder_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

class ReportParameterForm extends StatelessWidget {
  const ReportParameterForm({
    required this.parameters,
    required this.onApply,
    this.initialValues = const <String, Object?>{},
    this.onClear,
    super.key,
  });

  final List<ReportParameterDescriptor> parameters;
  final ValueChanged<Map<String, Object?>> onApply;
  final Map<String, Object?> initialValues;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormBuilderState>();
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final hasParameters = parameters.isNotEmpty;

    return AppSectionCard(
      color: theme.colorScheme.surfaceContainerLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Parâmetros do relatório',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: tokens.gapXs),
          Text(
            'Ajuste o recorte antes de consultar o resultado consolidado.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: tokens.gapMd),
          Wrap(
            spacing: tokens.gapSm,
            runSpacing: tokens.gapSm,
            children: <Widget>[
              Chip(label: Text('${parameters.length} filtros')),
              if (hasParameters)
                Chip(
                  label: Text(
                    '${parameters.where((p) => p.required).length} '
                    'obrigatórios',
                  ),
                ),
            ],
          ),
          SizedBox(height: tokens.contentSpacing),
          FormBuilder(
            key: formKey,
            child: Column(
              children: <Widget>[
                ...parameters.asMap().entries.map((entry) {
                  final isLast = entry.key == parameters.length - 1;
                  final parameter = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: isLast ? tokens.gapMd : tokens.contentSpacing,
                    ),
                    child: _ReportParameterField(
                      parameter: parameter,
                      initialValues: initialValues,
                    ),
                  );
                }),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          formKey.currentState?.reset();
                          onClear?.call();
                        },
                        child: const Text('Limpar'),
                      ),
                    ),
                    SizedBox(width: tokens.gapMd),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          final isValid =
                              formKey.currentState?.saveAndValidate() ?? false;

                          if (!isValid) {
                            return;
                          }

                          onApply(
                            formKey.currentState?.value ?? <String, Object?>{},
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
      ),
    );
  }
}

class _ReportParameterField extends StatelessWidget {
  const _ReportParameterField({
    required this.parameter,
    required this.initialValues,
  });

  final ReportParameterDescriptor parameter;
  final Map<String, Object?> initialValues;

  @override
  Widget build(BuildContext context) {
    final initialValue =
        initialValues[parameter.name] ?? parameter.initialValue;
    final theme = Theme.of(context);
    final textValidator = parameter.required
        ? FormBuilderValidators.compose(<String? Function(String?)>[
            FormBuilderValidators.required(),
          ])
        : null;

    switch (parameter.type) {
      case ReportParameterType.text:
        return AppFormBuilderTextField(
          name: parameter.name,
          label: parameter.label,
          initialValue: initialValue as String?,
          inputFormatters: parameter.name.toLowerCase().contains('cpf')
              ? AppBrFormatters.cpfInputFormatters
              : null,
          validator: textValidator,
        );
      case ReportParameterType.singleSelect:
        return FormBuilderDropdown<String>(
          name: parameter.name,
          initialValue: initialValue as String?,
          decoration: InputDecoration(
            labelText: parameter.label,
            helperText: parameter.required ? 'Obrigatório' : 'Opcional',
          ),
          items: parameter.options.map((option) {
            return DropdownMenuItem<String>(
              value: option.value,
              child: Text(option.label),
            );
          }).toList(),
          validator: parameter.required
              ? FormBuilderValidators.compose(<String? Function(String?)>[
                  FormBuilderValidators.required(),
                ])
              : null,
        );
      case ReportParameterType.date:
        return FormBuilderDateTimePicker(
          name: parameter.name,
          initialValue: initialValue as DateTime?,
          inputType: InputType.date,
          format: AppBrFormatters.shortDateFormat,
          decoration: InputDecoration(
            labelText: parameter.label,
            helperText: parameter.required ? 'Obrigatório' : 'Opcional',
          ),
          validator: parameter.required
              ? FormBuilderValidators.compose(<String? Function(DateTime?)>[
                  FormBuilderValidators.required(),
                ])
              : null,
        );
      case ReportParameterType.toggle:
        return FormBuilderSwitch(
          name: parameter.name,
          activeColor: theme.colorScheme.primary,
          title: Text(parameter.label),
          subtitle: Text(
            'Ative para restringir o recorte ao cenário desejado.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          initialValue: initialValue as bool? ?? false,
        );
    }
  }
}
