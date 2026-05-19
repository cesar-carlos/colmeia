import 'package:colmeia/core/refresh/auto_refresh_option.dart';
import 'package:flutter/foundation.dart';

@immutable
class AutoRefreshOptionSet {
  factory AutoRefreshOptionSet({
    required List<AutoRefreshOption> values,
    AutoRefreshOption? defaultOption,
  }) {
    final resolvedValues = List<AutoRefreshOption>.unmodifiable(values);
    if (defaultOption != null && resolvedValues.isEmpty) {
      throw ArgumentError.value(
        defaultOption,
        'defaultOption',
        'defaultOption requires at least one available option.',
      );
    }
    if (defaultOption != null && !resolvedValues.contains(defaultOption)) {
      throw ArgumentError.value(
        defaultOption,
        'defaultOption',
        'defaultOption must belong to the option set.',
      );
    }
    return AutoRefreshOptionSet._(
      values: resolvedValues,
      defaultOption: defaultOption,
    );
  }

  const AutoRefreshOptionSet._({
    required List<AutoRefreshOption> values,
    required this.defaultOption,
  }) : _values = values;

  final List<AutoRefreshOption> _values;
  final AutoRefreshOption? defaultOption;

  List<AutoRefreshOption> get values => _values;

  AutoRefreshOption? byId(String? id) {
    if (id == null) {
      return null;
    }
    for (final option in _values) {
      if (option.id == id) {
        return option;
      }
    }
    return null;
  }

  bool contains(AutoRefreshOption option) => _values.contains(option);
}
