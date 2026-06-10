enum ClientRegistrationStatus {
  pending,
  approved,
  rejected,
  expired,
  blocked,
  unknown,
}

extension ClientRegistrationStatusParsing on ClientRegistrationStatus {
  static ClientRegistrationStatus fromRaw(String? rawStatus) {
    return switch (rawStatus?.trim().toLowerCase()) {
      'pending' => ClientRegistrationStatus.pending,
      'approved' => ClientRegistrationStatus.approved,
      'rejected' => ClientRegistrationStatus.rejected,
      'expired' => ClientRegistrationStatus.expired,
      'blocked' => ClientRegistrationStatus.blocked,
      _ => ClientRegistrationStatus.unknown,
    };
  }

  String get wireValue => switch (this) {
    ClientRegistrationStatus.pending => 'pending',
    ClientRegistrationStatus.approved => 'approved',
    ClientRegistrationStatus.rejected => 'rejected',
    ClientRegistrationStatus.expired => 'expired',
    ClientRegistrationStatus.blocked => 'blocked',
    ClientRegistrationStatus.unknown => 'unknown',
  };
}
