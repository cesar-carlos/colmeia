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
