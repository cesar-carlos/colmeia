enum AgentCatalogStatus {
  active,
  inactive,
  unknown;

  static AgentCatalogStatus fromWireValue(String? value) {
    return switch (value?.trim().toLowerCase()) {
      'active' => AgentCatalogStatus.active,
      'inactive' => AgentCatalogStatus.inactive,
      null || '' => AgentCatalogStatus.unknown,
      _ => AgentCatalogStatus.unknown,
    };
  }
}
