import 'dart:convert';

import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/core/cache/app_kv_cache_key_prefixes.dart';
import 'package:colmeia/features/overview/data/datasources/overview_local_datasource.dart';
import 'package:colmeia/features/overview/data/models/overview_model.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_kpis.dart';
import 'package:colmeia/features/overview/domain/entities/overview_payment_method_breakdown.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('readOverview returns null when cache is empty', () async {
    final store = _MemoryCacheStore();
    final ds = OverviewLocalDataSource(
      store,
      maxCacheAge: const Duration(minutes: 30),
    );
    expect(await ds.readOverview(userId: 'u1'), isNull);
  });

  test('readOverview returns fresh v2 envelope', () async {
    final store = _MemoryCacheStore();
    final ds = OverviewLocalDataSource(
      store,
      maxCacheAge: const Duration(hours: 1),
    );
    final model = _minimalOverview();
    await ds.saveOverview(userId: 'u1', overview: model);
    final read = await ds.readOverview(userId: 'u1');
    expect(read, isNotNull);
    expect(read!.kpis.totalSalesCount, model.kpis.totalSalesCount);
  });

  test(
    'readOverview returns null when v2 envelope is older than maxCacheAge',
    () async {
      final store = _MemoryCacheStore();
      final ds = OverviewLocalDataSource(
        store,
        maxCacheAge: const Duration(minutes: 30),
      );
      final model = _minimalOverview();
      final staleSavedAt = DateTime.now().toUtc().subtract(
        const Duration(hours: 2),
      );
      await store.putString(
        key: '${AppKvCacheKeyPrefixes.dashboardOverview}u1_payments',
        value: jsonEncode(<String, Object?>{
          'v': 2,
          'savedAt': staleSavedAt.toIso8601String(),
          'payload': model.encode(),
        }),
      );
      expect(await ds.readOverview(userId: 'u1'), isNull);
    },
  );
}

OverviewModel _minimalOverview() {
  return OverviewModel(
    periodStart: DateTime(2026),
    periodEnd: DateTime(2026, 1, 31),
    kpis: const OverviewPaymentKpis(
      totalSalesCount: 3,
      totalAmount: 30,
      averageTicket: 10,
      paymentMethodCount: 1,
    ),
    paymentMethods: const <OverviewPaymentMethodBreakdown>[
      OverviewPaymentMethodBreakdown(
        code: 'PIX',
        label: 'Pix',
        totalSalesCount: 3,
        totalAmount: 30,
        averageTicket: 10,
        sharePercent: 100,
      ),
    ],
    agentRankings: const [],
    userRankings: const [],
  );
}

final class _MemoryCacheStore implements AppCacheStore {
  final Map<String, String> _entries = <String, String>{};

  @override
  Future<void> clearAll() async {
    _entries.clear();
  }

  @override
  Future<String?> getString(String key) async => _entries[key];

  @override
  Future<void> putString({
    required String key,
    required String value,
  }) async {
    _entries[key] = value;
  }

  @override
  Future<void> removeString(String key) async {
    _entries.remove(key);
  }
}
