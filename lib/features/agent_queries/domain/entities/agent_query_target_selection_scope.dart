/// Normalizes agent selection sets into stable cache scope keys.
abstract final class AgentQueryTargetSelectionScope {
  static const String _allAgentsScope = '__all__';
  static const String _emptySelectionScope = '__empty__';
  static const String _separator = '\u001f';

  /// Scope key for agent query target resolution cache entries.
  ///
  /// `null` means all approved agents; an empty set is distinct from `null`.
  static String cacheScopeKey(Set<String>? selectedAgentIds) {
    if (selectedAgentIds == null) {
      return _allAgentsScope;
    }
    if (selectedAgentIds.isEmpty) {
      return _emptySelectionScope;
    }
    final sortedIds = selectedAgentIds.toList(growable: false)..sort();
    return sortedIds.join(_separator);
  }
}
