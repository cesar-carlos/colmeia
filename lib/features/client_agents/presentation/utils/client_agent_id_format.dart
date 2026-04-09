/// Shared validation for agent UUIDs used in client agent flows.
final RegExp clientAgentIdUuidPattern = RegExp(
  '^[0-9a-fA-F]{8}-'
  '[0-9a-fA-F]{4}-'
  '[1-5][0-9a-fA-F]{3}-'
  '[89abAB][0-9a-fA-F]{3}-'
  r'[0-9a-fA-F]{12}$',
);

bool isValidClientAgentId(String value) {
  return clientAgentIdUuidPattern.hasMatch(value.trim());
}

/// Parses UUID agent IDs from legacy free-form draft text (commas, spaces,
/// line breaks). Preserves first-seen order and drops duplicates.
List<String> parseAgentIdsFromFreeformDraft(String rawValue) {
  final rawAgentIds = rawValue
      .split(RegExp(r'[\s,;]+'))
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty);

  final out = <String>[];
  final seen = <String>{};
  for (final agentId in rawAgentIds) {
    if (!isValidClientAgentId(agentId)) {
      continue;
    }
    final normalized = agentId.trim();
    if (seen.add(normalized)) {
      out.add(normalized);
    }
  }
  return out;
}
