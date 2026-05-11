import 'package:colmeia/core/errors/app_failure.dart';

class AgentQueryExecutionParticipant<Row> {
  const AgentQueryExecutionParticipant({
    required this.agentId,
    required this.displayName,
    required this.rows,
    required this.elapsedMs,
    int? sourceRowCount,
    this.failure,
    this.wasDiscardedByRace = false,
  }) : sourceRowCount = sourceRowCount ?? rows.length;

  final String agentId;
  final String displayName;
  final List<Row> rows;
  final int sourceRowCount;
  final AppFailure? failure;
  final int elapsedMs;
  final bool wasDiscardedByRace;

  bool get isSuccess => failure == null;

  bool reachedSourceRowLimit(int maxRows) =>
      isSuccess && sourceRowCount >= maxRows;
}
