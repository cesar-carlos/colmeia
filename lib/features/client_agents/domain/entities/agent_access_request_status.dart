enum AgentAccessRequestStatus {
  pending,
  approved,
  rejected,
  expired,
  unknown
  ;

  static AgentAccessRequestStatus fromWireValue(String? value) {
    return switch (value?.trim().toLowerCase()) {
      'pending' => AgentAccessRequestStatus.pending,
      'approved' => AgentAccessRequestStatus.approved,
      'rejected' => AgentAccessRequestStatus.rejected,
      'expired' => AgentAccessRequestStatus.expired,
      _ => AgentAccessRequestStatus.unknown,
    };
  }
}
