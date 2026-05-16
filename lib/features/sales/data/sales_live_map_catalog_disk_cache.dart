import 'dart:convert';

import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_participant.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_report.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_strategy.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_key.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_target.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_across_agents_page_result.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_row.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
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
  static const int _schemaVersion = 1;
  static const String _keyPrefix = 'colmeia_sales_live_map_catalog_v1.';

  String _storageKey({
    required String userId,
    required String agentSignature,
    required int codEmpresa,
    required int codFilial,
  }) {
    return '$_keyPrefix${userId.trim()}|$codEmpresa|$codFilial|$agentSignature';
  }

  static String agentSignature(Set<String>? selectedAgentIds) {
    if (selectedAgentIds == null || selectedAgentIds.isEmpty) {
      return '*';
    }
    final sorted = selectedAgentIds.toList(growable: false)..sort();
    return sorted.join(',');
  }

  CadastroFilialAcrossAgentsPageResult? readIfFresh({
    required String userId,
    required Set<String>? selectedAgentIds,
    required int codEmpresa,
    required int codFilial,
    required DateTime now,
  }) {
    final key = _storageKey(
      userId: userId,
      agentSignature: agentSignature(selectedAgentIds),
      codEmpresa: codEmpresa,
      codFilial: codFilial,
    );
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final cachedAtMs = decoded['cachedAtMs'];
      if (cachedAtMs is! int) {
        return null;
      }
      final age = now.difference(
        DateTime.fromMillisecondsSinceEpoch(cachedAtMs),
      );
      if (age > ttl) {
        return null;
      }
      return _decode(decoded);
    } on Object catch (e, st) {
      AppLogger.warning(
        'Sales live map catalog disk cache decode failed',
        context: <String, Object?>{'operation': 'SalesLiveMapCatalogDiskCache'},
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<void> write({
    required String userId,
    required Set<String>? selectedAgentIds,
    required int codEmpresa,
    required int codFilial,
    required DateTime now,
    required CadastroFilialAcrossAgentsPageResult result,
  }) async {
    final key = _storageKey(
      userId: userId,
      agentSignature: agentSignature(selectedAgentIds),
      codEmpresa: codEmpresa,
      codFilial: codFilial,
    );
    final encoded = jsonEncode(_encode(now: now, result: result));
    await _prefs.setString(key, encoded);
  }

  Future<void> invalidateUser(String userId) async {
    final prefix = '$_keyPrefix${userId.trim()}|';
    final keys = _prefs
        .getKeys()
        .where((k) => k.startsWith(prefix))
        .toList(growable: false);
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }

  Map<String, Object?> _encode({
    required DateTime now,
    required CadastroFilialAcrossAgentsPageResult result,
  }) {
    return <String, Object?>{
      'v': _schemaVersion,
      'cachedAtMs': now.millisecondsSinceEpoch,
      'participants': <Object?>[
        for (final p in result.report.participants)
          if (p.isSuccess)
            <String, Object?>{
              'agentId': p.agentId,
              'displayName': p.displayName,
              'elapsedMs': p.elapsedMs,
              'rows': <Object?>[
                for (final r in p.rows) _rowToJson(r),
              ],
            },
      ],
    };
  }

  Map<String, Object?> _rowToJson(CadastroFilialRow r) {
    return <String, Object?>{
      'ce': r.codEmpresa,
      'cf': r.codFilial,
      'nf': r.nomeFilial,
      'fa': r.nomeFantasia,
      'cp': r.cep,
      'nm': r.nomeMunicipio,
      'uf': r.ufMunicipio,
      'ib': r.codigoIbge,
    };
  }

  CadastroFilialRow _rowFromJson(Map<String, dynamic> m) {
    return CadastroFilialRow(
      codEmpresa: m['ce'] as int,
      codFilial: m['cf'] as int,
      nomeFilial: m['nf'] as String,
      nomeFantasia: m['fa'] as String?,
      cep: m['cp'] as String?,
      nomeMunicipio: m['nm'] as String?,
      ufMunicipio: m['uf'] as String?,
      codigoIbge: m['ib'] as String?,
    );
  }

  CadastroFilialAcrossAgentsPageResult? _decode(Map<String, dynamic> decoded) {
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
      participants.add(
        AgentQueryExecutionParticipant<CadastroFilialRow>(
          agentId: agentId,
          displayName: displayName,
          rows: List<CadastroFilialRow>.unmodifiable(rows),
          elapsedMs: item['elapsedMs'] as int? ?? 0,
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
    return CadastroFilialAcrossAgentsPageResult.fromReport(report);
  }
}
