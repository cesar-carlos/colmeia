import 'dart:convert';

import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_ranking.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_kpis.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_method_breakdown.dart';
import 'package:colmeia/features/overview/domain/entities/overview_user_ranking.dart';

class OverviewModel {
  const OverviewModel({
    required this.periodStart,
    required this.periodEnd,
    required this.kpis,
    required this.paymentMethods,
    required this.agentRankings,
    required this.userRankings,
    this.cachedAt,
    this.sourceAgentIds,
  });

  factory OverviewModel.fromJson(Map<String, dynamic> json) {
    final kpisJson = json['kpis'] as Map<String, dynamic>;
    final paymentMethodsJson =
        json['paymentMethods'] as List<dynamic>? ?? const <dynamic>[];
    final agentRankingsJson =
        json['agentRankings'] as List<dynamic>? ?? const <dynamic>[];
    final userRankingsJson =
        json['userRankings'] as List<dynamic>? ?? const <dynamic>[];

    final cachedAt = json['cachedAt'] is String
        ? DateTime.tryParse(json['cachedAt'] as String)
        : null;
    final sourceAgentIds = (json['sourceAgentIds'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList(growable: false);

    return OverviewModel(
      periodStart: DateTime.parse(json['periodStart'] as String),
      periodEnd: DateTime.parse(json['periodEnd'] as String),
      kpis: OverviewPaymentKpis(
        totalSalesCount: kpisJson['totalSalesCount'] as int,
        totalAmount: (kpisJson['totalAmount'] as num).toDouble(),
        averageTicket: (kpisJson['averageTicket'] as num).toDouble(),
        paymentMethodCount: kpisJson['paymentMethodCount'] as int,
      ),
      paymentMethods: paymentMethodsJson.map((item) {
        final row = item as Map<String, dynamic>;
        return OverviewPaymentMethodBreakdown(
          code: row['code'] as String,
          label: row['label'] as String,
          totalSalesCount: row['totalSalesCount'] as int,
          totalAmount: (row['totalAmount'] as num).toDouble(),
          averageTicket: (row['averageTicket'] as num).toDouble(),
          sharePercent: (row['sharePercent'] as num).toDouble(),
        );
      }).toList(growable: false),
      agentRankings: agentRankingsJson.map((item) {
        final row = item as Map<String, dynamic>;
        return OverviewAgentRanking(
          agentId: row['agentId'] as String,
          displayName: row['displayName'] as String,
          totalSalesCount: row['totalSalesCount'] as int,
          totalAmount: (row['totalAmount'] as num).toDouble(),
        );
      }).toList(growable: false),
      userRankings: userRankingsJson.map((item) {
        final row = item as Map<String, dynamic>;
        return OverviewUserRanking(
          userName: row['userName'] as String,
          totalSalesCount: row['totalSalesCount'] as int,
          totalAmount: (row['totalAmount'] as num).toDouble(),
          averageTicket: (row['averageTicket'] as num).toDouble(),
        );
      }).toList(growable: false),
      cachedAt: cachedAt,
      sourceAgentIds: sourceAgentIds,
    );
  }

  factory OverviewModel.decode(String raw) {
    return OverviewModel.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  factory OverviewModel.fromEntity(
    Overview overview, {
    DateTime? cachedAt,
    List<String>? sourceAgentIds,
  }) {
    return OverviewModel(
      periodStart: overview.periodStart,
      periodEnd: overview.periodEnd,
      kpis: overview.kpis,
      paymentMethods: overview.paymentMethods,
      agentRankings: overview.agentRankings,
      userRankings: overview.userRankings,
      cachedAt: cachedAt,
      sourceAgentIds: sourceAgentIds,
    );
  }

  final DateTime periodStart;
  final DateTime periodEnd;
  final OverviewPaymentKpis kpis;
  final List<OverviewPaymentMethodBreakdown> paymentMethods;
  final List<OverviewAgentRanking> agentRankings;
  final List<OverviewUserRanking> userRankings;

  /// When the overview was persisted locally (for TTL / signature checks).
  final DateTime? cachedAt;

  /// Sorted at persistence time; used to avoid mixing datasets across agents.
  final List<String>? sourceAgentIds;

  Overview toEntity({bool isStaleCache = false}) {
    return Overview(
      periodStart: periodStart,
      periodEnd: periodEnd,
      kpis: kpis,
      paymentMethods: paymentMethods,
      agentRankings: agentRankings,
      userRankings: userRankings,
      isStaleCache: isStaleCache,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'periodStart': periodStart.toIso8601String(),
      'periodEnd': periodEnd.toIso8601String(),
      'kpis': <String, Object?>{
        'totalSalesCount': kpis.totalSalesCount,
        'totalAmount': kpis.totalAmount,
        'averageTicket': kpis.averageTicket,
        'paymentMethodCount': kpis.paymentMethodCount,
      },
      'paymentMethods': paymentMethods.map((item) {
        return <String, Object?>{
          'code': item.code,
          'label': item.label,
          'totalSalesCount': item.totalSalesCount,
          'totalAmount': item.totalAmount,
          'averageTicket': item.averageTicket,
          'sharePercent': item.sharePercent,
        };
      }).toList(growable: false),
      'agentRankings': agentRankings.map((item) {
        return <String, Object?>{
          'agentId': item.agentId,
          'displayName': item.displayName,
          'totalSalesCount': item.totalSalesCount,
          'totalAmount': item.totalAmount,
        };
      }).toList(growable: false),
      'userRankings': userRankings.map((item) {
        return <String, Object?>{
          'userName': item.userName,
          'totalSalesCount': item.totalSalesCount,
          'totalAmount': item.totalAmount,
          'averageTicket': item.averageTicket,
        };
      }).toList(growable: false),
      if (cachedAt != null) 'cachedAt': cachedAt!.toIso8601String(),
      if (sourceAgentIds != null) 'sourceAgentIds': sourceAgentIds,
    };
  }

  String encode() => jsonEncode(toJson());
}
