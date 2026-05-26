import 'dart:convert';

import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_mensal_row.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_produto_venda_lucratividade_row.dart';
import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_ranking.dart';
import 'package:colmeia/features/overview/domain/entities/overview_monthly_parcel_point.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_kpis.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_method_breakdown.dart';
import 'package:colmeia/features/overview/domain/entities/overview_user_ranking.dart';
import 'package:colmeia/features/overview/domain/entities/overview_weekday_sales_trend_point.dart';
import 'package:colmeia/features/overview/domain/entities/overview_weekday_user_sales_trend_point.dart';
import 'package:colmeia/shared/charts/daily_sales_trend_point.dart';

class OverviewModel {
  const OverviewModel({
    required this.periodStart,
    required this.periodEnd,
    required this.kpis,
    required this.paymentMethods,
    required this.agentRankings,
    required this.userRankings,
    this.monthlyParcelTrend = const <OverviewMonthlyParcelPoint>[],
    this.monthlyParcelTrendLoadFailed = false,
    this.monthlyParcelTrendLoadFailureMessage,
    this.weekdaySalesTrend = const <OverviewWeekdaySalesTrendPoint>[],
    this.weekdaySalesTrendLoadFailed = false,
    this.weekdaySalesTrendLoadFailureMessage,
    this.weekdayUserSalesTrend = const <OverviewWeekdayUserSalesTrendPoint>[],
    this.weekdayUserSalesTrendLoadFailed = false,
    this.weekdayUserSalesTrendLoadFailureMessage,
    this.dailySalesTrend = const <DailySalesTrendPoint>[],
    this.dailySalesTrendLoadFailed = false,
    this.dailySalesTrendLoadFailureMessage,
    this.lucratividadeMensalTrend =
        const <ResumoProdutoVendaLucratividadeMensalRow>[],
    this.lucratividadeMensalTrendLoadFailed = false,
    this.lucratividadeMensalTrendLoadFailureMessage,
    this.lucratividadeTrend = const <ResumoProdutoVendaLucratividadeRow>[],
    this.lucratividadeTrendLoadFailed = false,
    this.lucratividadeTrendLoadFailureMessage,
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
    final monthlyJson =
        json['monthlyParcelTrend'] as List<dynamic>? ?? const <dynamic>[];
    final monthlyParcelTrendLoadFailed =
        json['monthlyParcelTrendLoadFailed'] as bool? ?? false;
    final weekdayJson =
        json['weekdaySalesTrend'] as List<dynamic>? ?? const <dynamic>[];
    final weekdaySalesTrendLoadFailed =
        json['weekdaySalesTrendLoadFailed'] as bool? ?? false;
    final weekdayUserJson =
        json['weekdayUserSalesTrend'] as List<dynamic>? ?? const <dynamic>[];
    final weekdayUserSalesTrendLoadFailed =
        json['weekdayUserSalesTrendLoadFailed'] as bool? ?? false;
    final dailyJson =
        json['dailySalesTrend'] as List<dynamic>? ?? const <dynamic>[];
    final dailySalesTrendLoadFailed =
        json['dailySalesTrendLoadFailed'] as bool? ?? false;
    final lucratividadeMensalJson =
        json['lucratividadeMensalTrend'] as List<dynamic>? ?? const <dynamic>[];
    final lucratividadeMensalTrendLoadFailed =
        json['lucratividadeMensalTrendLoadFailed'] as bool? ?? false;
    final lucratividadeJson =
        json['lucratividadeTrend'] as List<dynamic>? ?? const <dynamic>[];
    final lucratividadeTrendLoadFailed =
        json['lucratividadeTrendLoadFailed'] as bool? ?? false;

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
      paymentMethods: paymentMethodsJson
          .map((item) {
            final row = item as Map<String, dynamic>;
            return OverviewPaymentMethodBreakdown(
              code: row['code'] as String,
              label: row['label'] as String,
              totalSalesCount: row['totalSalesCount'] as int,
              totalAmount: (row['totalAmount'] as num).toDouble(),
              averageTicket: (row['averageTicket'] as num).toDouble(),
              sharePercent: (row['sharePercent'] as num).toDouble(),
            );
          })
          .toList(growable: false),
      agentRankings: agentRankingsJson
          .map((item) {
            final row = item as Map<String, dynamic>;
            return OverviewAgentRanking(
              agentId: row['agentId'] as String,
              displayName: row['displayName'] as String,
              totalSalesCount: row['totalSalesCount'] as int,
              totalAmount: (row['totalAmount'] as num).toDouble(),
            );
          })
          .toList(growable: false),
      userRankings: userRankingsJson
          .map((item) {
            final row = item as Map<String, dynamic>;
            return OverviewUserRanking(
              userName: row['userName'] as String,
              totalSalesCount: row['totalSalesCount'] as int,
              totalAmount: (row['totalAmount'] as num).toDouble(),
              averageTicket: (row['averageTicket'] as num).toDouble(),
            );
          })
          .toList(growable: false),
      monthlyParcelTrend: monthlyJson
          .map((item) {
            final row = item as Map<String, dynamic>;
            return OverviewMonthlyParcelPoint(
              anoMes: row['anoMes'] as String,
              qtdVendas: row['qtdVendas'] as int,
              valorParcela: (row['valorParcela'] as num).toDouble(),
            );
          })
          .toList(growable: false),
      monthlyParcelTrendLoadFailed: monthlyParcelTrendLoadFailed,
      weekdaySalesTrend: weekdayJson
          .map((item) {
            final row = item as Map<String, dynamic>;
            return OverviewWeekdaySalesTrendPoint(
              weekdayNumber: row['weekdayNumber'] as int,
              salesCount: row['salesCount'] as int,
              salesAmount: (row['salesAmount'] as num).toDouble(),
            );
          })
          .toList(growable: false),
      weekdaySalesTrendLoadFailed: weekdaySalesTrendLoadFailed,
      weekdayUserSalesTrend: weekdayUserJson
          .map((item) {
            final row = item as Map<String, dynamic>;
            return OverviewWeekdayUserSalesTrendPoint(
              weekdayNumber: row['weekdayNumber'] as int,
              userName: row['userName'] as String,
              salesCount: row['salesCount'] as int,
              salesAmount: (row['salesAmount'] as num).toDouble(),
            );
          })
          .toList(growable: false),
      weekdayUserSalesTrendLoadFailed: weekdayUserSalesTrendLoadFailed,
      dailySalesTrend: dailyJson
          .map((item) {
            final row = item as Map<String, dynamic>;
            return DailySalesTrendPoint(
              saleDate: DateTime.parse(row['saleDate'] as String),
              salesCount: row['salesCount'] as int,
              salesAmount: (row['salesAmount'] as num).toDouble(),
            );
          })
          .toList(growable: false),
      dailySalesTrendLoadFailed: dailySalesTrendLoadFailed,
      lucratividadeMensalTrend: lucratividadeMensalJson
          .map((item) {
            final row = item as Map<String, dynamic>;
            return ResumoProdutoVendaLucratividadeMensalRow(
              codEmpresa: row['codEmpresa'] as int,
              codFilial: row['codFilial'] as int,
              ano: row['ano'] as int,
              mes: row['mes'] as int,
              anoMes: row['anoMes'] as String,
              qtdVendas: row['qtdVendas'] as int,
              qtdItensVendido: (row['qtdItensVendido'] as num).toDouble(),
              valorTotalCustoMedio: (row['valorTotalCustoMedio'] as num)
                  .toDouble(),
              custoReposicao: (row['custoReposicao'] as num).toDouble(),
              pontoEquilibrio: (row['pontoEquilibrio'] as num).toDouble(),
              valorTotalItem: (row['valorTotalItem'] as num).toDouble(),
            );
          })
          .toList(growable: false),
      lucratividadeMensalTrendLoadFailed: lucratividadeMensalTrendLoadFailed,
      lucratividadeTrend: lucratividadeJson
          .map((item) {
            final row = item as Map<String, dynamic>;
            return ResumoProdutoVendaLucratividadeRow(
              codEmpresa: row['codEmpresa'] as int,
              codFilial: row['codFilial'] as int,
              qtdVendas: row['qtdVendas'] as int,
              qtdItensVendido: (row['qtdItensVendido'] as num).toDouble(),
              valorTotalCustoMedio: (row['valorTotalCustoMedio'] as num)
                  .toDouble(),
              custoReposicao: (row['custoReposicao'] as num).toDouble(),
              pontoEquilibrio: (row['pontoEquilibrio'] as num).toDouble(),
              valorTotalItem: (row['valorTotalItem'] as num).toDouble(),
              chartAxisLabel: row['chartAxisLabel'] as String?,
            );
          })
          .toList(growable: false),
      lucratividadeTrendLoadFailed: lucratividadeTrendLoadFailed,
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
      monthlyParcelTrend: overview.monthlyParcelTrend,
      monthlyParcelTrendLoadFailed: overview.monthlyParcelTrendLoadFailed,
      monthlyParcelTrendLoadFailureMessage:
          overview.monthlyParcelTrendLoadFailureMessage,
      weekdaySalesTrend: overview.weekdaySalesTrend,
      weekdaySalesTrendLoadFailed: overview.weekdaySalesTrendLoadFailed,
      weekdaySalesTrendLoadFailureMessage:
          overview.weekdaySalesTrendLoadFailureMessage,
      weekdayUserSalesTrend: overview.weekdayUserSalesTrend,
      weekdayUserSalesTrendLoadFailed: overview.weekdayUserSalesTrendLoadFailed,
      weekdayUserSalesTrendLoadFailureMessage:
          overview.weekdayUserSalesTrendLoadFailureMessage,
      dailySalesTrend: overview.dailySalesTrend,
      dailySalesTrendLoadFailed: overview.dailySalesTrendLoadFailed,
      dailySalesTrendLoadFailureMessage:
          overview.dailySalesTrendLoadFailureMessage,
      lucratividadeMensalTrend: overview.lucratividadeMensalTrend,
      lucratividadeMensalTrendLoadFailed:
          overview.lucratividadeMensalTrendLoadFailed,
      lucratividadeMensalTrendLoadFailureMessage:
          overview.lucratividadeMensalTrendLoadFailureMessage,
      lucratividadeTrend: overview.lucratividadeTrend,
      lucratividadeTrendLoadFailed: overview.lucratividadeTrendLoadFailed,
      lucratividadeTrendLoadFailureMessage:
          overview.lucratividadeTrendLoadFailureMessage,
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

  final List<OverviewMonthlyParcelPoint> monthlyParcelTrend;

  final bool monthlyParcelTrendLoadFailed;

  /// Transient runtime field; not persisted in [toJson] (cache is offline /
  /// signature-driven, so a stale auth message would be misleading after
  /// app restart).
  final String? monthlyParcelTrendLoadFailureMessage;

  final List<OverviewWeekdaySalesTrendPoint> weekdaySalesTrend;

  final bool weekdaySalesTrendLoadFailed;

  /// See [monthlyParcelTrendLoadFailureMessage] — transient runtime field.
  final String? weekdaySalesTrendLoadFailureMessage;

  final List<OverviewWeekdayUserSalesTrendPoint> weekdayUserSalesTrend;

  final bool weekdayUserSalesTrendLoadFailed;

  /// See [monthlyParcelTrendLoadFailureMessage] — transient runtime field.
  final String? weekdayUserSalesTrendLoadFailureMessage;

  final List<DailySalesTrendPoint> dailySalesTrend;

  final bool dailySalesTrendLoadFailed;

  /// Transient runtime field; not persisted in [toJson].
  final String? dailySalesTrendLoadFailureMessage;

  final List<ResumoProdutoVendaLucratividadeMensalRow> lucratividadeMensalTrend;

  final bool lucratividadeMensalTrendLoadFailed;

  /// Transient runtime field; not persisted in [toJson].
  final String? lucratividadeMensalTrendLoadFailureMessage;

  final List<ResumoProdutoVendaLucratividadeRow> lucratividadeTrend;

  final bool lucratividadeTrendLoadFailed;

  /// Transient runtime field; not persisted in [toJson].
  final String? lucratividadeTrendLoadFailureMessage;

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
      monthlyParcelTrend: monthlyParcelTrend,
      monthlyParcelTrendLoadFailed: monthlyParcelTrendLoadFailed,
      monthlyParcelTrendLoadFailureMessage:
          monthlyParcelTrendLoadFailureMessage,
      weekdaySalesTrend: weekdaySalesTrend,
      weekdaySalesTrendLoadFailed: weekdaySalesTrendLoadFailed,
      weekdaySalesTrendLoadFailureMessage: weekdaySalesTrendLoadFailureMessage,
      weekdayUserSalesTrend: weekdayUserSalesTrend,
      weekdayUserSalesTrendLoadFailed: weekdayUserSalesTrendLoadFailed,
      weekdayUserSalesTrendLoadFailureMessage:
          weekdayUserSalesTrendLoadFailureMessage,
      dailySalesTrend: dailySalesTrend,
      dailySalesTrendLoadFailed: dailySalesTrendLoadFailed,
      dailySalesTrendLoadFailureMessage: dailySalesTrendLoadFailureMessage,
      lucratividadeMensalTrend: lucratividadeMensalTrend,
      lucratividadeMensalTrendLoadFailed: lucratividadeMensalTrendLoadFailed,
      lucratividadeMensalTrendLoadFailureMessage:
          lucratividadeMensalTrendLoadFailureMessage,
      lucratividadeTrend: lucratividadeTrend,
      lucratividadeTrendLoadFailed: lucratividadeTrendLoadFailed,
      lucratividadeTrendLoadFailureMessage:
          lucratividadeTrendLoadFailureMessage,
      isStaleCache: isStaleCache,
    );
  }

