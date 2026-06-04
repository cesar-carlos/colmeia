import 'package:colmeia/features/agent_queries/domain/cache/agent_query_fact_kind.dart';
import 'package:colmeia/features/agent_queries/domain/cache/consolidation_catalog.dart';
import 'package:colmeia/features/agent_queries/domain/cache/consolidation_storage_mode.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConsolidationCatalog', () {
    test('daily sales writer may persist', () {
      expect(
        ConsolidationCatalog.mayPersist(
          factKind: AgentQueryFactKind.dailySales,
          writer: AgentQueryKey.resumoTotalDiarioVendas,
        ),
        isTrue,
      );
    });

    test('weekday period persists via resumo parcelas dia semana', () {
      expect(
        ConsolidationCatalog.storageModeFor(AgentQueryFactKind.weekdayPeriod),
        ConsolidationStorageMode.persistClosedBuckets,
      );
      expect(
        ConsolidationCatalog.mayPersist(
          factKind: AgentQueryFactKind.weekdayPeriod,
          writer: AgentQueryKey.resumoParcelasDiaSemana,
        ),
        isTrue,
      );
    });

    test('weekday user period is derived only', () {
      expect(
        ConsolidationCatalog.storageModeFor(AgentQueryFactKind.weekdayUserPeriod),
        ConsolidationStorageMode.derivedOnly,
      );
      expect(
        ConsolidationCatalog.mayPersist(
          factKind: AgentQueryFactKind.weekdayUserPeriod,
          writer: AgentQueryKey.resumoParcelasDiaSemanaUsuario,
        ),
        isFalse,
      );
    });

    test('unknown fact kind defaults to derived only', () {
      expect(
        ConsolidationCatalog.storageModeFor(AgentQueryFactKind.lucratividadeMensal),
        ConsolidationStorageMode.derivedOnly,
      );
    });
  });
}
