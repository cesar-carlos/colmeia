import 'package:colmeia/core/socket/relay/relay_rpc_body.dart';

/// Mirrors hub `isRelayStreamingCapableCommand` in
/// `relay_command_validation.ts`.
///
/// Used to withhold `fastPath: true` on `relay:rpc.request` for commands that
/// need `relay:rpc.accepted` before `relay:rpc.stream.pull`. Hub rejects the
/// combination with `accepted { success: false }` (`BAD_REQUEST`).
bool isRelayStreamingCapableRpcBody(Map<String, Object?> body) {
  final command = resolveRelayRpcBody(body);
  if (command == null) {
    return false;
  }
  final method = command['method']?.toString();
  if (method == 'sql.executeBatch') {
    return true;
  }
  if (method != 'sql.execute') {
    return false;
  }
  final params = command['params'];
  if (params is! Map) {
    return false;
  }
  final options = params['options'];
  if (options is! Map) {
    return false;
  }
  return options['prefer_db_streaming'] == true ||
      options['multi_result'] == true;
}
