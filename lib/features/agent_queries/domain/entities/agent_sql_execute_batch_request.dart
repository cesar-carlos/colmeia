import 'package:colmeia/core/socket/relay/relay_event_names.dart';

const int kAgentSqlExecuteBatchMaxCommands = 32;

class AgentSqlExecuteBatchRequest {
  const AgentSqlExecuteBatchRequest({
    required this.agentId,
    required this.commands,
    this.clientToken,
    this.requestingUserId,
    this.hubPresenceOnlineAgentIdsSnapshot,
    this.hubConnectedFromApprovedCatalogRow,
    this.bridgeTimeoutMs,
    this.options,
    this.useRelay = false,
    this.apiVersion = kColmeiaAgentBatchApiVersion,
    this.payloadFrameCompression,
    this.skipTransportCache = false,
    this.transportRpcId,
  });

  final String agentId;
  final List<AgentSqlExecuteBatchCommand> commands;
  final String? clientToken;
  final String? requestingUserId;
  final Set<String>? hubPresenceOnlineAgentIdsSnapshot;
  final bool? hubConnectedFromApprovedCatalogRow;
  final int? bridgeTimeoutMs;
  final AgentSqlExecuteBatchOptions? options;
  final bool useRelay;
  final String apiVersion;
  final RelayPayloadFrameCompression? payloadFrameCompression;
  final bool skipTransportCache;

  /// Same semantics as `transportRpcId` on single execute requests.
  final String? transportRpcId;

  String get trimmedAgentId => agentId.trim();
  String? get trimmedClientToken => clientToken?.trim();
  String? get trimmedRequestingUserId => requestingUserId?.trim();

  String? validationError() {
    if (trimmedAgentId.isEmpty) {
      return 'agentId must not be empty';
    }
    if (commands.isEmpty) {
      return 'commands must not be empty';
    }
    if (commands.length > kAgentSqlExecuteBatchMaxCommands) {
      return 'commands must contain at most '
          '$kAgentSqlExecuteBatchMaxCommands items';
    }

    final token = trimmedClientToken;
    if (clientToken != null && (token == null || token.isEmpty)) {
      return 'clientToken must be null or non-empty';
    }

    final userId = trimmedRequestingUserId;
    if (requestingUserId != null && (userId == null || userId.isEmpty)) {
      return 'requestingUserId must be null or non-empty when provided';
    }

    final bridgeTimeout = bridgeTimeoutMs;
    if (bridgeTimeout != null && bridgeTimeout < 1) {
      return 'bridgeTimeoutMs must be >= 1';
    }

    for (var i = 0; i < commands.length; i++) {
      final error = commands[i].validationError();
      if (error != null) {
        return 'commands[$i].$error';
      }
    }

    return options?.validationError();
  }

  AgentSqlExecuteBatchRequest copyWith({
    String? agentId,
    List<AgentSqlExecuteBatchCommand>? commands,
    String? clientToken,
    String? requestingUserId,
    Set<String>? hubPresenceOnlineAgentIdsSnapshot,
    bool? hubConnectedFromApprovedCatalogRow,
    int? bridgeTimeoutMs,
    AgentSqlExecuteBatchOptions? options,
    bool? useRelay,
    String? apiVersion,
    RelayPayloadFrameCompression? payloadFrameCompression,
    bool? skipTransportCache,
    String? transportRpcId,
  }) {
    return AgentSqlExecuteBatchRequest(
      agentId: agentId ?? this.agentId,
      commands: commands ?? this.commands,
      clientToken: clientToken ?? this.clientToken,
      requestingUserId: requestingUserId ?? this.requestingUserId,
      hubPresenceOnlineAgentIdsSnapshot:
          hubPresenceOnlineAgentIdsSnapshot ??
          this.hubPresenceOnlineAgentIdsSnapshot,
      hubConnectedFromApprovedCatalogRow:
          hubConnectedFromApprovedCatalogRow ??
          this.hubConnectedFromApprovedCatalogRow,
      bridgeTimeoutMs: bridgeTimeoutMs ?? this.bridgeTimeoutMs,
      options: options ?? this.options,
      useRelay: useRelay ?? this.useRelay,
      apiVersion: apiVersion ?? this.apiVersion,
      payloadFrameCompression:
          payloadFrameCompression ?? this.payloadFrameCompression,
      skipTransportCache: skipTransportCache ?? this.skipTransportCache,
      transportRpcId: transportRpcId ?? this.transportRpcId,
    );
  }
}

class AgentSqlExecuteBatchCommand {
  const AgentSqlExecuteBatchCommand({
    required this.sql,
    this.namedParams = const <String, Object?>{},
    this.executionOrder,
  });

  final String sql;
  final Map<String, Object?> namedParams;
  final int? executionOrder;

  String get trimmedSql => sql.trim();

  String? validationError() {
    if (trimmedSql.isEmpty) {
      return 'sql must not be empty';
    }
    final order = executionOrder;
    if (order != null && order < 0) {
      return 'executionOrder must be >= 0';
    }
    return null;
  }
}

class AgentSqlExecuteBatchOptions {
  const AgentSqlExecuteBatchOptions({
    this.sqlTimeoutMs,
    this.maxRows,
    this.transaction,
    this.maxParallelReadOnlyBatchItems,
  });

  final int? sqlTimeoutMs;
  final int? maxRows;
  final bool? transaction;
  final int? maxParallelReadOnlyBatchItems;

  String? validationError() {
    final timeout = sqlTimeoutMs;
    if (timeout != null && timeout < 1) {
      return 'sqlTimeoutMs must be >= 1';
    }
    final max = maxRows;
    if (max != null && max < 1) {
      return 'maxRows must be >= 1';
    }
    final parallel = maxParallelReadOnlyBatchItems;
    if (parallel != null && parallel < 1) {
      return 'maxParallelReadOnlyBatchItems must be >= 1';
    }
    return null;
  }

  Map<String, Object?>? toRpcOptions() {
    final map = <String, Object?>{};
    final timeout = sqlTimeoutMs;
    if (timeout != null) {
      map['timeout_ms'] = timeout;
    }
    final max = maxRows;
    if (max != null) {
      map['max_rows'] = max;
    }
    final tx = transaction;
    if (tx != null) {
      map['transaction'] = tx;
    }
    final parallel = maxParallelReadOnlyBatchItems;
    if (parallel != null) {
      map['max_parallel_read_only_batch_items'] = parallel;
    }
    return map.isEmpty ? null : map;
  }
}

const String kColmeiaAgentBatchApiVersion = '2.10';
