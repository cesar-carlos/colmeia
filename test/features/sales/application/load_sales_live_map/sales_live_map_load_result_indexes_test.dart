import 'package:colmeia/features/sales/application/load_sales_live_map_use_case.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_branch_ref.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SalesLiveMapLoadResult.agentIdsByBranchRef', () {
    test('maps every branch ref to its owning agent id', () {
      final result = _buildResult(const <SalesLiveMapBranchOption>[
        SalesLiveMapBranchOption(
          id: 'agent-a-1-1',
          agentId: 'agent-a',
          agentName: 'A',
          codEmpresa: 1,
          codFilial: 1,
          registrationName: 'Loja A',
          city: 'Cuiaba',
          uf: 'MT',
        ),
        SalesLiveMapBranchOption(
          id: 'agent-b-1-2',
          agentId: 'agent-b',
          agentName: 'B',
          codEmpresa: 1,
          codFilial: 2,
          registrationName: 'Loja B',
          city: 'Sinop',
          uf: 'MT',
        ),
      ]);

      final index = result.agentIdsByBranchRef;
      expect(
        index[const SalesLiveMapBranchRef(
          agentId: 'agent-a',
          codEmpresa: 1,
          codFilial: 1,
        )],
        'agent-a',
      );
      expect(
        index[const SalesLiveMapBranchRef(
          agentId: 'agent-b',
          codEmpresa: 1,
          codFilial: 2,
        )],
        'agent-b',
      );
      expect(index, hasLength(2));
    });

    test('returns the same instance across repeated reads (memoized)', () {
      final result = _buildResult(const <SalesLiveMapBranchOption>[
        SalesLiveMapBranchOption(
          id: 'agent-a-1-1',
          agentId: 'agent-a',
          agentName: 'A',
          codEmpresa: 1,
          codFilial: 1,
          registrationName: 'Loja A',
          city: 'Cuiaba',
          uf: 'MT',
        ),
      ]);

      final first = result.agentIdsByBranchRef;
      final second = result.agentIdsByBranchRef;
      expect(identical(first, second), isTrue);
    });

    test('exposes an unmodifiable map', () {
      final result = _buildResult(const <SalesLiveMapBranchOption>[
        SalesLiveMapBranchOption(
          id: 'agent-a-1-1',
          agentId: 'agent-a',
          agentName: 'A',
          codEmpresa: 1,
          codFilial: 1,
          registrationName: 'Loja A',
          city: 'Cuiaba',
          uf: 'MT',
        ),
      ]);

      final index = result.agentIdsByBranchRef;
      expect(
        () => index[const SalesLiveMapBranchRef(
          agentId: 'agent-x',
          codEmpresa: 1,
          codFilial: 1,
        )] = 'agent-x',
        throwsUnsupportedError,
      );
    });

    test('empty branch options yields an empty index', () {
      final result = _buildResult(const <SalesLiveMapBranchOption>[]);
      expect(result.agentIdsByBranchRef, isEmpty);
    });
  });
}

SalesLiveMapLoadResult _buildResult(
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
