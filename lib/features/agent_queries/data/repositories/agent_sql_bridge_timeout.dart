import 'package:colmeia/core/config/app_environment.dart';

/// Shared bridge/SQL timeout resolution for agent SQL repository implementations.
abstract final class AgentSqlBridgeTimeout {
  static const int defaultSqlTimeoutMs = 162000;
  static const int minSqlTimeoutMs = 5000;

  static ({int bridgeMs, int sqlMs}) resolve({int? bridgeTimeoutMs}) {
    final bridgeMs =
        bridgeTimeoutMs ?? AppEnvironment.agentSqlBridgeMediumTimeoutMs;
    final sqlMs = (bridgeMs * 0.9).round().clamp(
      minSqlTimeoutMs,
      defaultSqlTimeoutMs,
    );
    return (bridgeMs: bridgeMs, sqlMs: sqlMs);
  }
}
