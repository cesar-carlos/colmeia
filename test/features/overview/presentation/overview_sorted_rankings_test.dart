import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_ranking.dart';
import 'package:colmeia/features/overview/domain/entities/overview_user_ranking.dart';
import 'package:colmeia/features/overview/presentation/overview_sorted_rankings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OverviewSortedRankings.from', () {
    test('returns empty lists when the overview has no rankings', () {
      final sorted = OverviewSortedRankings.from(Overview.empty());

      expect(sorted.agents, isEmpty);
      expect(sorted.users, isEmpty);
    });

    test('sorts agents by totalAmount descending', () {
      final overview = _overviewWith(
        agents: const <OverviewAgentRanking>[
          OverviewAgentRanking(
            agentId: 'a',
            displayName: 'Alpha',
            totalSalesCount: 1,
            totalAmount: 100,
          ),
          OverviewAgentRanking(
            agentId: 'c',
            displayName: 'Charlie',
            totalSalesCount: 1,
            totalAmount: 300,
          ),
          OverviewAgentRanking(
            agentId: 'b',
            displayName: 'Bravo',
            totalSalesCount: 1,
            totalAmount: 200,
          ),
        ],
      );

      final sorted = OverviewSortedRankings.from(overview);

      expect(
        sorted.agents.map((a) => a.agentId).toList(),
        <String>['c', 'b', 'a'],
      );
    });

    test('drops agents with totalAmount == 0 and negative values', () {
      final overview = _overviewWith(
        agents: const <OverviewAgentRanking>[
          OverviewAgentRanking(
            agentId: 'a',
            displayName: 'Alpha',
            totalSalesCount: 1,
            totalAmount: 100,
          ),
          OverviewAgentRanking(
            agentId: 'b',
            displayName: 'Bravo',
            totalSalesCount: 0,
            totalAmount: 0,
          ),
          OverviewAgentRanking(
            agentId: 'c',
            displayName: 'Charlie',
            totalSalesCount: 1,
            totalAmount: -50,
          ),
        ],
      );

      final sorted = OverviewSortedRankings.from(overview);

      expect(sorted.agents.map((a) => a.agentId).toList(), <String>['a']);
    });

    test('sorts users by totalAmount descending and drops zero-amount rows',
        () {
      final overview = _overviewWith(
        users: const <OverviewUserRanking>[
          OverviewUserRanking(
            userName: 'low',
            totalSalesCount: 1,
            totalAmount: 50,
            averageTicket: 50,
          ),
          OverviewUserRanking(
            userName: 'zero',
            totalSalesCount: 0,
            totalAmount: 0,
            averageTicket: 0,
          ),
          OverviewUserRanking(
            userName: 'high',
            totalSalesCount: 1,
            totalAmount: 500,
            averageTicket: 500,
          ),
        ],
      );

      final sorted = OverviewSortedRankings.from(overview);

      expect(
        sorted.users.map((u) => u.userName).toList(),
        <String>['high', 'low'],
      );
    });

    test('does not mutate the original lists', () {
      final originalAgents = <OverviewAgentRanking>[
        const OverviewAgentRanking(
          agentId: 'a',
          displayName: 'Alpha',
          totalSalesCount: 1,
          totalAmount: 100,
        ),
        const OverviewAgentRanking(
          agentId: 'b',
          displayName: 'Bravo',
          totalSalesCount: 1,
          totalAmount: 300,
        ),
      ];
      final overview = _overviewWith(agents: originalAgents);

      OverviewSortedRankings.from(overview);

      expect(originalAgents.first.agentId, 'a');
      expect(originalAgents.last.agentId, 'b');
    });
  });

  group('OverviewSortedRankings.empty', () {
    test('exposes shared, growable=false lists', () {
      expect(OverviewSortedRankings.empty.agents, isEmpty);
      expect(OverviewSortedRankings.empty.users, isEmpty);
      expect(
        identical(
          OverviewSortedRankings.empty,
          OverviewSortedRankings.empty,
        ),
        isTrue,
      );
    });
  });

  group('OverviewSortedRankingsCache', () {
    test('resolves once and reuses the same instance for the same overview',
        () {
      final overview = _overviewWith(
        agents: const <OverviewAgentRanking>[
          OverviewAgentRanking(
            agentId: 'a',
            displayName: 'Alpha',
            totalSalesCount: 1,
            totalAmount: 100,
          ),
        ],
      );
      final cache = OverviewSortedRankingsCache();

      final first = cache.resolve(overview);
      final second = cache.resolve(overview);

      expect(identical(first, second), isTrue);
    });

    test('recomputes when a different overview instance is passed', () {
      final overviewA = _overviewWith(
        agents: const <OverviewAgentRanking>[
          OverviewAgentRanking(
            agentId: 'a',
            displayName: 'A',
            totalSalesCount: 1,
            totalAmount: 100,
          ),
        ],
      );
      final overviewB = _overviewWith(
        agents: const <OverviewAgentRanking>[
          OverviewAgentRanking(
            agentId: 'b',
            displayName: 'B',
            totalSalesCount: 1,
            totalAmount: 200,
          ),
        ],
      );
      final cache = OverviewSortedRankingsCache();

      final first = cache.resolve(overviewA);
      final second = cache.resolve(overviewB);

      expect(identical(first, second), isFalse);
      expect(first.agents.single.agentId, 'a');
      expect(second.agents.single.agentId, 'b');
    });

    test('invalidate forces recomputation on the next resolve', () {
      final overview = _overviewWith(
        agents: const <OverviewAgentRanking>[
          OverviewAgentRanking(
            agentId: 'a',
            displayName: 'A',
            totalSalesCount: 1,
            totalAmount: 100,
          ),
        ],
      );
      final cache = OverviewSortedRankingsCache()
        ..resolve(overview)
        ..invalidate();

      final after = cache.resolve(overview);

      expect(after.agents.single.agentId, 'a');
    });
  });
}

Overview _overviewWith({
  List<OverviewAgentRanking> agents = const <OverviewAgentRanking>[],
  List<OverviewUserRanking> users = const <OverviewUserRanking>[],
}) {
  final base = Overview.empty();
  return base.copyWith(agentRankings: agents, userRankings: users);
}
