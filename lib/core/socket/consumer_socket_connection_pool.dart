import 'package:colmeia/core/socket/consumer_socket_connection.dart';

/// Optional multi-socket spike surface. Default Colmeia builds use
/// [poolSize] `1` and route everything through [primary].
///
/// A second connection (`secondary`) is reserved for future throughput
/// experiments — see roadmap phase 5. Ops must keep sticky sessions when
/// `poolSize > 1`.
class ConsumerSocketConnectionPool {
  ConsumerSocketConnectionPool({
    required ConsumerSocketConnection primary,
    ConsumerSocketConnection? secondary,
    this.poolSize = 1,
  }) : _primary = primary,
       _secondary = secondary,
       assert(poolSize >= 1, 'poolSize must be >= 1');

  final ConsumerSocketConnection _primary;
  final ConsumerSocketConnection? _secondary;
  final int poolSize;

  ConsumerSocketConnection get primary => _primary;

  /// Data-heavy relay traffic (spike only). Falls back to [primary].
  ConsumerSocketConnection get data => _secondary ?? _primary;

  /// Control / presence / lightweight commands (always [primary] today).
  ConsumerSocketConnection get control => _primary;

  bool get isMultiConnection => poolSize > 1 && _secondary != null;
}
