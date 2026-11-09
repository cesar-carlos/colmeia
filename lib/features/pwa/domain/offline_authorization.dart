class OfflineAuthorization {
  OfflineAuthorization({
    required this.userId,
    required Set<String> agentIds,
    required this.issuedAt,
    required this.expiresAt,
  }) : agentIds = Set.unmodifiable(agentIds);
  factory OfflineAuthorization.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1 ||
        json['userId'] is! String ||
        json['agentIds'] is! List ||
        (json['agentIds'] as List).any((value) => value is! String) ||
        json['issuedAt'] is! String ||
        json['expiresAt'] is! String) {
      throw const FormatException('Unsupported offline authorization');
    }
    return OfflineAuthorization(
      userId: json['userId'] as String,
      agentIds: (json['agentIds'] as List).cast<String>().toSet(),
      issuedAt: DateTime.parse(json['issuedAt'] as String).toUtc(),
      expiresAt: DateTime.parse(json['expiresAt'] as String).toUtc(),
    );
  }
  final String userId;
  final Set<String> agentIds;
  final DateTime issuedAt;
  final DateTime expiresAt;
  bool permits(String user, String agent, DateTime now) =>
      user == userId &&
      agentIds.contains(agent) &&
      !now.isBefore(issuedAt) &&
      now.isBefore(expiresAt) &&
      expiresAt.isAfter(issuedAt) &&
      expiresAt.difference(issuedAt) <= const Duration(hours: 24);
  Map<String, Object?> toJson() => {
    'version': 1,
    'userId': userId,
    'agentIds': agentIds.toList()..sort(),
    'issuedAt': issuedAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
  };
}
