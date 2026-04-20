import 'package:colmeia/features/client_agents/domain/events/agent_presence_event.dart';

/// Transport-agnostic source of presence/catalog events.
///
/// Implementations: `SocketAgentPresenceStream` (Camadas 1+2 do plano
/// `socket_consumer_channel_plan.md` §19), and — opcionalmente, em um
/// PR seguinte — `CompositeAgentPresenceStream` que multiplexa Socket
/// + REST polling (Camada 3) num único `Stream`.
///
/// SOLID:
///
/// - **DIP**: the application/use case depends on this port, never on
///   `socket_io_client`, `Dio`, or `dart:io`.
/// - **SRP / ISP**: presence is intentionally separate from
///   `ClientAgentsRepository` — clients that only need CRUD/sync of
///   approved agents do not pay the cost of a Socket subscription.
abstract interface class AgentPresenceStream {
  /// Broadcast stream of events. Multiple consumers are legal even
  /// though the controller (`ClientAgentsController`) is the primary one.
  ///
  /// Events may arrive out of order — the consumer must use
  /// `event.observedAt` to resolve conflicts.
  Stream<AgentPresenceEvent> events();

  /// Cancels Socket listeners, timers and any other internal
  /// subscription. Idempotent.
  Future<void> dispose();
}
