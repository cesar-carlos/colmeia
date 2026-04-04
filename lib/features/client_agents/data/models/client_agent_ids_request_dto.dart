class ClientAgentIdsRequestDto {
  const ClientAgentIdsRequestDto({
    required this.agentIds,
  });

  final Set<String> agentIds;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'agentIds': agentIds.toList(growable: false),
    };
  }
}