  /// JSON persisted for offline/stale recovery. Excludes weekday-by-user
  /// fields to keep payload small (high-cardinality series); those fields
  /// reload on next successful fetch. Legacy cache files may still contain
  /// those keys; `fromJson` continues to parse them when present.
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
      'paymentMethods': paymentMethods
          .map((item) {
            return <String, Object?>{
              'code': item.code,
              'label': item.label,
              'totalSalesCount': item.totalSalesCount,
              'totalAmount': item.totalAmount,
              'averageTicket': item.averageTicket,
              'sharePercent': item.sharePercent,
            };
          })
          .toList(growable: false),
      'agentRankings': agentRankings
          .map((item) {
            return <String, Object?>{
              'agentId': item.agentId,
              'displayName': item.displayName,
              'totalSalesCount': item.totalSalesCount,
              'totalAmount': item.totalAmount,
            };
          })
          .toList(growable: false),
      'userRankings': userRankings
          .map((item) {
            return <String, Object?>{
              'userName': item.userName,
              'totalSalesCount': item.totalSalesCount,
              'totalAmount': item.totalAmount,
              'averageTicket': item.averageTicket,
            };
          })
          .toList(growable: false),
      'monthlyParcelTrend': monthlyParcelTrend
          .map(
            (p) => <String, Object?>{
              'anoMes': p.anoMes,
              'qtdVendas': p.qtdVendas,
              'valorParcela': p.valorParcela,
            },
          )
          .toList(growable: false),
      'monthlyParcelTrendLoadFailed': monthlyParcelTrendLoadFailed,
      'weekdaySalesTrend': weekdaySalesTrend
          .map(
            (p) => <String, Object?>{
              'weekdayNumber': p.weekdayNumber,
              'salesCount': p.salesCount,
              'salesAmount': p.salesAmount,
            },
          )
          .toList(growable: false),
      'weekdaySalesTrendLoadFailed': weekdaySalesTrendLoadFailed,
      'dailySalesTrend': dailySalesTrend
          .map(
            (p) => <String, Object?>{
              'saleDate': p.saleDate.toIso8601String(),
              'salesCount': p.salesCount,
              'salesAmount': p.salesAmount,
            },
          )
          .toList(growable: false),
      'dailySalesTrendLoadFailed': dailySalesTrendLoadFailed,
      'lucratividadeMensalTrend': lucratividadeMensalTrend
          .map(
            (p) => <String, Object?>{
              'codEmpresa': p.codEmpresa,
              'codFilial': p.codFilial,
              'ano': p.ano,
              'mes': p.mes,
              'anoMes': p.anoMes,
              'qtdVendas': p.qtdVendas,
              'qtdItensVendido': p.qtdItensVendido,
              'valorTotalCustoMedio': p.valorTotalCustoMedio,
              'custoReposicao': p.custoReposicao,
              'pontoEquilibrio': p.pontoEquilibrio,
              'valorTotalItem': p.valorTotalItem,
            },
          )
          .toList(growable: false),
      'lucratividadeMensalTrendLoadFailed': lucratividadeMensalTrendLoadFailed,
      'lucratividadeTrend': lucratividadeTrend
          .map(
            (p) => <String, Object?>{
              'codEmpresa': p.codEmpresa,
              'codFilial': p.codFilial,
              'qtdVendas': p.qtdVendas,
              'qtdItensVendido': p.qtdItensVendido,
              'valorTotalCustoMedio': p.valorTotalCustoMedio,
              'custoReposicao': p.custoReposicao,
              'pontoEquilibrio': p.pontoEquilibrio,
              'valorTotalItem': p.valorTotalItem,
              if (p.chartAxisLabel != null) 'chartAxisLabel': p.chartAxisLabel,
            },
          )
          .toList(growable: false),
      'lucratividadeTrendLoadFailed': lucratividadeTrendLoadFailed,
      if (cachedAt != null) 'cachedAt': cachedAt!.toIso8601String(),
      if (sourceAgentIds != null) 'sourceAgentIds': sourceAgentIds,
    };
  }

  String encode() => jsonEncode(toJson());
}
