import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_ranking.dart';
import 'package:colmeia/features/overview/domain/entities/overview_user_ranking.dart';

/// Memoized view of the overview rankings used by the home screen: positive
/// totals only, sorted by `totalAmount` descending. Built from a single
/// `Overview` instance so callers that already have a reference to it can share
/// the same sort + filter pass instead of re-implementing it per widget.
class OverviewSortedRankings {
  OverviewSortedRankings._({
    required this.agents,
    required this.users,
  });

  factory OverviewSortedRankings.from(Overview overview) {
    final agents = <OverviewAgentRanking>[
      for (final a in overview.agentRankings)
        if (a.totalAmount > 0) a,
    ]..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    final users = <OverviewUserRanking>[
      for (final u in overview.userRankings)
        if (u.totalAmount > 0) u,
    ]..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    return OverviewSortedRankings._(agents: agents, users: users);
  }

  static final OverviewSortedRankings empty = OverviewSortedRankings._(
    agents: const <OverviewAgentRanking>[],
    users: const <OverviewUserRanking>[],
  );

  final List<OverviewAgentRanking> agents;
  final List<OverviewUserRanking> users;
}

/// Cache that recomputes only when the source `Overview` identity changes.
/// Designed for `State` classes that already follow the identity-based
/// rebuild pattern used across the overview widgets.
class OverviewSortedRankingsCache {
  Overview? _source;
  OverviewSortedRankings? _value;

  OverviewSortedRankings resolve(Overview overview) {
    if (identical(_source, overview) && _value != null) {
      return _value!;
    }
    _source = overview;
    final next = OverviewSortedRankings.from(overview);
    _value = next;
    return next;
  }

  void invalidate() {
    _source = null;
    _value = null;
  }
}
