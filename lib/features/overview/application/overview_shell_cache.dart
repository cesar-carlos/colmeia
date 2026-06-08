import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/domain/entities/overview_progressive_snapshot.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';

/// Shell-scoped snapshot of the last successful overview for instant re-entry.
class OverviewShellCacheEntry {
  const OverviewShellCacheEntry({
    required this.signature,
    required this.overview,
    required this.activeFilter,
    required this.availableAgents,
    required this.completedSections,
  });

  final String signature;
  final Overview overview;
  final DashboardFilter activeFilter;
  final List<DashboardAgentOption> availableAgents;
  final Set<OverviewProgressiveSection> completedSections;
}

/// Process-lifetime cache keyed by [OverviewShellCacheEntry.signature].
///
/// Route-scoped overview controllers read on mount and publish after
/// successful loads. Invalidated on filter change, explicit refresh, and logout.
class OverviewShellCache {
  OverviewShellCacheEntry? _entry;

  OverviewShellCacheEntry? get latestEntry => _entry;

  OverviewShellCacheEntry? read(String signature) {
    final entry = _entry;
    if (entry != null && entry.signature == signature) {
      return entry;
    }
    return null;
  }

  void publish({
    required String signature,
    required Overview overview,
    required DashboardFilter activeFilter,
    required List<DashboardAgentOption> availableAgents,
    required Set<OverviewProgressiveSection> completedSections,
  }) {
    _entry = OverviewShellCacheEntry(
      signature: signature,
      overview: overview,
      activeFilter: activeFilter,
      availableAgents: List<DashboardAgentOption>.unmodifiable(availableAgents),
      completedSections: Set<OverviewProgressiveSection>.of(completedSections),
    );
  }

  /// Merges a section-only detail load into the existing entry for [signature].
  void mergePublish({
    required String signature,
    required Overview detailOverview,
    required OverviewProgressiveSection section,
    required Set<OverviewProgressiveSection> addedSections,
  }) {
    final existing = read(signature);
    if (existing == null) {
      return;
    }
    _entry = OverviewShellCacheEntry(
      signature: existing.signature,
      overview: existing.overview.mergeSection(detailOverview, section),
      activeFilter: existing.activeFilter,
      availableAgents: existing.availableAgents,
      completedSections: <OverviewProgressiveSection>{
        ...existing.completedSections,
        ...addedSections,
      },
    );
  }

  void invalidate() {
    _entry = null;
  }
}
