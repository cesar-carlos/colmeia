import 'package:colmeia/shared/utils/app_debouncer.dart';
import 'package:colmeia/shared/widgets/reports/app_report_filter_values_equality.dart';
import 'package:flutter/foundation.dart';

/// Owns filter drafts and emits one complete snapshot after rapid edits.
class AppReportFilterValuesController {
  AppReportFilterValuesController(Map<String, Object?> initialValues)
    : _externalValues = _snapshotExternalValues(initialValues),
      _values = Map.of(initialValues);

  Map<String, Object?> _externalValues;
  Map<String, Object?> _values;
  AppDebouncer? _debouncer;

  Map<String, Object?> get values => Map.unmodifiable(_values);

  bool synchronize(Map<String, Object?> values) {
    if (reportFilterValuesEqual(_externalValues, values)) return false;
    cancelPending();
    _externalValues = _snapshotExternalValues(values);
    _values = Map.of(values);
    return true;
  }

  void change(
    String name,
    Object? value, {
    required ValueChanged<Map<String, Object?>> onChanged,
    Duration delay = Duration.zero,
  }) {
    if (value == null || value is String && value.trim().isEmpty) {
      _values.remove(name);
    } else {
      _values[name] = value;
    }
    cancelPending();
    if (delay <= Duration.zero) {
      onChanged(Map.of(_values));
    } else {
      _debouncer = AppDebouncer(duration: delay)
        ..run(() => onChanged(Map.of(_values)));
    }
  }

  void clear() {
    cancelPending();
    _values.clear();
  }

  void cancelPending() {
    _debouncer?.dispose();
    _debouncer = null;
  }

  void dispose() => cancelPending();

  static Map<String, Object?> _snapshotExternalValues(
    Map<String, Object?> values,
  ) => {
    for (final entry in values.entries)
      entry.key: switch (entry.value) {
        final List<Object?> items => List<Object?>.of(items),
        final value => value,
      },
  };
}
