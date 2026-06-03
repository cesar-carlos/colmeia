import 'dart:async';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/agent_queries/data/cache/strategies/resumo_total_diario_vendas_cache_strategy.dart';
import 'package:colmeia/features/agent_queries/data/repositories/caching/caching_resumo_total_diario_vendas_repository_impl.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_load_policy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/resumo_total_diario_vendas_row.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/resumo_total_diario_vendas_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:result_dart/result_dart.dart';

import '../../facts/memory_agent_query_facts_store.dart';

void main() {
  const strategy = ResumoTotalDiarioVendasCacheStrategy();
  final clock = DateTime(2026, 6, 3);

  group('CachingResumoTotalDiarioVendasRepositoryImpl', () {
    late _FakeDelegate fakeDelegate;
    late CachingResumoTotalDiarioVendasRepositoryImpl cachingRepo;

    setUp(() {
      fakeDelegate = _FakeDelegate();
      cachingRepo = CachingResumoTotalDiarioVendasRepositoryImpl(
        delegate: fakeDelegate,
        factsStore: memoryAgentQueryFactsStore(),
        clock: () => clock,
      );
    });

    test('defaultLoad reads closed bucket from store without delegate', () async {
      final filter = ResumoTotalDiarioVendasFilter(
        dataVendaInicio: DateTime(2026, 6),
        dataVendaFim: DateTime(2026, 6, 1, 23, 59, 59, 999, 999),
      );
      final row = ResumoTotalDiarioVendasRow(
        codEmpresa: 1,
        codFilial: 1,
        dataVenda: DateTime(2026, 6),
        qtdVendas: 2,
        valorTotalDiarioVenda: 10,
      );
      final storageKey = strategy.storageKey(
        userId: 'u1',
        agentId: 'a1',
        bucketId: '2026-06-01',
        rangeFilter: filter,
      );
      await cachingRepo.factsStore.writePayload(
        storageKey: storageKey,
        payload: strategy.encodePayload([row]),
        schemaVersion: strategy.schemaVersion,
      );

      final result = await cachingRepo.load(
        userId: 'u1',
        agentId: 'a1',
        filter: filter,
      );

      final loaded = result.getOrNull();
      expect(loaded, isNotNull);
      expect(loaded!.single.qtdVendas, row.qtdVendas);
      expect(fakeDelegate.loadCount, 0);
    });

    test('forceRefresh calls delegate even when store has data', () async {
      final filter = ResumoTotalDiarioVendasFilter(
        dataVendaInicio: DateTime(2026, 6),
        dataVendaFim: DateTime(2026, 6, 1, 23, 59, 59, 999, 999),
      );
      final row = ResumoTotalDiarioVendasRow(
        codEmpresa: 1,
        codFilial: 1,
        dataVenda: DateTime(2026, 6),
        qtdVendas: 1,
        valorTotalDiarioVenda: 5,
      );
      fakeDelegate.rows = [row];
      final storageKey = strategy.storageKey(
        userId: 'u1',
        agentId: 'a1',
        bucketId: '2026-06-01',
        rangeFilter: filter,
      );
      await cachingRepo.factsStore.writePayload(
        storageKey: storageKey,
        payload: strategy.encodePayload([
          ResumoTotalDiarioVendasRow(
            codEmpresa: 1,
            codFilial: 1,
            dataVenda: DateTime(2026, 6),
            qtdVendas: 99,
            valorTotalDiarioVenda: 99,
          ),
        ]),
        schemaVersion: strategy.schemaVersion,
      );

      final result = await cachingRepo.load(
        userId: 'u1',
        agentId: 'a1',
        filter: filter,
        cachePolicy: AgentQueryLoadPolicy.forceRefresh,
      );

      expect(result.getOrNull(), [row]);
      expect(fakeDelegate.loadCount, greaterThan(0));
    });

    test('networkOnly never reads store and always calls delegate', () async {
      final filter = ResumoTotalDiarioVendasFilter(
        dataVendaInicio: DateTime(2026, 6),
        dataVendaFim: DateTime(2026, 6, 1, 23, 59, 59, 999, 999),
      );
      final storageKey = strategy.storageKey(
        userId: 'u1',
        agentId: 'a1',
        bucketId: '2026-06-01',
        rangeFilter: filter,
      );
      await cachingRepo.factsStore.writePayload(
        storageKey: storageKey,
        payload: strategy.encodePayload([
          ResumoTotalDiarioVendasRow(
            codEmpresa: 1,
            codFilial: 1,
            dataVenda: DateTime(2026, 6),
            qtdVendas: 99,
            valorTotalDiarioVenda: 99,
          ),
        ]),
        schemaVersion: strategy.schemaVersion,
      );
      fakeDelegate.rows = [
        ResumoTotalDiarioVendasRow(
          codEmpresa: 1,
          codFilial: 1,
          dataVenda: DateTime(2026, 6),
          qtdVendas: 1,
          valorTotalDiarioVenda: 1,
        ),
      ];

      final result = await cachingRepo.load(
        userId: 'u1',
        agentId: 'a1',
        filter: filter,
        cachePolicy: AgentQueryLoadPolicy.networkOnly,
      );

      expect(result.getOrNull()?.single.qtdVendas, 1);
      expect(fakeDelegate.loadCount, greaterThan(0));
    });

    test(
      'defaultLoad without batch support fetches network buckets via delegate',
      () async {
        final gateDelegate = _GateDelegate();
        cachingRepo = CachingResumoTotalDiarioVendasRepositoryImpl(
          delegate: gateDelegate,
          factsStore: memoryAgentQueryFactsStore(),
          clock: () => clock,
          useExecuteBatchForBuckets: false,
          bucketLoadConcurrency: 3,
        );

        final filter = ResumoTotalDiarioVendasFilter(
          dataVendaInicio: DateTime(2026, 6, 3),
          dataVendaFim: DateTime(2026, 6, 5, 23, 59, 59, 999, 999),
        );

        final loadFuture = cachingRepo.load(
          userId: 'u1',
          agentId: 'a1',
          filter: filter,
        );

        await gateDelegate.waitUntilInFlight(atLeast: 2);
        expect(gateDelegate.peakConcurrent, greaterThanOrEqualTo(2));

        gateDelegate.releaseAll();
        await loadFuture;

        expect(gateDelegate.loadCount, 3);
      },
    );

    test('forceRefresh merges bucket rows in plan order', () async {
      cachingRepo = CachingResumoTotalDiarioVendasRepositoryImpl(
        delegate: _PerDayDelegate(),
        factsStore: memoryAgentQueryFactsStore(),
        clock: () => clock,
      );

      final filter = ResumoTotalDiarioVendasFilter(
        dataVendaInicio: DateTime(2026, 6),
        dataVendaFim: DateTime(2026, 6, 3, 23, 59, 59, 999, 999),
      );

      final result = await cachingRepo.load(
        userId: 'u1',
        agentId: 'a1',
        filter: filter,
        cachePolicy: AgentQueryLoadPolicy.forceRefresh,
      );

      expect(
        result.getOrNull()?.map((row) => row.qtdVendas).toList(),
        <int>[1, 2, 3],
      );
    });

    test('returns first bucket failure in plan order', () async {
      cachingRepo = CachingResumoTotalDiarioVendasRepositoryImpl(
        delegate: _FailingDelegate(failOnDay: DateTime(2026, 6, 2)),
        factsStore: memoryAgentQueryFactsStore(),
        clock: () => clock,
      );

      final filter = ResumoTotalDiarioVendasFilter(
        dataVendaInicio: DateTime(2026, 6),
        dataVendaFim: DateTime(2026, 6, 3, 23, 59, 59, 999, 999),
      );

      final result = await cachingRepo.load(
        userId: 'u1',
        agentId: 'a1',
        filter: filter,
        cachePolicy: AgentQueryLoadPolicy.forceRefresh,
      );

      expect(result.isError(), isTrue);
      expect(result.exceptionOrNull()?.message, 'bucket-2026-06-02');
    });
  });
}

