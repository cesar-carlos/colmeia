import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_ranking.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_kpis.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_method_breakdown.dart';
import 'package:colmeia/features/overview/domain/entities/overview_user_ranking.dart';
import 'package:flutter_test/flutter_test.dart';

Overview _overview({
  required bool hasPaymentMethods,
  required List<String> missingIds,
  required List<String> missingNames,
  bool mainResumoHadPlannedTargets = false,
}) {
  return Overview(
    periodStart: DateTime(2026, 4),
    periodEnd: DateTime(2026, 4, 30),
    kpis: OverviewPaymentKpis(
      totalSalesCount: hasPaymentMethods ? 1 : 0,
      totalAmount: hasPaymentMethods ? 10 : 0,
      averageTicket: hasPaymentMethods ? 10 : 0,
      paymentMethodCount: hasPaymentMethods ? 1 : 0,
    ),
    paymentMethods: hasPaymentMethods
        ? const <OverviewPaymentMethodBreakdown>[
            OverviewPaymentMethodBreakdown(
              code: 'X',
              label: 'X',
              totalSalesCount: 1,
              totalAmount: 10,
              averageTicket: 10,
              sharePercent: 100,
            ),
          ]
        : const <OverviewPaymentMethodBreakdown>[],
    agentRankings: const <OverviewAgentRanking>[
      OverviewAgentRanking(
        agentId: 'a',
        displayName: 'A',
        totalSalesCount: 0,
        totalAmount: 0,
      ),
    ],
    userRankings: const <OverviewUserRanking>[],
    agentIdsMissingClientToken: missingIds,
    agentNamesMissingClientToken: missingNames,
    mainResumoHadPlannedTargets: mainResumoHadPlannedTargets,
  );
}

void main() {
  group('Overview.requiresClientTokenSetup', () {
    test(
      'is false when main resumo had planned targets but payment rows are empty '
      '(e.g. other agents lack token only)',
      () {
        final o = _overview(
          hasPaymentMethods: false,
          missingIds: const <String>['b'],
          missingNames: const <String>['B'],
          mainResumoHadPlannedTargets: true,
        );
        expect(o.requiresClientTokenSetup, isFalse);
      },
    );

    test(
      'is true when no agent could run the resumo and agents lack token and '
      'there are no payment rows',
      () {
        final o = _overview(
          hasPaymentMethods: false,
          missingIds: const <String>['a', 'b'],
          missingNames: const <String>['A', 'B'],
        );
        expect(o.requiresClientTokenSetup, isTrue);
      },
    );

    test('is false when there are payment rows even if some agents lack token',
        () {
      final o = _overview(
        hasPaymentMethods: true,
        missingIds: const <String>['b'],
        missingNames: const <String>['B'],
        mainResumoHadPlannedTargets: true,
      );
      expect(o.hasRows, isTrue);
      expect(o.requiresClientTokenSetup, isFalse);
    });
  });

  group('Overview.hasAgentsSkippedDueToHubPresence', () {
    test('is false when the offline-by-hub list is empty', () {
      final o = _overview(
        hasPaymentMethods: false,
        missingIds: const <String>['a'],
        missingNames: const <String>['A'],
      );
      expect(o.hasAgentsSkippedDueToHubPresence, isFalse);
    });

    test(
      'is true when at least one agent was skipped because the hub '
      'reported it offline (independent of missing-token agents)',
      () {
        // Cross-axis sanity: this flag must NOT be derived from
        // missingClientToken / partialFailure. The "agentes offline"
        // banner addresses an entirely different recovery path
        // (operator must reconnect the agent to the hub) than the
        // "save your token" banner.
        final o = Overview(
          periodStart: DateTime(2026, 4),
          periodEnd: DateTime(2026, 4, 30),
          kpis: const OverviewPaymentKpis(
            totalSalesCount: 0,
            totalAmount: 0,
            averageTicket: 0,
            paymentMethodCount: 0,
          ),
          paymentMethods: const <OverviewPaymentMethodBreakdown>[],
          agentRankings: const <OverviewAgentRanking>[],
          userRankings: const <OverviewUserRanking>[],
          agentIdsSkippedDueToHubPresence: const <String>['offline-1'],
          agentNamesSkippedDueToHubPresence:
              const <String>['Offline Agent 1'],
        );
        expect(o.hasAgentsSkippedDueToHubPresence, isTrue);
        expect(o.hasMissingClientToken, isFalse);
        expect(o.hasPartialAgentQueryFailure, isFalse);
      },
    );
  });
}
