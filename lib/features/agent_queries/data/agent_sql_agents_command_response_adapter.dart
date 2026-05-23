import 'package:colmeia/core/socket/payload_frame.dart';
import 'package:colmeia/core/socket/payload_frame_codec.dart';
import 'package:colmeia/features/agent_queries/data/agent_sql_relay_response_adapter.dart';

/// Decodes a wire payload from `agents:command_response`.
///
/// Post-migration hubs wrap JSON-RPC or bridge JSON inside [PayloadFrame].
/// Older hubs may still emit bridge maps or JSON-RPC directly.
Map<String, dynamic> decodeAgentsCommandWirePayload(
  Map<String, dynamic> payload,
) {
  if (!_looksLikePayloadFrameMap(payload)) {
    return payload;
  }

  final frame = switch (PayloadFrame.parseDetailed(payload)) {
    PayloadFrameParseSuccess(frame: final parsed) => parsed,
    PayloadFrameParseFailure(:final message, :final code) =>
      throw FormatException(
        'Invalid agents:command PayloadFrame ($code): $message',
      ),
  };

  final decoded = const PayloadFrameCodec().decodeJson(frame);
  if (decoded is! Map) {
    throw const FormatException(
      'agents:command PayloadFrame inner JSON must be an object',
    );
  }
  return _deepStringKeyedMap(decoded);
}

/// Normalizes `agents:command_response` payloads into the bridge envelope
/// consumed by `AgentSqlBridgeResponse`.
///
/// Hubs may return REST-parity envelopes, coordinator batch shapes
/// (`response.type == batch` with `items`), flat `response.items`, raw
/// JSON-RPC (`jsonrpc` + `result` / `error`), or a [PayloadFrame] wrapper
/// around any of the above. Relay uses [relayJsonRpcToBridgeEnvelope] only;
/// this adapter covers the extra socket legacy shapes before the repository
/// parser runs.
Map<String, dynamic> agentsCommandResponseToBridgeEnvelope(
  Map<String, dynamic> payload, {
  required String responseType,
}) {
  final logical = decodeAgentsCommandWirePayload(payload);
  final response = logical['response'];
  if (response is Map) {
    final responseMap = Map<String, dynamic>.from(response);
    if (responseType == 'batch') {
      if (_isRestParityBatchResponse(responseMap)) {
        return _normalizeBridgeRoot(logical, responseMap);
      }
      final items = _readBatchItemsList(responseMap);
      if (items != null) {
        return _batchItemsToBridgeEnvelope(logical, items);
      }
    } else if (_isRestParitySingleResponse(responseMap)) {
      return _normalizeBridgeRoot(logical, responseMap);
    } else {
      final normalizedItem = _normalizeCoordinatorSingleItem(responseMap);
      if (normalizedItem != null) {
        return _normalizeBridgeRoot(logical, normalizedItem);
      }
    }
  }

  if (_isFlatBridgeFailure(logical)) {
    return _flatBridgeFailureEnvelope(logical, responseType: responseType);
  }

  return relayJsonRpcToBridgeEnvelope(
    logical,
    responseType: responseType,
  );
}

bool _isFlatBridgeFailure(Map<String, dynamic> logical) {
  if (logical['response'] is Map) {
    return false;
  }
  if (logical['success'] == false) {
    return true;
  }
  final error = logical['error'];
  if (error is Map && error.isNotEmpty) {
    return true;
  }
  if (error is String && error.isNotEmpty) {
    return true;
  }
  return false;
}

Map<String, dynamic> _flatBridgeFailureEnvelope(
  Map<String, dynamic> logical, {
  required String responseType,
}) {
  final error = logical['error'];
  final errorMap = error is Map
      ? Map<String, dynamic>.from(error)
      : <String, dynamic>{
          'code': -32000,
          'message': error?.toString() ?? 'bridge_error',
        };
  return <String, dynamic>{
    'response': <String, dynamic>{
      'success': true,
      'type': responseType,
      'item': <String, dynamic>{
        'success': false,
        'error': errorMap,
      },
    },
  };
}

bool _looksLikePayloadFrameMap(Map<String, dynamic> payload) {
  return payload.containsKey('schemaVersion') &&
      payload.containsKey('payload') &&
      !payload.containsKey('response');
}

Map<String, dynamic> _deepStringKeyedMap(Map<dynamic, dynamic> source) {
  return source.map(
    (key, value) => MapEntry<String, dynamic>(
      key.toString(),
      _deepStringKeyedValue(value),
    ),
  );
}

dynamic _deepStringKeyedValue(Object? value) {
  if (value is Map) {
    return _deepStringKeyedMap(value);
  }
  if (value is List) {
    return value.map(_deepStringKeyedValue).toList(growable: false);
  }
  return value;
}

/// Coordinator envelopes may return `item` with `success` but without a
/// `result` object until the hub fills rows; `AgentSqlBridgeResponse` still
/// requires `item.result` for success parsing.
Map<String, dynamic>? _normalizeCoordinatorSingleItem(
  Map<String, dynamic> responseMap,
) {
  final item = responseMap['item'];
  if (item is! Map) {
    return null;
  }
  final itemMap = Map<String, dynamic>.from(item);
  if (itemMap.containsKey('result') || itemMap.containsKey('error')) {
    return null;
  }
  if (itemMap['success'] != true) {
    return null;
  }
  return <String, dynamic>{
    ...responseMap,
    'success': responseMap['success'] ?? true,
    'item': <String, dynamic>{
      ...itemMap,
      'result': <String, dynamic>{
        'rows': <Map<String, dynamic>>[],
        'row_count': 0,
      },
    },
  };
}

bool _isRestParitySingleResponse(Map<String, dynamic> responseMap) {
  final item = responseMap['item'];
  if (item is! Map) {
    return false;
  }
  return item.containsKey('result') || item.containsKey('error');
}

bool _isRestParityBatchResponse(Map<String, dynamic> responseMap) {
  final item = responseMap['item'];
  if (item is! Map) {
    return false;
  }
  final result = item['result'];
  return result is Map && result['items'] is List;
}

List<dynamic>? _readBatchItemsList(Map<String, dynamic> responseMap) {
  final items = responseMap['items'];
  if (items is! List) {
    return null;
  }
  if (responseMap['type'] == 'batch') {
    return items;
  }
  if (!responseMap.containsKey('item')) {
    return items;
  }
  return null;
}

Map<String, dynamic> _batchItemsToBridgeEnvelope(
  Map<String, dynamic> payload,
  List<dynamic> items,
) {
  return <String, dynamic>{
    ...payload,
    'response': <String, dynamic>{
      'success': true,
      'item': <String, dynamic>{
        'success': true,
        'result': <String, dynamic>{'items': items},
      },
    },
  };
}

Map<String, dynamic> _normalizeBridgeRoot(
  Map<String, dynamic> payload,
  Map<String, dynamic> responseMap,
) {
  return <String, dynamic>{
    ...payload,
    'response': <String, dynamic>{
      ...responseMap,
      'success': responseMap['success'] ?? true,
    },
  };
}
