import 'dart:convert';

import 'package:colmeia/features/dashboards/domain/entities/dashboard_filial_ranking.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_overview.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_payment_kpis.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_payment_method_breakdown.dart';
import 'package:colmeia/features/dashboards/domain/entities/dashboard_user_ranking.dart';

class DashboardOverviewModel {
  const DashboardOverviewModel({
    required this.periodStart,
    required this.periodEnd,
    required this.kpis,
    required this.paymentMethods,
    required this.filialRankings,
    required this.userRankings,
  });

  factory DashboardOverviewModel.fromJson(Map<String, dynamic> json) {
    final kpisJson = json['kpis'] as Map<String, dynamic>;
    final paymentMethodsJson =
        json['paymentMethods'] as List<dynamic>? ?? const <dynamic>[];
    final filialRankingsJson =
        json['filialRankings'] as List<dynamic>? ?? const <dynamic>[];
    final userRankingsJson =
        json['userRankings'] as List<dynamic>? ?? const <dynamic>[];

    return DashboardOverviewModel(
      periodStart: DateTime.parse(json['periodStart'] as String),
      periodEnd: DateTime.parse(json['periodEnd'] as String),
      kpis: DashboardPaymentKpis(
        totalSalesCount: kpisJson['totalSalesCount'] as int,
        totalAmount: (kpisJson['totalAmount'] as num).toDouble(),
        averageTicket: (kpisJson['averageTicket'] as num).toDouble(),
        paymentMethodCount: kpisJson['paymentMethodCount'] as int,
      ),
      paymentMethods: paymentMethodsJson.map((item) {
        final row = item as Map<String, dynamic>;
        return DashboardPaymentMethodBreakdown(
          code: row['code'] as String,
          label: row['label'] as String,
          totalSalesCount: row['totalSalesCount'] as int,
          totalAmount: (row['totalAmount'] as num).toDouble(),
          averageTicket: (row['averageTicket'] as num).toDouble(),
          sharePercent: (row['sharePercent'] as num).toDouble(),
        );
      }).toList(growable: false),
      filialRankings: filialRankingsJson.map((item) {
        final row = item as Map<String, dynamic>;
        return DashboardFilialRanking(
          codEmpresa: row['codEmpresa'] as int,
          codFilial: row['codFilial'] as int,
          totalSalesCount: row['totalSalesCount'] as int,
          totalAmount: (row['totalAmount'] as num).toDouble(),
        );
      }).toList(growable: false),
      userRankings: userRankingsJson.map((item) {
        final row = item as Map<String, dynamic>;
        return DashboardUserRanking(
          userName: row['userName'] as String,
          totalSalesCount: row['totalSalesCount'] as int,
          totalAmount: (row['totalAmount'] as num).toDouble(),
          averageTicket: (row['averageTicket'] as num).toDouble(),
        );
      }).toList(growable: false),
    );
  }

  factory DashboardOverviewModel.decode(String raw) {
    return DashboardOverviewModel.fromJson(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  factory DashboardOverviewModel.fromEntity(DashboardOverview overview) {
    return DashboardOverviewModel(
      periodStart: overview.periodStart,
      periodEnd: overview.periodEnd,
      kpis: overview.kpis,
      paymentMethods: overview.paymentMethods,
      filialRankings: overview.filialRankings,
      userRankings: overview.userRankings,
    );
  }

  final DateTime periodStart;
  final DateTime periodEnd;
  final DashboardPaymentKpis kpis;
  final List<DashboardPaymentMethodBreakdown> paymentMethods;
  final List<DashboardFilialRanking> filialRankings;
  final List<DashboardUserRanking> userRankings;

  DashboardOverview toEntity() {
    return DashboardOverview(
      periodStart: periodStart,
      periodEnd: periodEnd,
      kpis: kpis,
      paymentMethods: paymentMethods,
      filialRankings: filialRankings,
      userRankings: userRankings,
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
      'filialRankings': filialRankings.map((item) {
        return <String, Object?>{
          'codEmpresa': item.codEmpresa,
          'codFilial': item.codFilial,
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
    };
  }

  String encode() => jsonEncode(toJson());
}
