import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_agent_names_list_sheet.dart';

/// Memoized projection of overview agent-name lists for the home alerts.
///
/// The home page renders four banners that each need a normalized (trimmed,
/// deduped, sorted) list of agent display names. Keeping the cache on a
/// dedicated object — instead of inline in the controller — keeps the
/// controller focused on load orchestration (SRP) and makes the projection
/// trivially unit-testable.
class OverviewAgentAlertNamesProjection {
  Overview? _source;
  bool _isCached = false;
  List<String> _missingToken = const <String>[];
  List<String> _partialFailure = const <String>[];
  List<String> _skippedDueToHubPresence = const <String>[];

  /// Combined display names of agents whose `client_token` is missing
  /// on this device.
  List<String> get missingClientToken {
    _ensureCache();
    return _missingToken;
  }

  /// Combined display names of agents whose query failed mid-flight
  /// (resumo failure or lucratividade partial failure).
  List<String> get partialQueryFailure {
    _ensureCache();
    return _partialFailure;
  }

  /// Display names of agents that have a stored token but were skipped
  /// because the hub-presence policy marked them as offline at dispatch.
  List<String> get skippedDueToHubPresence {
    _ensureCache();
    return _skippedDueToHubPresence;
  }

  /// Swaps the projected overview. Subsequent reads recompute lazily.
  void update(Overview? overview) {
    if (identical(_source, overview)) {
      return;
    }
    _source = overview;
    _isCached = false;
    _missingToken = const <String>[];
    _partialFailure = const <String>[];
    _skippedDueToHubPresence = const <String>[];
  }

  void _ensureCache() {
    if (_isCached) {
      return;
    }
    final overview = _source;
    _isCached = true;
    if (overview == null) {
      return;
    }
    _missingToken = normalizeOverviewAgentNames(
      overview.agentNamesMissingClientToken,
    );
    _partialFailure = normalizeOverviewAgentNames(<String>[
      ...overview.agentNamesExcludedFromQueryFailure,
      ...overview.lucratividadePartialFailureAgentNames,
    ]);
    _skippedDueToHubPresence = normalizeOverviewAgentNames(
      overview.agentNamesSkippedDueToHubPresence,
    );
  }
}
