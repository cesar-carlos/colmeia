import 'dart:convert';

import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_participant.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_across_agents_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_filter.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_row.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/sales/data/sales_live_map_catalog_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Short-lived on-device snapshot of branch catalog rows for faster first paint.
///
/// Omits secrets (no `client_token`). Reconstructed targets use
/// [AgentConnectionStatus.unknown] — sufficient for map aggregation only;
/// network load replaces this before final state.
class SalesLiveMapCatalogDiskCache {
  SalesLiveMapCatalogDiskCache(this._prefs);

  final SharedPreferences _prefs;

  static const Duration ttl = Duration(minutes: 4);
  static const int _schemaVersion = 2;
  static const String _keyPrefix = 'colmeia_sales_live_map_catalog_v2.';
  static const String _legacyKeyPrefix = 'colmeia_sales_live_map_catalog_v1.';
  static const int _legacyCompanyCode = 1;
  static const int _legacyBranchCode = 1;

  static String agentSignature(Set<String>? selectedAgentIds) {
    if (selectedAgentIds == null || selectedAgentIds.isEmpty) {
      return '*';
    }
    final sorted = selectedAgentIds.toList(growable: false)..sort();
    return sorted.join(',');
  }

  static String branchSignature(
    Iterable<CadastroFilialBranchRef> selectedBranches,
  ) {
    return CadastroFilialBranchRef.signature(selectedBranches);
  }

  CadastroFilialAcrossAgentsPageResult? readIfFresh({
    required String userId,
    required SalesLiveMapCatalogScope scope,
    required DateTime now,
  }) {
    final v2Key = _storageKey(userId: userId, scope: scope);
    final raw = _prefs.getString(v2Key);
    if (raw != null && raw.isNotEmpty) {
      return _decodeIfFresh(raw: raw, expectedScope: scope, now: now);
    }

    if (!scope.isFullAgent) {
      return null;
    }

    final legacyKey = _legacyStorageKey(
      userId: userId,
      agentSignature: scope.agentSignature,
    );
    final legacyRaw = _prefs.getString(legacyKey);
    if (legacyRaw == null || legacyRaw.isEmpty) {
      return null;
    }
    return _decodeIfFresh(raw: legacyRaw, expectedScope: scope, now: now);
  }

  Future<void> write({
    required String userId,
    required SalesLiveMapCatalogScope scope,
    required DateTime now,
    required CadastroFilialAcrossAgentsPageResult result,
  }) async {
    final key = _storageKey(userId: userId, scope: scope);
    final encoded = jsonEncode(
      _encode(now: now, scope: scope, result: result),
    );
    await _prefs.setString(key, encoded);
  }

  Future<void> invalidateUser(String userId) async {
    final trimmedUserId = userId.trim();
    final keys = _prefs
        .getKeys()
        .where(
          (key) =>
              key.startsWith('$_keyPrefix$trimmedUserId|') ||
              key.startsWith('$_legacyKeyPrefix$trimmedUserId|'),
        )
        .toList(growable: false);
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }

  String _storageKey({
    required String userId,
    required SalesLiveMapCatalogScope scope,
  }) {
    return '$_keyPrefix${userId.trim()}|${scope.storageKey}';
  }

  String _legacyStorageKey({
    required String userId,
    required String agentSignature,
  }) {
    return '$_legacyKeyPrefix${userId.trim()}|$_legacyCompanyCode|'
        '$_legacyBranchCode|$agentSignature';
  }

