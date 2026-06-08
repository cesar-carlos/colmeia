import 'package:checks/checks.dart';
import 'package:colmeia/features/overview/application/overview_shell_cache.dart';
import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_ranking.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_kpis.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_method_breakdown.dart';
import 'package:colmeia/features/overview/domain/entities/overview_progressive_snapshot.dart';
import 'package:colmeia/features/overview/domain/entities/overview_user_ranking.dart';
import 'package:colmeia/features/overview/domain/overview_load_signature.dart';
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
  });
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
