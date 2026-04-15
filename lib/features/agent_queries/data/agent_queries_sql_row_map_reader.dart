/// Normalizes bridge row maps (PascalCase, camelCase, lowercase keys).
abstract final class AgentQueriesSqlRowMapReader {
  static List<String> keysCodEmpresaStyle(String pascal) {
    return <String>[
      pascal,
      _pascalToCamel(pascal),
      pascal.toLowerCase(),
    ];
  }

  static String _pascalToCamel(String pascal) {
    if (pascal.isEmpty) {
      return pascal;
    }
    return pascal[0].toLowerCase() + pascal.substring(1);
  }

  static Object? lookupFirst(Map<String, dynamic> map, List<String> keys) {
    for (final k in keys) {
      if (map.containsKey(k)) {
        return map[k];
      }
    }
    return null;
  }

  static int readRequiredInt(Map<String, dynamic> map, List<String> keys) {
    final value = lookupFirst(map, keys);
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) {
        return parsed;
      }
    }
    throw FormatException(
      'Invalid or missing "${keys.first}" in agent SQL row',
    );
  }

  /// `NULL`, absent key, or unparseable value yields `null`.
  static int? readOptionalInt(Map<String, dynamic> map, List<String> keys) {
    final value = lookupFirst(map, keys);
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return null;
      }
      return int.tryParse(trimmed);
    }
    return null;
  }

  /// Like [readOptionalInt], but throws [FormatException] when a value is
  /// present and not parseable as int (non-empty string that is not an int,
  /// or an unsupported type). Use for optional columns where silent null
  /// would hide bridge bugs.
  static int? readOptionalIntStrict(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    final value = lookupFirst(map, keys);
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return null;
      }
      final parsed = int.tryParse(trimmed);
      if (parsed != null) {
        return parsed;
      }
      throw FormatException(
        'Invalid or non-numeric "${keys.first}" in agent SQL row',
      );
    }
    throw FormatException(
      'Invalid type for "${keys.first}" in agent SQL row '
      '(expected int, num, string, or null)',
    );
  }

  static double readRequiredDouble(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    final value = lookupFirst(map, keys);
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      final normalized = value.trim().replaceAll(',', '.');
      final parsed = double.tryParse(normalized);
      if (parsed != null) {
        return parsed;
      }
    }
    throw FormatException(
      'Invalid or missing "${keys.first}" in agent SQL row',
    );
  }

  static String readRequiredNonEmptyString(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    final value = lookupFirst(map, keys);
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    throw FormatException(
      'Invalid or missing "${keys.first}" in agent SQL row',
    );
  }

  /// `NULL`, absent key, empty string, or whitespace yields `null`.
  ///
  /// [num] values are converted with [num.toString] for tolerant bridges.
  static String? readOptionalTrimmedString(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    final value = lookupFirst(map, keys);
    if (value == null) {
      return null;
    }
    if (value is String) {
      final t = value.trim();
      return t.isEmpty ? null : t;
    }
    if (value is num) {
      return value.toString();
    }
    return null;
  }

  /// Like [readOptionalTrimmedString], but throws [FormatException] when a
  /// value is present and not a [String] (after trim). Does not coerce
  /// [num] to text; use for optional text columns where silent coercion would
  /// hide bridge bugs.
  static String? readOptionalTrimmedStringStrict(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    final value = lookupFirst(map, keys);
    if (value == null) {
      return null;
    }
    if (value is String) {
      final t = value.trim();
      return t.isEmpty ? null : t;
    }
    throw FormatException(
      'Invalid type for "${keys.first}" in agent SQL row '
      '(expected string or null)',
    );
  }

  /// Month label from SQL (e.g. `YYYY/MM`); tolerates `num` from some bridges.
  static String readRequiredAnoMesDataVenda(Map<String, dynamic> map) {
    final keys = keysCodEmpresaStyle('AnoMesDataVenda');
    final value = lookupFirst(map, keys);
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    } else if (value is num) {
      return value.toString();
    }
    throw const FormatException(
      'Invalid or missing "AnoMesDataVenda" in agent SQL row',
    );
  }

  /// Calendar date from `DataVenda` (bridge may send `DateTime` or ISO-like
  /// strings).
  static DateTime readDataVendaCalendarDate(Map<String, dynamic> map) {
    final keys = keysCodEmpresaStyle('DataVenda');
    final raw = lookupFirst(map, keys);
    if (raw is DateTime) {
      return DateTime(raw.year, raw.month, raw.day);
    }
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.length >= 10) {
        final datePart = trimmed.substring(0, 10);
        final parsed = DateTime.tryParse(datePart);
        if (parsed != null) {
          return DateTime(parsed.year, parsed.month, parsed.day);
        }
      }
      final parsed = DateTime.tryParse(trimmed);
      if (parsed != null) {
        return DateTime(parsed.year, parsed.month, parsed.day);
      }
    }
    throw const FormatException(
      'Invalid or missing "DataVenda" in agent SQL row',
    );
  }
}
