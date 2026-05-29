import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:intl/intl.dart';

/// Resolves active report filters into human-readable label/value pairs for
/// inclusion in exported documents (PDF/Excel).
///
/// Kept separate from the format exporters so value formatting (option labels,
/// dates, booleans, lists) has a single source of truth.
abstract final class ReportExportFilterFormatter {
  static List<({String label, String value})> resolve(
    List<AppReportFilterDescriptor>? filters,
    Map<String, Object?>? filterValues,
  ) {
    if (filters == null || filters.isEmpty || filterValues == null) {
      return const <({String label, String value})>[];
    }

    final result = <({String label, String value})>[];
    for (final filter in filters) {
      final rawValue = filterValues[filter.name];
      final formattedValue = _formatValue(filter, rawValue);
      if (formattedValue == null || formattedValue.isEmpty) {
        continue;
      }
      result.add((label: filter.label, value: formattedValue));
    }
    return result;
  }

  static String? _formatValue(
    AppReportFilterDescriptor filter,
    Object? value,
  ) {
    if (value == null) {
      return null;
    }

    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return null;
      }
      return _resolveOptionLabel(filter, trimmed);
    }

    if (value is bool) {
      return value ? 'Sim' : 'Não';
    }

    if (value is DateTime) {
      return DateFormat('dd/MM/yyyy').format(value);
    }

    if (value is num) {
      return NumberFormat.decimalPattern('pt_BR').format(value);
    }

    if (value is Iterable) {
      final labels = value
          .map((item) => _formatValue(filter, item))
          .whereType<String>()
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
      if (labels.isEmpty) {
        return null;
      }
      return labels.join(', ');
    }

    return value.toString();
  }

  static String _resolveOptionLabel(
    AppReportFilterDescriptor filter,
    String value,
  ) {
    for (final option in filter.options) {
      if (option.value == value) {
        return option.label;
      }
    }
    return value;
  }
}