final class _FakeDelegate implements ResumoTotalDiarioVendasRepository {
  int loadCount = 0;
  List<ResumoTotalDiarioVendasRow> rows = const <ResumoTotalDiarioVendasRow>[];

  @override
  Future<AppResult<List<ResumoTotalDiarioVendasRow>>> load({
    required String userId,
    required String agentId,
    required ResumoTotalDiarioVendasFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
    AgentQueryLoadPolicy cachePolicy = AgentQueryLoadPolicy.defaultLoad,
  }) async {
    loadCount++;
    return Success<List<ResumoTotalDiarioVendasRow>, AppFailure>(rows);
  }
}

/// Holds each delegate [load] until [releaseAll] so tests can observe overlap.
final class _GateDelegate implements ResumoTotalDiarioVendasRepository {
  int loadCount = 0;
  int peakConcurrent = 0;
  int _inFlight = 0;
  final List<Completer<void>> _pending = <Completer<void>>[];
  final _inFlightReached = Completer<void>();

  Future<void> waitUntilInFlight({required int atLeast}) async {
    while (_inFlight < atLeast) {
      if (_inFlightReached.isCompleted) {
        break;
      }
      await Future<void>.delayed(Duration.zero);
    }
    if (_inFlight < atLeast && !_inFlightReached.isCompleted) {
      await _inFlightReached.future.timeout(
        const Duration(seconds: 2),
        onTimeout: () {},
      );
    }
  }

