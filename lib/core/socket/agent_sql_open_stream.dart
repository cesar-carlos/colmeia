/// Open hub stream that can receive a best-effort `sql.cancel`.
class AgentSqlOpenStream {
  const AgentSqlOpenStream({
    required this.agentId,
    required this.streamId,
  });

  final String agentId;
  final String streamId;
}
