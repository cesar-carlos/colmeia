import 'package:colmeia/features/sales/application/load_sales_live_map_use_case.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_branch_ref.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/presentation/controllers/sales_live_map_filter_normalizer.dart';
import 'package:colmeia/shared/filters/dashboard_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeRestoredFilter', () {
    test('returns the filter unchanged when there is no branch selection', () {
      const filter = SalesLiveMapFilter(
        periodMode: SalesLiveMapPeriodMode.lastSevenDays,
      );

      final normalized = SalesLiveMapFilterNormalizer.normalizeRestoredFilter(
        filter,
      );

      expect(identical(normalized, filter), isTrue);
    });

    test('drops branch + agent selection when restoring with branches', () {
      final filter = SalesLiveMapFilter(
        selectedAgentIds: const <String>{'agent-1'},
        selectedBranchIds: <SalesLiveMapBranchRef>{
          const SalesLiveMapBranchRef(
            agentId: 'agent-1',
            codEmpresa: 1,
            codFilial: 1,
          ),
        },
      );

      final normalized = SalesLiveMapFilterNormalizer.normalizeRestoredFilter(
        filter,
      );

      expect(normalized.selectedBranchIds, isNull);
      expect(normalized.selectedAgentIds, isNull);
      // Other fields are preserved.
      expect(normalized.periodMode, filter.periodMode);
    });
  });

  group('normalizeForSelectedBranches', () {
    test('drops selectedAgentIds when no branches are selected', () {
      const filter = SalesLiveMapFilter(
        selectedAgentIds: <String>{'agent-1'},
      );

      final normalized =
          SalesLiveMapFilterNormalizer.normalizeForSelectedBranches(
            filter: filter,
            result: null,
          );

      expect(normalized.selectedAgentIds, isNull);
      expect(normalized.selectedBranchIds, isNull);
    });

    test(
      'returns the filter unchanged when the result has no branch options',
      () {
        final filter = SalesLiveMapFilter(
          selectedBranchIds: <SalesLiveMapBranchRef>{
            const SalesLiveMapBranchRef(
              agentId: 'agent-1',
              codEmpresa: 1,
              codFilial: 1,
            ),
          },
        );

        final normalized =
            SalesLiveMapFilterNormalizer.normalizeForSelectedBranches(
              filter: filter,
              result: null,
            );

        expect(identical(normalized, filter), isTrue);
      },
    );

    test(
      'rewrites selectedAgentIds to the agents owning the selected branches',
      () {
        final result = _resultWithBranches(const <SalesLiveMapBranchOption>[
          SalesLiveMapBranchOption(
            id: 'agent-a-1-1',
            agentId: 'agent-a',
            agentName: 'Agente A',
            codEmpresa: 1,
            codFilial: 1,
            registrationName: 'Loja A',
            city: 'Cuiaba',
            uf: 'MT',
          ),
          SalesLiveMapBranchOption(
            id: 'agent-b-1-1',
            agentId: 'agent-b',
            agentName: 'Agente B',
            codEmpresa: 1,
            codFilial: 1,
            registrationName: 'Loja B',
            city: 'Sinop',
            uf: 'MT',
          ),
        ]);

        final filter = SalesLiveMapFilter(
          selectedAgentIds: const <String>{'agent-a', 'agent-z'},
          selectedBranchIds: <SalesLiveMapBranchRef>{
            const SalesLiveMapBranchRef(
              agentId: 'agent-b',
              codEmpresa: 1,
              codFilial: 1,
            ),
          },
        );

        final normalized =
            SalesLiveMapFilterNormalizer.normalizeForSelectedBranches(
              filter: filter,
              result: result,
            );

        expect(normalized.selectedAgentIds, <String>{'agent-b'});
        expect(normalized.selectedBranchIds, filter.selectedBranchIds);
      },
    );

    test(
      'returns the filter unchanged when none of the selected branches '
      'match the catalog',
      () {
        final result = _resultWithBranches(const <SalesLiveMapBranchOption>[
          SalesLiveMapBranchOption(
            id: 'agent-a-1-1',
            agentId: 'agent-a',
            agentName: 'Agente A',
            codEmpresa: 1,
            codFilial: 1,
            registrationName: 'Loja A',
            city: 'Cuiaba',
            uf: 'MT',
          ),
        ]);

        final filter = SalesLiveMapFilter(
          selectedAgentIds: const <String>{'agent-stale'},
          selectedBranchIds: <SalesLiveMapBranchRef>{
            const SalesLiveMapBranchRef(
              agentId: 'agent-stale',
              codEmpresa: 1,
              codFilial: 1,
            ),
          },
        );

        final normalized =
            SalesLiveMapFilterNormalizer.normalizeForSelectedBranches(
              filter: filter,
              result: result,
            );

        // Stale branch isn't in the catalog -> agent normalization can't
        // run; the filter is returned as-is so the caller can decide.
        expect(identical(normalized, filter), isTrue);
      },
    );
  });

  group('normalizeSelectedAgentIds', () {
    const agentWithToken = DashboardAgentOption(
      agentId: 'agent-1',
      name: 'Agent One',
    );
    const agentMissingToken = DashboardAgentOption(
      agentId: 'agent-2',
      name: 'Agent Two',
      missingLocalClientToken: true,
    );

    test(
      'returns null when every available agent has a token and there '
      'is no explicit selection',
      () {
        final normalized =
            SalesLiveMapFilterNormalizer.normalizeSelectedAgentIds(
              agents: const <DashboardAgentOption>[agentWithToken],
              selectedAgentIds: null,
            );

        expect(normalized, isNull);
      },
    );

    test(
      'returns token-backed subset when some agents lack token and '
      'there is no explicit selection',
      () {
        final normalized =
            SalesLiveMapFilterNormalizer.normalizeSelectedAgentIds(
              agents: const <DashboardAgentOption>[
                agentWithToken,
                agentMissingToken,
              ],
              selectedAgentIds: null,
            );

        expect(normalized, <String>{'agent-1'});
      },
    );

    test('returns null when there are no token-backed agents at all', () {
      final normalized = SalesLiveMapFilterNormalizer.normalizeSelectedAgentIds(
        agents: const <DashboardAgentOption>[agentMissingToken],
        selectedAgentIds: null,
      );

      expect(normalized, isNull);
    });

    test(
      'reconciles an explicit selection by dropping ids that lost their '
      'token (or were removed)',
      () {
        final normalized =
            SalesLiveMapFilterNormalizer.normalizeSelectedAgentIds(
              agents: const <DashboardAgentOption>[
                agentWithToken,
                agentMissingToken,
              ],
              selectedAgentIds: const <String>{'agent-1', 'agent-2', 'agent-x'},
            );

      expect(normalized, <String>{'agent-1'});
      },
    );

    test(
      'falls back to all token-backed agents when the explicit selection '
      'no longer overlaps with any token-backed agent',
      () {
        final normalized =
            SalesLiveMapFilterNormalizer.normalizeSelectedAgentIds(
              agents: const <DashboardAgentOption>[
                agentWithToken,
                agentMissingToken,
              ],
              selectedAgentIds: const <String>{'agent-x'},
            );

      expect(normalized, <String>{'agent-1'});
      },
    );

    test(
      'returns null when an explicit selection covers every token-backed '
      'agent AND every available agent (no real filter)',
      () {
        final normalized =
            SalesLiveMapFilterNormalizer.normalizeSelectedAgentIds(
              agents: const <DashboardAgentOption>[agentWithToken],
              selectedAgentIds: const <String>{'agent-1'},
            );

        expect(normalized, isNull);
      },
    );
  });
}

SalesLiveMapLoadResult _resultWithBranches(
  List<SalesLiveMapBranchOption> branchOptions,
) {
  return SalesLiveMapLoadResult(
    points: const [],
    branchOptions: branchOptions,
    totalRevenue: 0,
    totalSalesCount: 0,
    totalBranchCount: branchOptions.length,
    mappedBranchCount: 0,
    mappedMunicipalityCount: 0,
    queriedAgentCount: 0,
    plannedAgentCount: 0,
    failedAgentCount: 0,
    missingClientTokenAgentCount: 0,
    skippedOfflineAgentCount: 0,
    rowCapReachedAgentCount: 0,
    refreshedAt: DateTime(2026, 5, 27),
  );
}
