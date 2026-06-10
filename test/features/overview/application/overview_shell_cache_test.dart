import 'package:checks/checks.dart';
import 'package:colmeia/features/overview/application/overview_shell_cache.dart';
import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_ranking.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_kpis.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_method_breakdown.dart';
import 'package:colmeia/features/overview/domain/entities/overview_progressive_snapshot.dart';
import 'package:colmeia/features/overview/domain/entities/overview_user_ranking.dart';
import 'package:colmeia/features/overview/domain/entities/overview_weekday_sales_trend_point.dart';
import 'package:colmeia/features/overview/domain/overview_load_signature.dart';
import 'package:colmeia/shared/charts/daily_sales_trend_point.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OverviewShellCache', () {
    late OverviewShellCache cache;

    setUp(() {
      cache = OverviewShellCache();
    });

    test('read returns null when empty or signature mismatches', () {
      check(cache.read('user|*|default')).isNull();

      cache.publish(
        signature: 'user|*|default',
        overview: _overview(),
        activeFilter: DashboardFilter.initial(),
        availableAgents: const <DashboardAgentOption>[],
        completedSections: OverviewProgressiveSection.values.toSet(),
      );

      check(cache.read('other|*|default')).isNull();
      check(cache.read('user|*|default')).isNotNull();
    });

    test('invalidate clears the entry', () {
      final signature = overviewLoadSignature(
        userId: 'user',
        filter: DashboardFilter.initial(),
      );
      cache
        ..publish(
          signature: signature,
          overview: _overview(),
          activeFilter: DashboardFilter.initial(),
          availableAgents: const <DashboardAgentOption>[],
          completedSections: OverviewProgressiveSection.values.toSet(),
        )
        ..invalidate();

      check(cache.read(signature)).isNull();
    });

    test('mergePublish is a no-op when signature is missing', () {
      cache.mergePublish(
        signature: 'missing',
        detailOverview: _overviewWithDailySales(),
        section: OverviewProgressiveSection.dailySales,
        addedSections: <OverviewProgressiveSection>{
          OverviewProgressiveSection.dailySales,
        },
      );

      check(cache.read('missing')).isNull();
    });

    test('mergePublish merges daily sales and preserves KPIs', () {
      final signature = overviewLoadSignature(
        userId: 'user',
        filter: DashboardFilter.initial(),
      );
      final base = _overview();
      cache.publish(
        signature: signature,
        overview: base,
        activeFilter: DashboardFilter.initial(),
        availableAgents: const <DashboardAgentOption>[],
        completedSections: <OverviewProgressiveSection>{
          OverviewProgressiveSection.summary,
        },
      );

      final detail = _overviewWithDailySales();
      cache.mergePublish(
        signature: signature,
        detailOverview: detail,
        section: OverviewProgressiveSection.dailySales,
        addedSections: <OverviewProgressiveSection>{
          OverviewProgressiveSection.dailySales,
        },
      );

      final entry = cache.read(signature);
      check(entry).isNotNull();
      check(
        entry!.completedSections,
      ).contains(OverviewProgressiveSection.dailySales);
      check(entry.overview.dailySalesTrend).deepEquals(detail.dailySalesTrend);
      check(entry.overview.kpis.totalAmount).equals(base.kpis.totalAmount);
    });

    test('mergePublish accumulates completed sections', () {
      final signature = overviewLoadSignature(
        userId: 'user',
        filter: DashboardFilter.initial(),
      );
      cache
        ..publish(
          signature: signature,
          overview: _overview(),
          activeFilter: DashboardFilter.initial(),
          availableAgents: const <DashboardAgentOption>[],
          completedSections: <OverviewProgressiveSection>{
            OverviewProgressiveSection.summary,
          },
        )
        ..mergePublish(
          signature: signature,
          detailOverview: _overviewWithDailySales(),
          section: OverviewProgressiveSection.dailySales,
          addedSections: <OverviewProgressiveSection>{
            OverviewProgressiveSection.dailySales,
          },
        )
        ..mergePublish(
          signature: signature,
          detailOverview: _overviewWithWeekdaySales(),
          section: OverviewProgressiveSection.weekdaySales,
          addedSections: <OverviewProgressiveSection>{
            OverviewProgressiveSection.weekdaySales,
          },
        );

      final entry = cache.read(signature);
      check(entry!.completedSections).deepEquals(<OverviewProgressiveSection>{
        OverviewProgressiveSection.summary,
        OverviewProgressiveSection.dailySales,
        OverviewProgressiveSection.weekdaySales,
      });
    });

    test('mergePublish preserves activeFilter and availableAgents', () {
      final signature = overviewLoadSignature(
        userId: 'user',
        filter: DashboardFilter.initial(),
      );
      const agents = <DashboardAgentOption>[
        DashboardAgentOption(agentId: 'a1', name: 'Agent 1'),
      ];
      final filter = DashboardFilter.initial();
      cache
        ..publish(
          signature: signature,
          overview: _overview(),
          activeFilter: filter,
          availableAgents: agents,
          completedSections: <OverviewProgressiveSection>{
            OverviewProgressiveSection.summary,
          },
        )
        ..mergePublish(
          signature: signature,
          detailOverview: _overviewWithDailySales(),
          section: OverviewProgressiveSection.dailySales,
          addedSections: <OverviewProgressiveSection>{
            OverviewProgressiveSection.dailySales,
          },
        );

      final entry = cache.read(signature);
      check(entry!.activeFilter).equals(filter);
      check(entry.availableAgents).deepEquals(agents);
    });
  });
}

Overview _overviewWithDailySales() {
  return _overview().copyWith(
    dailySalesTrend: <DailySalesTrendPoint>[
      DailySalesTrendPoint(
        saleDate: DateTime(2026, 3, 15),
        salesCount: 9,
        salesAmount: 90,
      ),
    ],
  );
}

Overview _overviewWithWeekdaySales() {
  return _overview().copyWith(
    weekdaySalesTrend: const <OverviewWeekdaySalesTrendPoint>[
      OverviewWeekdaySalesTrendPoint(
        weekdayNumber: 3,
        salesCount: 7,
        salesAmount: 70,
      ),
    ],
  );
}

Overview _overview() {
  return Overview(
    periodStart: DateTime(2026, 3, 9),
    periodEnd: DateTime(2026, 4, 7),
    kpis: const OverviewPaymentKpis(
      totalSalesCount: 1,
      totalAmount: 10,
      averageTicket: 10,
      paymentMethodCount: 1,
    ),
    paymentMethods: const <OverviewPaymentMethodBreakdown>[
      OverviewPaymentMethodBreakdown(
        code: 'Pix',
        label: 'Pix',
        totalSalesCount: 1,
        totalAmount: 10,
        averageTicket: 10,
        sharePercent: 100,
      ),
    ],
    agentRankings: const <OverviewAgentRanking>[],
    userRankings: const <OverviewUserRanking>[],
  );
}
