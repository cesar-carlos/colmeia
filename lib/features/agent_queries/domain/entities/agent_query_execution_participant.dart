import 'package:colmeia/core/errors/app_failure.dart';

class AgentQueryExecutionParticipant<Row> {
  const AgentQueryExecutionParticipant({
    required this.agentId,
    required this.displayName,
    required this.rows,
    required this.elapsedMs,
    this.failure,
    this.wasDiscardedByRace = false,
  });

  final String agentId;
  final String displayName;
  final List<Row> rows;
  final AppFailure? failure;
  final int elapsedMs;
  final bool wasDiscardedByRace;

  bool get isSuccess => failure == null;
}
