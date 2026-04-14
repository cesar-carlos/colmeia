import 'package:colmeia/shared/widgets/forms/app_dropdown_field.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

class AppFormBuilderDropdownField<T> extends StatelessWidget {
  const AppFormBuilderDropdownField({
    required this.name,
    required this.options,
    super.key,
    this.label,
    this.hintText,
    this.helperText,
    this.initialValue,
    this.validator,
    this.enabled = true,
    this.autovalidateMode,
    this.density = AppTextFieldDensity.comfortable,
    this.menuMaxHeight = 220,
  });

  final String name;
  final List<AppDropdownOption<T>> options;
  final String? label;
  final String? hintText;
  final String? helperText;
  final T? initialValue;
  final String? Function(T?)? validator;
  final bool enabled;
  final AutovalidateMode? autovalidateMode;
  final AppTextFieldDensity density;
  final double menuMaxHeight;

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<T>(
      name: name,
      initialValue: initialValue,
      enabled: enabled,
      validator: validator,
      autovalidateMode: autovalidateMode,
      builder: (field) {
        return AppDropdownField<T>(
          value: field.value,
          options: options,
          label: label,
          hintText: hintText,
          helperText: field.errorText == null ? helperText : null,
          errorText: field.errorText,
          enabled: enabled,
          density: density,
          menuMaxHeight: menuMaxHeight,
          onChanged: field.didChange,
        );
      },
    );
  }
}

class AppFormBuilderMultiSelectSearchField<T> extends StatelessWidget {
  const AppFormBuilderMultiSelectSearchField({
    required this.name,
    required this.options,
    super.key,
    this.label,
    this.helperText,
    this.initialValue,
    this.validator,
    this.enabled = true,
    this.autovalidateMode,
    this.searchHintText = 'Search tags...',
    this.emptyResultsLabel = 'Nenhum resultado encontrado.',
    this.density = AppTextFieldDensity.comfortable,
    this.menuMaxHeight = 220,
    this.minimumSelectionCount = 0,
  });

  final String name;
  final List<AppDropdownOption<T>> options;
  final String? label;
  final String? helperText;
  final List<T>? initialValue;
  final String? Function(List<T>?)? validator;
  final bool enabled;
  final AutovalidateMode? autovalidateMode;
  final String searchHintText;
  final String emptyResultsLabel;
  final AppTextFieldDensity density;
  final double menuMaxHeight;
  final int minimumSelectionCount;

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<List<T>>(
      name: name,
      initialValue: initialValue,
      enabled: enabled,
      validator: validator,
      autovalidateMode: autovalidateMode,
      builder: (field) {
        return AppMultiSelectSearchField<T>(
          options: options,
          selectedValues: field.value ?? <T>[],
          label: label,
          helperText: field.errorText == null ? helperText : null,
          errorText: field.errorText,
          enabled: enabled,
          density: density,
          menuMaxHeight: menuMaxHeight,
          searchHintText: searchHintText,
          emptyResultsLabel: emptyResultsLabel,
          minimumSelectionCount: minimumSelectionCount,
          onChanged: field.didChange,
        );
      },
    );
  }
}
