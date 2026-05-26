class OwnerApprovedClient {
  const OwnerApprovedClient({
    required this.clientId,
    required this.clientName,
    this.clientEmail,
    this.accountStatus,
    this.approvedAt,
    this.isStaleCache = false,
  });

  final String clientId;
  final String clientName;
  final String? clientEmail;
  final String? accountStatus;
  final DateTime? approvedAt;
  final bool isStaleCache;
}
