import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_ranking.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_kpis.dart';
import 'package:colmeia/features/overview/presentation/overview_available_agents_assembler.dart';
import 'package:flutter_test/flutter_test.dart';

Overview _minimalOverview({
  List<OverviewAgentRanking> rankings = const [],
  List<String> failedIds = const [],
  List<String> failedNames = const [],
  List<String> missingTokenIds = const [],
  List<String> missingTokenNames = const [],
}) {
  return Overview(
    periodStart: DateTime(2024),
    periodEnd: DateTime(2024, 1, 2),
    kpis: const OverviewPaymentKpis(
      totalSalesCount: 0,
      totalAmount: 0,
      averageTicket: 0,
      paymentMethodCount: 0,
    ),
    paymentMethods: const [],
    agentRankings: rankings,
    userRankings: const [],
    agentIdsExcludedFromQueryFailure: failedIds,
    agentNamesExcludedFromQueryFailure: failedNames,
    agentIdsMissingClientToken: missingTokenIds,
    agentNamesMissingClientToken: missingTokenNames,
  );
}

void main() {
  group('OverviewAvailableAgentsAssembler', () {
    test('merges rankings and failure rows', () {
      final overview = _minimalOverview(
        rankings: const [
          OverviewAgentRanking(
            agentId: 'a1',
            displayName: 'Alpha',
            totalAmount: 1,
            totalSalesCount: 1,
          ),
        ],
        failedIds: ['a2'],
        failedNames: ['Beta'],
      );
      final out = OverviewAvailableAgentsAssembler.assemble(
        overview: overview,
        previousOptions: const [],
        onlineAgentIds: {'a1'},
      );
      expect(out.length, 2);
      final byId = {for (final o in out) o.agentId: o};
      expect(byId['a1']!.name, 'Alpha');
      expect(byId['a1']!.connectionStatus, AgentConnectionStatus.online);
      expect(byId['a2']!.name, 'Beta');
      expect(byId['a2']!.connectionStatus, AgentConnectionStatus.offline);
    });

    test(
      'returns empty when overview has no agent rows and no previous options',
      () {
        final overview = _minimalOverview();
        final out = OverviewAvailableAgentsAssembler.assemble(
          overview: overview,
          previousOptions: const [],
          onlineAgentIds: {},
        );
        expect(out, isEmpty);
      },
    );

    test('previous names carry over when overview adds new ids', () {
      final previous = [
        const OverviewAgentOption(agentId: 'x', name: 'Old X'),
      ];
      final overview = _minimalOverview(
        rankings: const [
          OverviewAgentRanking(
            agentId: 'y',
            displayName: 'Y',
            totalAmount: 1,
            totalSalesCount: 1,
          ),
        ],
      );
      final out = OverviewAvailableAgentsAssembler.assemble(
        overview: overview,
        previousOptions: previous,
        onlineAgentIds: {},
      );
      expect(out.length, 2);
      final byId = {for (final o in out) o.agentId: o};
      expect(byId['x']!.name, 'Old X');
      expect(byId['y']!.name, 'Y');
    });

    test(
      'failure metadata overwrites ranking display name for same agent id',
      () {
        final overview = _minimalOverview(
          rankings: const [
            OverviewAgentRanking(
              agentId: 'x',
              displayName: 'FromRanking',
              totalAmount: 1,
              totalSalesCount: 1,
            ),
          ],
          failedIds: ['x'],
          failedNames: ['FromFailure'],
        );
        final out = OverviewAvailableAgentsAssembler.assemble(
          overview: overview,
          previousOptions: const [],
          onlineAgentIds: {},
        );
        expect(out.length, 1);
        expect(out.single.name, 'FromFailure');
      },
    );

    test(
      'missing token metadata overwrites failure name for same agent id',
      () {
        final overview = _minimalOverview(
          failedIds: ['x'],
          failedNames: ['FromFailure'],
          missingTokenIds: ['x'],
          missingTokenNames: ['FromMissingToken'],
        );
        final out = OverviewAvailableAgentsAssembler.assemble(
          overview: overview,
          previousOptions: const [],
          onlineAgentIds: {},
        );
        expect(out.length, 1);
        expect(out.single.name, 'FromMissingToken');
      },
    );

    test('sorts by display name', () {
      final overview = _minimalOverview(
        rankings: const [
          OverviewAgentRanking(
            agentId: 'b',
            displayName: 'B',
            totalAmount: 1,
            totalSalesCount: 1,
          ),
          OverviewAgentRanking(
            agentId: 'a',
            displayName: 'A',
            totalAmount: 1,
            totalSalesCount: 1,
          ),
        ],
      );
      final out = OverviewAvailableAgentsAssembler.assemble(
        overview: overview,
        previousOptions: const [],
        onlineAgentIds: {},
      );
      expect(out.map((e) => e.agentId).toList(), <String>['a', 'b']);
    });
  });
}
