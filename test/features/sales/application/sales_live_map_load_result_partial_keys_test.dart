import 'package:colmeia/features/sales/application/load_sales_live_map_use_case.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_point.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('partialIssueActiveKeys is empty when hasPartialIssue is false', () {
    final result = _baseResult();
    expect(result.hasPartialIssue, isFalse);
    expect(result.partialIssueActiveKeys, isEmpty);
  });

  test('partialIssueActiveKeys includes mappedBranchCountBelowTotal', () {
    final result = _baseResult(totalBranchCount: 3);
    expect(result.hasPartialIssue, isTrue);
    expect(
      result.partialIssueActiveKeys,
      contains('mappedBranchCountBelowTotal'),
    );
    expect(
      result.partialIssueFlagBreakdown['mappedBranchCountBelowTotal'],
      isTrue,
    );
  });

  test('partialIssueActiveKeys includes unmappedBranchOptions', () {
    final result = _baseResult(
      unmappedBranchOptions: const <SalesLiveMapBranchOption>[
        SalesLiveMapBranchOption(
          id: 'x',
          agentId: 'a',
          agentName: 'A',
          codEmpresa: 1,
          codFilial: 9,
          registrationName: 'Branch',
          city: 'C',
          uf: 'MT',
        ),
      ],
    );
    expect(result.hasPartialIssue, isTrue);
    expect(result.partialIssueActiveKeys, contains('unmappedBranchOptions'));
  });
}

SalesLiveMapLoadResult _baseResult({
  int totalBranchCount = 1,
  int mappedBranchCount = 1,
  List<SalesLiveMapBranchOption> unmappedBranchOptions =
      const <SalesLiveMapBranchOption>[],
}) {
  return SalesLiveMapLoadResult(
    points: const <SalesLiveMapPoint>[
      SalesLiveMapPoint(
        id: 'agent-1-1-1',
        name: 'Branch One',
        uf: 'MT',
        latitude: -15.60,
        longitude: -56.10,
        salesAmount: 100,
        salesCount: 2,
        city: 'Cuiaba',
      ),
    ],
    branchOptions: const <SalesLiveMapBranchOption>[
      SalesLiveMapBranchOption(
        id: 'agent-1-1-1',
        agentId: 'agent-1',
        agentName: 'Agent One',
        codEmpresa: 1,
        codFilial: 1,
        registrationName: 'Branch One',
        city: 'Cuiaba',
        uf: 'MT',
      ),
    ],
    unmappedBranchOptions: unmappedBranchOptions,
    totalRevenue: 100,
    totalSalesCount: 2,
    totalBranchCount: totalBranchCount,
    mappedBranchCount: mappedBranchCount,
    mappedMunicipalityCount: 1,
    queriedAgentCount: 1,
    plannedAgentCount: 1,
    failedAgentCount: 0,
    missingClientTokenAgentCount: 0,
    skippedOfflineAgentCount: 0,
    rowCapReachedAgentCount: 0,
    refreshedAt: DateTime(2026, 5, 9, 12),
  );
}
