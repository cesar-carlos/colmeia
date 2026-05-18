String appBranchDisplayName(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return trimmed;
  }

  for (final prefix in _knownPrefixes) {
    if (trimmed.length > prefix.length &&
        trimmed.toLowerCase().startsWith(prefix)) {
      return trimmed.substring(prefix.length).trimLeft();
    }
  }
  return trimmed;
}

const List<String> _knownPrefixes = <String>[
  'agente ',
  'agent ',
  'filial ',
  'branch ',
];
