import 'package:colmeia/features/agent_queries/domain/entities/agent_sql_execute_request.dart';
import 'package:colmeia/features/agent_queries/domain/ports/agent_queries_cancel_scope.dart';

/// Companion port to `AgentQueriesRemoteDataSource` exposing the
/// **streaming** path for `sql.execute` calls that produce a large
/// progressive result.
///
/// Kept separate from the unary port to honour ISP: callers that only
/// need the final aggregated `Map<String, dynamic>` (the vast majority
/// of queries today) keep depending on `AgentQueriesRemoteDataSource`
/// and never see the streaming surface. Callers that opt into the
/// progressive flow (PR-L+ p3 — relay-only today) depend on this port
/// instead.
///
/// **Wire format.** Each emitted `Map<String, dynamic>` is the JSON
/// payload of one decoded `relay:rpc.chunk`. The hub may also send
/// a single `relay:rpc.response` (non-streaming agent on a streaming
/// caller); in that case the stream emits exactly one item carrying
/// the full bridge envelope and then closes. Either way the consumer
/// keeps using the same `AgentSqlBridgeResponse.parseSuccess` shape
/// — chunks just slice the result rows.
///
/// **Errors.** Failures map 1:1 to the `RelayDispatchException` family
/// already produced by `RelayCommandDispatcher.sendStreaming`:
/// rejection (`RelayRequestRejected`), abort (`RelayStreamTerminated`),
/// timeout (`RelayRequestTimeout`), decode (`RelayDecodeFailure`),
/// dispose (`RelayDispatcherDisposed`). Repository decoders translate
/// them to `AppFailure` exactly like the unary path already does for
/// `SocketDispatchException`.
// PR-L+ p3 keeps a single method; future variants (`cancel`, batched
// streaming) may add more, at which point this ignore goes.
// ignore: one_member_abstracts
abstract interface class AgentQueriesStreamingRemoteDataSource {
  Stream<Map<String, dynamic>> streamSqlExecute(
    AgentSqlExecuteRequest request, {
    AgentQueriesCancelScope? cancelScope,
  });
}
