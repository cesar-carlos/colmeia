Map<String, dynamic> readWrappedPayload(
  Map<String, dynamic> json, {
  List<String> wrapperKeys = const <String>['data', 'session', 'clientSession'],
}) {
  for (final key in wrapperKeys) {
    final wrapped = json[key];
    if (wrapped is Map<String, dynamic>) {
      return wrapped;
    }
  }

  return json;
}

Map<String, dynamic>? readNestedMap(
  Map<String, dynamic> json,
  List<String> keys,
) {
  for (final key in keys) {
    final value = json[key];
    if (value is Map<String, dynamic>) {
      return value;
    }
  }

  return null;
}

String? readOptionalString(
  Map<String, dynamic> json,
  List<String> keys,
) {
  for (final key in keys) {
    final value = json[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
  }

  return null;
}

String readRequiredString(
  Map<String, dynamic> json,
  List<String> keys, {
  required String logicalName,
}) {
  final value = readOptionalString(json, keys);
  if (value != null) {
    return value;
  }

  throw FormatException(
    'Client auth response missing non-empty string for $logicalName '
    '(tried: ${keys.join(', ')})',
  );
}