  void releaseAll() {
    for (final pending in _pending) {
      if (!pending.isCompleted) {
        pending.complete();
      }
    }
    _pending.clear();
  }

  @override
  Future<AppResult<List<ResumoTotalDiarioVendasRow>>> load({
    required String userId,
    required String agentId,
    required ResumoTotalDiarioVendasFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
    AgentQueryLoadPolicy cachePolicy = AgentQueryLoadPolicy.defaultLoad,
  }) async {
    loadCount++;
    _inFlight++;
    if (_inFlight > peakConcurrent) {
      peakConcurrent = _inFlight;
    }
    if (_inFlight >= 2 && !_inFlightReached.isCompleted) {
      _inFlightReached.complete();
    }

    final release = Completer<void>();
    _pending.add(release);
    await release.future;

    _inFlight--;
    return Success<List<ResumoTotalDiarioVendasRow>, AppFailure>(
      <ResumoTotalDiarioVendasRow>[
        ResumoTotalDiarioVendasRow(
          codEmpresa: 1,
          codFilial: 1,
          dataVenda: filter.dataVendaInicio,
          qtdVendas: 1,
          valorTotalDiarioVenda: 1,
        ),
      ],
    );
  }
}

final class _PerDayDelegate implements ResumoTotalDiarioVendasRepository {
  @override
  Future<AppResult<List<ResumoTotalDiarioVendasRow>>> load({
    required String userId,
    required String agentId,
    required ResumoTotalDiarioVendasFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
    AgentQueryLoadPolicy cachePolicy = AgentQueryLoadPolicy.defaultLoad,
  }) async {
    final day = filter.dataVendaInicio.day;
    return Success<List<ResumoTotalDiarioVendasRow>, AppFailure>(
      <ResumoTotalDiarioVendasRow>[
        ResumoTotalDiarioVendasRow(
          codEmpresa: 1,
          codFilial: 1,
          dataVenda: filter.dataVendaInicio,
          qtdVendas: day,
          valorTotalDiarioVenda: day.toDouble(),
        ),
      ],
    );
  }
}

final class _FailingDelegate implements ResumoTotalDiarioVendasRepository {
  _FailingDelegate({required this.failOnDay});

  final DateTime failOnDay;

  @override
  Future<AppResult<List<ResumoTotalDiarioVendasRow>>> load({
    required String userId,
    required String agentId,
    required ResumoTotalDiarioVendasFilter filter,
    String? clientToken,
    int? bridgeTimeoutMs,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    AgentQueriesCancelScope? cancelScope,
    AgentQueryLoadPolicy cachePolicy = AgentQueryLoadPolicy.defaultLoad,
  }) async {
    final day = DateTime(
      filter.dataVendaInicio.year,
      filter.dataVendaInicio.month,
      filter.dataVendaInicio.day,
    );
    if (day == failOnDay) {
      return Failure<List<ResumoTotalDiarioVendasRow>, AppFailure>(
        ValidationFailure(
          message:
              'bucket-${failOnDay.year}-${failOnDay.month.toString().padLeft(2, '0')}-${failOnDay.day.toString().padLeft(2, '0')}',
        ),
      );
    }
    return Success<List<ResumoTotalDiarioVendasRow>, AppFailure>(
      <ResumoTotalDiarioVendasRow>[
        ResumoTotalDiarioVendasRow(
          codEmpresa: 1,
          codFilial: 1,
          dataVenda: filter.dataVendaInicio,
          qtdVendas: day.day,
          valorTotalDiarioVenda: day.day.toDouble(),
        ),
      ],
    );
  }
}
