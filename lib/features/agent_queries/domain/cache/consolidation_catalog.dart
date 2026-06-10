import 'package:colmeia/features/agent_queries/domain/cache/agent_query_fact_kind.dart';
import 'package:colmeia/features/agent_queries/domain/cache/consolidation_storage_mode.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';

/// Registry of which queries may persist which fact kinds.
abstract final class ConsolidationCatalog {
  static ConsolidationStorageMode storageModeFor(AgentQueryFactKind kind) {
    return _entries[kind]?.storageMode ?? ConsolidationStorageMode.derivedOnly;
  }

  static AgentQueryKey? canonicalWriterFor(AgentQueryFactKind kind) {
    return _entries[kind]?.canonicalWriter;
  }

  static bool mayPersist({
    required AgentQueryFactKind factKind,
    required AgentQueryKey writer,
  }) {
    final entry = _entries[factKind];
    if (entry == null) {
      return false;
    }
    if (entry.storageMode == ConsolidationStorageMode.derivedOnly) {
      return false;
    }
    return entry.canonicalWriter == writer;
  }

  static final Map<AgentQueryFactKind, _CatalogEntry> _entries =
      <AgentQueryFactKind, _CatalogEntry>{
        AgentQueryFactKind.dailySales: const _CatalogEntry(
          storageMode: ConsolidationStorageMode.persistClosedBuckets,
          canonicalWriter: AgentQueryKey.resumoTotalDiarioVendas,
        ),
        AgentQueryFactKind.branchMunicipalityPeriodSales: const _CatalogEntry(
          storageMode: ConsolidationStorageMode.persistClosedBuckets,
          canonicalWriter:
              AgentQueryKey.resumoTotalVendasMunicipioFilialPeriodo,
        ),
        AgentQueryFactKind.monthlyParcels: const _CatalogEntry(
          storageMode: ConsolidationStorageMode.persistClosedBuckets,
          canonicalWriter: AgentQueryKey.resumoParcelasMensal,
        ),
        AgentQueryFactKind.weekdayPeriod: const _CatalogEntry(
          storageMode: ConsolidationStorageMode.persistClosedBuckets,
          canonicalWriter: AgentQueryKey.resumoParcelasDiaSemana,
        ),
        AgentQueryFactKind.weekdayUserPeriod: const _CatalogEntry(
          storageMode: ConsolidationStorageMode.derivedOnly,
        ),
        AgentQueryFactKind.lucratividadePeriod: const _CatalogEntry(
          storageMode: ConsolidationStorageMode.persistClosedBuckets,
          canonicalWriter: AgentQueryKey.resumoProdutoVendaLucratividade,
        ),
      };
}

final class _CatalogEntry {
  const _CatalogEntry({
    required this.storageMode,
    this.canonicalWriter,
  });

  final ConsolidationStorageMode storageMode;
  final AgentQueryKey? canonicalWriter;
}
