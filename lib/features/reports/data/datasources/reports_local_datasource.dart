import 'dart:convert';

import 'package:colmeia/core/cache/app_cache_store.dart';
import 'package:colmeia/core/cache/app_kv_cache_key_prefixes.dart';
import 'package:colmeia/core/value_objects/report_id.dart';
import 'package:colmeia/core/value_objects/store_id.dart';
import 'package:colmeia/features/reports/data/models/report_detail_model.dart';
import 'package:colmeia/features/reports/data/models/reports_overview_model.dart';

class ReportsLocalDataSource {
  ReportsLocalDataSource(this._cacheStore);

  final AppCacheStore _cacheStore;

  Future<ReportsOverviewModel?> readOverview({
    required String userId,
    required StoreId activeStoreId,
  }) async {
    final raw = await _cacheStore.getString(
      _cacheKey(userId, activeStoreId),
    );
    if (raw == null || raw.isEmpty) {
      return null;
    }

    return ReportsOverviewModel.decode(raw);
  }

  Future<void> saveOverview({
    required String userId,
    required StoreId activeStoreId,
    required ReportsOverviewModel overview,
  }) {
    return _cacheStore.putString(
      key: _cacheKey(userId, activeStoreId),
      value: overview.encode(),
    );
  }

  String _cacheKey(String userId, StoreId activeStoreId) {
    return '${AppKvCacheKeyPrefixes.reportsOverview}'
        '${userId}_${activeStoreId.value}';
  }

  Future<ReportDetailModel?> readDetail({
    required String userId,
    required ReportId reportId,
    required StoreId storeId,
    required Map<String, Object?> filters,
    required int page,
    required int pageSize,
  }) async {
    final raw = await _cacheStore.getString(
      _detailCacheKey(
        userId,
        reportId,
        storeId,
        filters: filters,
        page: page,
        pageSize: pageSize,
      ),
    );
    if (raw == null || raw.isEmpty) {
      return null;
    }

    return ReportDetailModel.decode(raw);
  }

  Future<void> saveDetail({
    required String userId,
    required ReportId reportId,
    required StoreId storeId,
    required ReportDetailModel detail,
    required Map<String, Object?> filters,
    required int page,
    required int pageSize,
  }) {
    return _cacheStore.putString(
      key: _detailCacheKey(
        userId,
        reportId,
        storeId,
        filters: filters,
        page: page,
        pageSize: pageSize,
      ),
      value: detail.encode(),
    );
  }

  String _detailCacheKey(
    String userId,
    ReportId reportId,
    StoreId storeId, {
    required Map<String, Object?> filters,
    required int page,
    required int pageSize,
  }) {
    final encodedFilters = jsonEncode(_encodeFilters(filters));
    return '${AppKvCacheKeyPrefixes.reportDetail}'
        '${userId}_${reportId.value}_${storeId.value}_'
        '${page}_$pageSize'
        '_$encodedFilters';
  }

  Future<Map<String, Object?>> readPersistedDetailFilters({
    required String userId,
    required ReportId reportId,
    required StoreId storeId,
  }) async {
    final raw = await _cacheStore.getString(
      _persistedFiltersKey(userId, reportId, storeId),
    );
    if (raw == null || raw.isEmpty) {
      return <String, Object?>{};
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return _decodeFilters(decoded);
  }

  Future<void> savePersistedDetailFilters({
    required String userId,
    required ReportId reportId,
    required StoreId storeId,
    required Map<String, Object?> filters,
  }) {
    return _cacheStore.putString(
      key: _persistedFiltersKey(userId, reportId, storeId),
      value: jsonEncode(_encodeFilters(filters)),
    );
  }

  String _persistedFiltersKey(
    String userId,
    ReportId reportId,
    StoreId storeId,
  ) {
    return '${AppKvCacheKeyPrefixes.reportDetailFilters}'
        '${userId}_${reportId.value}_${storeId.value}';
  }

  Map<String, Object?> _encodeFilters(Map<String, Object?> filters) {
    final sortedEntries = filters.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));

    return Map<String, Object?>.fromEntries(
      sortedEntries.map((entry) {
        return MapEntry<String, Object?>(
          entry.key,
          _encodeFilterValue(entry.value),
        );
      }),
    );
  }

  Map<String, Object?> _decodeFilters(Map<String, dynamic> filters) {
    return filters.map((key, value) {
      return MapEntry<String, Object?>(
        key,
        _decodeFilterValue(value),
      );
    });
  }

  Object? _encodeFilterValue(Object? value) {
    if (value is DateTime) {
      return <String, Object?>{
        'type': 'dateTime',
        'value': value.toIso8601String(),
      };
    }

    return value;
  }

  Object? _decodeFilterValue(Object? value) {
    if (value case <String, dynamic>{
      'type': 'dateTime',
      'value': final String rawValue,
    }) {
      return DateTime.parse(rawValue);
    }

    return value;
  }
}
