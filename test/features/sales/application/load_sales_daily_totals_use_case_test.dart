import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/application/usecases/load_resumo_total_diario_vendas_use_case.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_row.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/features/sales/application/load_sales_daily_totals_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockLoadResumoTotalDiarioVendasUseCase extends Mock
    implements LoadResumoTotalDiarioVendasUseCase {}

void main() {
  late _MockLoadResumoTotalDiarioVendasUseCase dependency;
  late LoadSalesDailyTotalsUseCase useCase;

  setUpAll(() {
    registerFallbackValue(
      ResumoTotalDiarioVendasFilter(
        dataVendaInicio: DateTime.utc(2026),
        dataVendaFim: DateTime.utc(2026, 5, 31),
      ),
    );
  });

  setUp(() {
    dependency = _MockLoadResumoTotalDiarioVendasUseCase();
    useCase = LoadSalesDailyTotalsUseCase(dependency);
  });

  test('without dailySaleDateRange uses calendar month from anchor', () async {
    ResumoTotalDiarioVendasFilter? captured;
    when(
      () => dependency(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        filter: any(named: 'filter'),
        clientToken: any(named: 'clientToken'),
        bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
        hubPresenceOnlineAgentIdsSnapshot: any(
          named: 'hubPresenceOnlineAgentIdsSnapshot',
        ),
        hubConnectedFromApprovedCatalogRow: any(
          named: 'hubConnectedFromApprovedCatalogRow',
        ),
      ),
    ).thenAnswer((invocation) async {
      captured =
          invocation.namedArguments[#filter] as ResumoTotalDiarioVendasFilter;
      return const Success<List<ResumoTotalDiarioVendasRow>, AppFailure>(
        <ResumoTotalDiarioVendasRow>[],
      );
    });

    final anchor = OverviewYearMonth(year: 2026, month: 5);
    final result = await useCase(
      userId: 'u',
      agentId: 'a',
      anchor: anchor,
    );

    expect(result.loadFailed, isFalse);
    expect(result.points.length, 31);
    expect(captured, isNotNull);
    expect(captured!.dataVendaInicio, DateTime(2026, 5));
    expect(captured!.dataVendaFim, DateTime(2026, 6, 0));
  });

  test('with dailySaleDateRange uses inclusive endpoints', () async {
    ResumoTotalDiarioVendasFilter? captured;
    when(
      () => dependency(
        userId: any(named: 'userId'),
        agentId: any(named: 'agentId'),
        filter: any(named: 'filter'),
        clientToken: any(named: 'clientToken'),
        bridgeTimeoutMs: any(named: 'bridgeTimeoutMs'),
        hubPresenceOnlineAgentIdsSnapshot: any(
          named: 'hubPresenceOnlineAgentIdsSnapshot',
        ),
        hubConnectedFromApprovedCatalogRow: any(
          named: 'hubConnectedFromApprovedCatalogRow',
        ),
      ),
    ).thenAnswer((invocation) async {
      captured =
          invocation.namedArguments[#filter] as ResumoTotalDiarioVendasFilter;
      return const Success<List<ResumoTotalDiarioVendasRow>, AppFailure>(
        <ResumoTotalDiarioVendasRow>[],
      );
    });

    final range = OverviewDateRange.fromOrderedEndpoints(
      DateTime(2026, 5, 2),
      DateTime(2026, 5, 8),
    );
    final result = await useCase(
      userId: 'u',
      agentId: 'a',
      anchor: OverviewYearMonth(year: 2026, month: 1),
      dailySaleDateRange: range,
    );

    expect(result.loadFailed, isFalse);
    expect(result.points.length, 7);
    expect(captured!.dataVendaInicio, DateTime(2026, 5, 2));
    expect(captured!.dataVendaFim, DateTime(2026, 5, 8));
  });
}
