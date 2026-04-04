enum AgentCatalogStatus {
  active,
  inactive
  ;

  static AgentCatalogStatus fromWireValue(String? value) {
    return switch (value?.trim().toLowerCase()) {
      'inactive' => AgentCatalogStatus.inactive,
      _ => AgentCatalogStatus.active,
    };
  }
}