  CadastroFilialAcrossAgentsPageResult? _decodeIfFresh({
    required String raw,
    required SalesLiveMapCatalogScope expectedScope,
    required DateTime now,
  }) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        _logWarning('Sales live map catalog disk cache payload is not a map');
        return null;
      }
      final cachedAtMs = decoded['cachedAtMs'];
      if (cachedAtMs is! int) {
        _logWarning('Sales live map catalog disk cache missing cachedAtMs');
        return null;
      }
      final age = now.difference(
        DateTime.fromMillisecondsSinceEpoch(cachedAtMs),
      );
      if (age > ttl) {
        return null;
      }
      final schemaVersion = decoded['v'];
      if (schemaVersion == 1) {
        return _decodeV1(decoded, expectedScope: expectedScope);
      }
      if (schemaVersion == _schemaVersion) {
        return _decodeV2(decoded, expectedScope: expectedScope);
      }
      _logWarning(
        'Sales live map catalog disk cache schema is unsupported',
        context: <String, Object?>{'schemaVersion': schemaVersion},
      );
      return null;
    } on Object catch (error, stackTrace) {
      AppLogger.warning(
        'Sales live map catalog disk cache decode failed',
        context: <String, Object?>{'operation': 'SalesLiveMapCatalogDiskCache'},
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Map<String, Object?> _encode({
    required DateTime now,
    required SalesLiveMapCatalogScope scope,
    required CadastroFilialAcrossAgentsPageResult result,
  }) {
    return <String, Object?>{
      'v': _schemaVersion,
      'cachedAtMs': now.millisecondsSinceEpoch,
      'scopeKind': scope.kind.name,
      'agentSignature': scope.agentSignature,
      'branchSignature': scope.branchSignature,
      'paginationStalledAgentIds': result.paginationStalledAgentIds.toList(
        growable: false,
      ),
      'participants': <Object?>[
        for (final participant in result.report.participants)
          if (participant.isSuccess)
            <String, Object?>{
              'agentId': participant.agentId,
              'displayName': participant.displayName,
              'elapsedMs': participant.elapsedMs,
              'sourceRowCount': participant.sourceRowCount,
              'rows': <Object?>[
                for (final row in participant.rows) _rowToJson(row),
              ],
            },
      ],
    };
  }

  CadastroFilialAcrossAgentsPageResult? _decodeV2(
    Map<String, dynamic> decoded, {
    required SalesLiveMapCatalogScope expectedScope,
  }) {
    final rawScopeKind = decoded['scopeKind'];
    final rawAgentSignature = decoded['agentSignature'];
    final rawBranchSignature = decoded['branchSignature'];
    if (rawScopeKind is! String ||
        rawAgentSignature is! String ||
        rawBranchSignature is! String) {
      _logWarning('Sales live map catalog disk cache v2 metadata is invalid');
      return null;
    }
    if (rawScopeKind != expectedScope.kind.name ||
        rawAgentSignature != expectedScope.agentSignature ||
        rawBranchSignature != expectedScope.branchSignature) {
      _logWarning(
        'Sales live map catalog disk cache scope metadata mismatch',
        context: <String, Object?>{
          'expectedScopeKind': expectedScope.kind.name,
          'expectedAgentSignature': expectedScope.agentSignature,
          'expectedBranchSignature': expectedScope.branchSignature,
          'storedScopeKind': rawScopeKind,
          'storedAgentSignature': rawAgentSignature,
          'storedBranchSignature': rawBranchSignature,
        },
      );
      return null;
    }
    return _decodeParticipants(
      decoded,
      paginationStalledAgentIds: _decodeStringSet(
        decoded['paginationStalledAgentIds'],
      ),
      defaultSourceRowCountToRowsLength: false,
    );
  }

  CadastroFilialAcrossAgentsPageResult? _decodeV1(
    Map<String, dynamic> decoded, {
    required SalesLiveMapCatalogScope expectedScope,
  }) {
    if (!expectedScope.isFullAgent) {
      return null;
    }
    return _decodeParticipants(
      decoded,
      paginationStalledAgentIds: const <String>{},
      defaultSourceRowCountToRowsLength: true,
    );
  }

  CadastroFilialAcrossAgentsPageResult? _decodeParticipants(
    Map<String, dynamic> decoded, {
    required Set<String> paginationStalledAgentIds,
    required bool defaultSourceRowCountToRowsLength,
  }) {
    final rawParticipants = decoded['participants'];
    if (rawParticipants is! List) {
      return null;
    }

    final participants = <AgentQueryExecutionParticipant<CadastroFilialRow>>[];
    final plannedTargets = <AgentQueryTarget>[];
    for (final item in rawParticipants) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      final agentId = item['agentId'] as String?;
      final displayName = item['displayName'] as String?;
      if (agentId == null || displayName == null) {
        continue;
      }
      plannedTargets.add(
        AgentQueryTarget(
          agentId: agentId,
          displayName: displayName,
          connectionStatus: AgentConnectionStatus.unknown,
        ),
      );
      final rowsRaw = item['rows'];
      final rows = <CadastroFilialRow>[];
      if (rowsRaw is List) {
        for (final row in rowsRaw) {
          if (row is Map<String, dynamic>) {
            rows.add(_rowFromJson(row));
          }
        }
      }
      final sourceRowCount = item['sourceRowCount'] as int?;
      participants.add(
        AgentQueryExecutionParticipant<CadastroFilialRow>(
          agentId: agentId,
          displayName: displayName,
          rows: List<CadastroFilialRow>.unmodifiable(rows),
          elapsedMs: item['elapsedMs'] as int? ?? 0,
          sourceRowCount: defaultSourceRowCountToRowsLength
              ? rows.length
              : (sourceRowCount ?? rows.length),
        ),
      );
    }

    if (participants.isEmpty) {
      return null;
    }

    final report = AgentQueryExecutionReport<CadastroFilialRow>(
      queryKey: AgentQueryKey.cadastroFilial,
      strategy: AgentQueryExecutionStrategy.mergeAll,
      consideredApprovedAgentCount: plannedTargets.length,
      plannedTargets: List<AgentQueryTarget>.unmodifiable(plannedTargets),
      missingClientTokenTargets: const <AgentQueryTarget>[],
      participants: participants,
      totalElapsedMs: 0,
    );
    return CadastroFilialAcrossAgentsPageResult.fromReport(
      report,
      paginationStalledAgentIds: paginationStalledAgentIds,
    );
  }

  Set<String> _decodeStringSet(Object? raw) {
    if (raw is! List) {
      return const <String>{};
    }
    return Set<String>.unmodifiable(
      raw.whereType<String>().where((value) => value.trim().isNotEmpty),
    );
  }

  Map<String, Object?> _rowToJson(CadastroFilialRow row) {
    return <String, Object?>{
      'ce': row.codEmpresa,
      'cf': row.codFilial,
      'nf': row.nomeFilial,
      'fa': row.nomeFantasia,
      'cp': row.cep,
      'nm': row.nomeMunicipio,
      'uf': row.ufMunicipio,
      'ib': row.codigoIbge,
    };
  }

  CadastroFilialRow _rowFromJson(Map<String, dynamic> json) {
    return CadastroFilialRow(
      codEmpresa: json['ce'] as int,
      codFilial: json['cf'] as int,
      nomeFilial: json['nf'] as String,
      nomeFantasia: json['fa'] as String?,
      cep: json['cp'] as String?,
      nomeMunicipio: json['nm'] as String?,
      ufMunicipio: json['uf'] as String?,
      codigoIbge: json['ib'] as String?,
    );
  }

  void _logWarning(String message, {Map<String, Object?> context = const {}}) {
    AppLogger.warning(
      message,
      context: <String, Object?>{
        'operation': 'SalesLiveMapCatalogDiskCache',
        ...context,
      },
    );
  }
}
