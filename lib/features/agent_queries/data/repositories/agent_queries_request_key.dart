import 'dart:convert';

import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_bridge_pagination.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_batch_request.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_options.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:crypto/crypto.dart';

/// Stable identity for an [AgentSqlExecuteRequest].
///
/// Used by short-lived cache/coalescing decorators. Keep this aligned with all
/// request fields that can affect the bridge response or transport route.
abstract final class AgentQueriesRequestKey {
  static String build(AgentSqlExecuteRequest request) {
    final payload = <String, Object?>{
      'agent_id': request.trimmedAgentId,
      'sql': request.trimmedSql,
      'named_params': _canonicalize(request.namedParams),
      'client_token': request.trimmedClientToken,
      'requesting_user_id': request.trimmedRequestingUserId,
      'hub_presence_online_agent_ids_snapshot': _canonicalizeSet(
        request.hubPresenceOnlineAgentIdsSnapshot,
      ),
      'hub_connected_from_approved_catalog_row':
          request.hubConnectedFromApprovedCatalogRow,
      'bridge_timeout_ms': request.bridgeTimeoutMs,
      'pagination': _paginationToKey(request.pagination),
      'execute_options': _executeOptionsToKey(request.executeOptions),
      'use_relay': request.useRelay,
      'api_version': request.apiVersion,
      'outbound_compression': request.outboundCompression?.wireValue,
      'payload_frame_compression': request.payloadFrameCompression?.wireValue,
    };
    return md5.convert(utf8.encode(jsonEncode(payload))).toString();
  }

  static String buildBatch(AgentSqlExecuteBatchRequest request) {
    final payload = <String, Object?>{
      'agent_id': request.trimmedAgentId,
      'commands': request.commands
          .map(
            (command) => <String, Object?>{
              'sql': command.trimmedSql,
              'named_params': _canonicalize(command.namedParams),
              'execution_order': command.executionOrder,
            },
          )
          .toList(growable: false),
      'client_token': request.trimmedClientToken,
      'requesting_user_id': request.trimmedRequestingUserId,
      'hub_presence_online_agent_ids_snapshot': _canonicalizeSet(
        request.hubPresenceOnlineAgentIdsSnapshot,
      ),
      'hub_connected_from_approved_catalog_row':
          request.hubConnectedFromApprovedCatalogRow,
      'bridge_timeout_ms': request.bridgeTimeoutMs,
      'options': _batchOptionsToKey(request.options),
      'use_relay': request.useRelay,
      'api_version': request.apiVersion,
      'payload_frame_compression': request.payloadFrameCompression?.wireValue,
    };
    return md5.convert(utf8.encode(jsonEncode(payload))).toString();
  }

  static Object? _paginationToKey(AgentSqlBridgePagination? pagination) {
    return switch (pagination) {
      null => null,
      AgentSqlPagePagination(:final page, :final pageSize) => <String, Object?>{
        'type': 'page',
        'page': page,
        'page_size': pageSize,
      },
      AgentSqlCursorPagination(:final cursor) => <String, Object?>{
        'type': 'cursor',
        'cursor': cursor,
      },
    };
  }

  static Object? _executeOptionsToKey(AgentSqlExecuteOptions? options) {
    if (options == null) {
      return null;
    }

    return <String, Object?>{
      'max_rows': options.maxRows,
      'sql_timeout_ms': options.sqlTimeoutMs,
      'execution_mode': options.executionMode?.name,
    };
  }

  static Object? _batchOptionsToKey(AgentSqlExecuteBatchOptions? options) {
    if (options == null) {
      return null;
    }

    return <String, Object?>{
      'max_rows': options.maxRows,
      'sql_timeout_ms': options.sqlTimeoutMs,
      'transaction': options.transaction,
    };
  }

  static Object? _canonicalize(Object? value) {
    if (value == null || value is num || value is bool || value is String) {
      return value;
    }
    if (value is DateTime) {
      return value.toUtc().toIso8601String();
    }
    if (value is Map) {
      final entries = value.entries.toList()
        ..sort(
          (left, right) => left.key.toString().compareTo(right.key.toString()),
        );
      return <String, Object?>{
        for (final entry in entries)
          entry.key.toString(): _canonicalize(entry.value),
      };
    }
    if (value is Iterable) {
      return value.map(_canonicalize).toList(growable: false);
    }
    return value.toString();
  }

  static Object? _canonicalizeSet(Set<String>? value) {
    if (value == null) {
      return null;
    }
    return value.toList(growable: false)..sort();
  }
}
