import 'package:colmeia/shared/widgets/forms/app_date_picker_field.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

class AppFormBuilderDatePickerField extends StatelessWidget {
  const AppFormBuilderDatePickerField({
    required this.name,
    super.key,
    this.label,
    this.helperText,
    this.placeholderText,
    this.pickerTitle,
    this.initialValue,
    this.firstDate,
    this.lastDate,
    this.enabled = true,
    this.onChanged,
    this.validator,
    this.onSaved,
    this.autovalidateMode,
    this.density = AppTextFieldDensity.comfortable,
  });

  final String name;
  final String? label;
  final String? helperText;
  final String? placeholderText;
  final String? pickerTitle;
  final DateTime? initialValue;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool enabled;
  final ValueChanged<DateTime?>? onChanged;
  final FormFieldValidator<DateTime?>? validator;
  final FormFieldSetter<DateTime?>? onSaved;
  final AutovalidateMode? autovalidateMode;
  final AppTextFieldDensity density;

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<DateTime?>(
      name: name,
      initialValue: initialValue,
      enabled: enabled,
      validator: validator,
      onSaved: onSaved,
      autovalidateMode: autovalidateMode,
      builder: (field) {
        return AppDatePickerField(
          label: label,
          helperText: helperText,
          placeholderText: placeholderText,
          pickerTitle: pickerTitle,
          value: field.value,
          firstDate: firstDate,
          lastDate: lastDate,
          enabled: enabled,
          density: density,
          errorText: field.errorText,
          onChanged: (value) {
            field.didChange(value);
            onChanged?.call(value);
          },
        );
      },
    );
  }
}

class AppFormBuilderDateRangePickerField extends StatelessWidget {
  const AppFormBuilderDateRangePickerField({
    required this.name,
    super.key,
    this.label,
    this.helperText,
    this.placeholderText,
    this.pickerTitle,
    this.initialValue,
    this.firstDate,
    this.lastDate,
    this.enabled = true,
    this.onChanged,
    this.validator,
    this.onSaved,
    this.autovalidateMode,
    this.density = AppTextFieldDensity.comfortable,
  });

  final String name;
  final String? label;
  final String? helperText;
  final String? placeholderText;
  final String? pickerTitle;
  final DateTimeRange? initialValue;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool enabled;
  final ValueChanged<DateTimeRange?>? onChanged;
  final FormFieldValidator<DateTimeRange?>? validator;
  final FormFieldSetter<DateTimeRange?>? onSaved;
  final AutovalidateMode? autovalidateMode;
  final AppTextFieldDensity density;

  @override
  Widget build(BuildContext context) {
    return FormBuilderField<DateTimeRange?>(
      name: name,
      initialValue: initialValue,
      enabled: enabled,
      validator: validator,
      onSaved: onSaved,
      autovalidateMode: autovalidateMode,
      builder: (field) {
        return AppDateRangePickerField(
          label: label,
          helperText: helperText,
          placeholderText: placeholderText,
          pickerTitle: pickerTitle,
          value: field.value,
          firstDate: firstDate,
          lastDate: lastDate,
          enabled: enabled,
          density: density,
          errorText: field.errorText,
          onChanged: (value) {
            field.didChange(value);
            onChanged?.call(value);
          },
        );
      },
    );
  }
}
