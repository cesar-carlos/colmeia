import 'package:flutter/material.dart';

typedef PersistedFilterRule = void Function(
  PersistedFilterMapDraft draft,
  Map<String, Object?> source,
);

/// Helpers to normalize filter maps when persisting/restoring page state.
class PersistedFilterMapCodec {
  const PersistedFilterMapCodec._();

  static Map<String, Object?> sanitize(
    void Function(PersistedFilterMapDraft draft) build,
  ) {
    final draft = PersistedFilterMapDraft();
    build(draft);
    return draft.toMap();
  }

  static void writeTrimmedString({
    required Map<String, Object?> target,
    required String key,
    required Object? rawValue,
  }) {
    if (rawValue case final String text) {
      final normalized = text.trim();
      if (normalized.isNotEmpty) {
        target[key] = normalized;
      }
    }
  }

  static void writeStringIfAllowed({
    required Map<String, Object?> target,
    required String key,
    required Object? rawValue,
    required Set<String> allowedValues,
  }) {
    if (rawValue case final String value when allowedValues.contains(value)) {
      target[key] = value;
    }
  }

  static void writeBool({
    required Map<String, Object?> target,
    required String key,
    required Object? rawValue,
  }) {
    if (rawValue case final bool value) {
      target[key] = value;
    }
  }

  static void writeDateRangeFromEpoch({
    required Map<String, Object?> target,
    required String targetKey,
    required Object? startEpochMs,
    required Object? endEpochMs,
  }) {
    if (startEpochMs is int && endEpochMs is int) {
      target[targetKey] = DateTimeRange(
        start: DateTime.fromMillisecondsSinceEpoch(startEpochMs),
        end: DateTime.fromMillisecondsSinceEpoch(endEpochMs),
      );
    }
  }

  static void writeDateRangeToEpoch({
    required Map<String, Object?> target,
    required String startEpochKey,
    required String endEpochKey,
    required Object? rawValue,
  }) {
    if (rawValue case final DateTimeRange range) {
      target[startEpochKey] = range.start.millisecondsSinceEpoch;
      target[endEpochKey] = range.end.millisecondsSinceEpoch;
    }
  }
}

class PersistedFilterMapSchema {
  PersistedFilterMapSchema({
    required List<PersistedFilterRule> rules,
  }) : _rules = List<PersistedFilterRule>.unmodifiable(rules);

  final List<PersistedFilterRule> _rules;

  Map<String, Object?> apply(Map<String, Object?> source) {
    return PersistedFilterMapCodec.sanitize(
      (draft) {
        for (final rule in _rules) {
          rule(draft, source);
        }
      },
    );
  }

  static PersistedFilterRule trimmedString(String key) {
    return (draft, source) {
      draft.trimmedString(
        key: key,
        rawValue: source[key],
      );
    };
  }

  static PersistedFilterRule stringIfAllowed({
    required String key,
    required Set<String> allowedValues,
  }) {
    return (draft, source) {
      draft.stringIfAllowed(
        key: key,
        rawValue: source[key],
        allowedValues: allowedValues,
      );
    };
  }

  static PersistedFilterRule boolean(String key) {
    return (draft, source) {
      draft.boolean(
        key: key,
        rawValue: source[key],
      );
    };
  }

  static PersistedFilterRule dateRangeFromEpoch({
    required String targetKey,
    required String startEpochKey,
    required String endEpochKey,
  }) {
    return (draft, source) {
      draft.dateRangeFromEpoch(
        targetKey: targetKey,
        startEpochMs: source[startEpochKey],
        endEpochMs: source[endEpochKey],
      );
    };
  }

  static PersistedFilterRule dateRangeToEpoch({
    required String sourceKey,
    required String startEpochKey,
    required String endEpochKey,
  }) {
    return (draft, source) {
      draft.dateRangeToEpoch(
        startEpochKey: startEpochKey,
        endEpochKey: endEpochKey,
        rawValue: source[sourceKey],
      );
    };
  }
}

class PersistedFilterMapDraft {
  final Map<String, Object?> _values = <String, Object?>{};

  void trimmedString({
    required String key,
    required Object? rawValue,
  }) {
    PersistedFilterMapCodec.writeTrimmedString(
      target: _values,
      key: key,
      rawValue: rawValue,
    );
  }

  void stringIfAllowed({
    required String key,
    required Object? rawValue,
    required Set<String> allowedValues,
  }) {
    PersistedFilterMapCodec.writeStringIfAllowed(
      target: _values,
      key: key,
      rawValue: rawValue,
      allowedValues: allowedValues,
    );
  }

  void boolean({
    required String key,
    required Object? rawValue,
  }) {
    PersistedFilterMapCodec.writeBool(
      target: _values,
      key: key,
      rawValue: rawValue,
    );
  }

  void dateRangeFromEpoch({
    required String targetKey,
    required Object? startEpochMs,
    required Object? endEpochMs,
  }) {
    PersistedFilterMapCodec.writeDateRangeFromEpoch(
      target: _values,
      targetKey: targetKey,
      startEpochMs: startEpochMs,
      endEpochMs: endEpochMs,
    );
  }

  void dateRangeToEpoch({
    required String startEpochKey,
    required String endEpochKey,
    required Object? rawValue,
  }) {
    PersistedFilterMapCodec.writeDateRangeToEpoch(
      target: _values,
      startEpochKey: startEpochKey,
      endEpochKey: endEpochKey,
      rawValue: rawValue,
    );
  }

  Map<String, Object?> toMap() => Map<String, Object?>.from(_values);
}
