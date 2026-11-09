import 'package:colmeia/features/pwa/domain/offline_authorization.dart';

class OfflinePackage {
  const OfflinePackage({
    required this.authorization,
    required this.agentId,
    required this.savedAt,
    required this.periodStart,
    required this.periodEnd,
    required this.datasets,
  });
  factory OfflinePackage.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1 ||
        json['authorization'] is! Map<String, dynamic> ||
        json['agentId'] is! String ||
        json['savedAt'] is! String ||
        json['periodStart'] is! String ||
        json['periodEnd'] is! String ||
        json['datasets'] is! Map<String, dynamic>) {
      throw const FormatException('Unsupported offline package');
    }
    return OfflinePackage(
      authorization: OfflineAuthorization.fromJson(
        Map<String, dynamic>.from(json['authorization'] as Map),
      ),
      agentId: json['agentId'] as String,
      savedAt: DateTime.parse(json['savedAt'] as String),
      periodStart: DateTime.parse(json['periodStart'] as String),
      periodEnd: DateTime.parse(json['periodEnd'] as String),
      datasets: Map<String, dynamic>.from(json['datasets'] as Map),
    );
  }
  final OfflineAuthorization authorization;
  final String agentId;
  final DateTime savedAt;
  final DateTime periodStart;
  final DateTime periodEnd;
  final Map<String, dynamic> datasets;
  Map<String, Object?> toJson() => {
    'version': 1,
    'authorization': authorization.toJson(),
    'agentId': agentId,
    'savedAt': savedAt.toIso8601String(),
    'periodStart': periodStart.toIso8601String(),
    'periodEnd': periodEnd.toIso8601String(),
    'datasets': datasets,
    'datasetMetadata': {
      for (final key in datasets.keys)
        key: {
          'userId': authorization.userId,
          'agentId': agentId,
          'formatVersion': 1,
          'periodStart': periodStart.toIso8601String(),
          'periodEnd': periodEnd.toIso8601String(),
          'collectedAt': savedAt.toIso8601String(),
          'complete': true,
          'currentDayPartial': true,
          'parameters': {
            'agentIds': [agentId],
          },
        },
    },
  };
}
