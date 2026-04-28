class OwnerApprovedClient {
  const OwnerApprovedClient({
    required this.clientId,
    required this.clientName,
    this.clientEmail,
    this.accountStatus,
    this.approvedAt,
  });

  final String clientId;
  final String clientName;
  final String? clientEmail;
  final String? accountStatus;
  final DateTime? approvedAt;
}
