import 'package:colmeia/shared/widgets/reports/app_report_models.dart';

/// Produces complete, typed patches for the fields registered by the panel.
Map<String, Object?> reportFilterFormValues(
  List<AppReportFilterDescriptor> filters,
  Map<String, Object?> values, {
  bool clear = false,
}) {
  final result = <String, Object?>{};
  for (final filter in filters) {
    final name = filter.name;
    if (filter.type == AppReportFilterType.numericRange) {
      for (final suffix in ['min', 'max']) {
        final key = '${name}_$suffix';
        result[key] = clear ? null : values[key]?.toString();
      }
      continue;
    }
    final value = clear
        ? null
        : values.containsKey(name)
        ? values[name]
        : filter.initialValue;
    result[name] = switch (filter.type) {
      AppReportFilterType.toggle => value as bool? ?? false,
      AppReportFilterType.multiSelect =>
        value is List
            ? value.whereType<String>().toList(growable: false)
            : <String>[],
      _ => value,
    };
  }
  return result;
}
