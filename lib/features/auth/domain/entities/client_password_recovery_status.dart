enum ClientPasswordRecoveryStatus {
  pending,
  expired,
  invalid,
  unknown,
}

extension ClientPasswordRecoveryStatusParsing on ClientPasswordRecoveryStatus {
  static ClientPasswordRecoveryStatus fromRaw(String? rawStatus) {
    return switch (rawStatus?.trim().toLowerCase()) {
      'pending' => ClientPasswordRecoveryStatus.pending,
      'expired' => ClientPasswordRecoveryStatus.expired,
      _ => ClientPasswordRecoveryStatus.unknown,
    };
  }

  String get wireValue {
    return switch (this) {
      ClientPasswordRecoveryStatus.pending => 'pending',
      ClientPasswordRecoveryStatus.expired => 'expired',
      ClientPasswordRecoveryStatus.invalid => 'invalid',
      ClientPasswordRecoveryStatus.unknown => 'unknown',
    };
  }
}
