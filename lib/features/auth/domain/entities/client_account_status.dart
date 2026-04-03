enum ClientAccountStatus {
  pending,
  active,
  rejected,
  blocked,
  unknown,
}

extension ClientAccountStatusParsing on ClientAccountStatus {
  static ClientAccountStatus fromRaw(String? rawStatus) {
    return switch (rawStatus?.trim().toLowerCase()) {
      'pending' => ClientAccountStatus.pending,
      'active' => ClientAccountStatus.active,
      'rejected' => ClientAccountStatus.rejected,
      'blocked' => ClientAccountStatus.blocked,
      _ => ClientAccountStatus.unknown,
    };
  }

  String get wireValue => switch (this) {
    ClientAccountStatus.pending => 'pending',
    ClientAccountStatus.active => 'active',
    ClientAccountStatus.rejected => 'rejected',
    ClientAccountStatus.blocked => 'blocked',
    ClientAccountStatus.unknown => 'unknown',
  };
}
