import 'package:colmeia/features/client_agents/data/models/agent_catalog_record_dto.dart';
import 'package:colmeia/features/client_agents/data/models/client_agent_token_response_dto.dart';

ClientAgentTokenResponseDto parseClientAgentTokenBody(
  Map<String, dynamic> json, {
  required String fallbackAgentId,
}) {
  final dto = ClientAgentTokenResponseDto.fromJson(json);
  if (dto.agentId.isNotEmpty) {
    return dto;
  }
  return ClientAgentTokenResponseDto(
    agentId: fallbackAgentId,
    clientToken: dto.clientToken,
  );
}

AgentCatalogRecordDto parseCatalogAgentBody(Map<String, dynamic> json) {
  final direct = json['agent'];
  if (direct is Map<String, dynamic>) {
    return AgentCatalogRecordDto.fromJson(direct);
  }
  final data = json['data'];
  if (data is Map<String, dynamic>) {
    final nested = data['agent'];
    if (nested is Map<String, dynamic>) {
      return AgentCatalogRecordDto.fromJson(nested);
    }
    return AgentCatalogRecordDto.fromJson(data);
  }
  return AgentCatalogRecordDto.fromJson(json);
}

Set<String> resolveMutatedAgentIds({
  required Map<String, dynamic> body,
  required Set<String> fallbackAgentIds,
}) {
  const knownLists = <String>[
    'agentIds',
    'processedAgentIds',
    'affectedAgentIds',
    'requestedAgentIds',
    'removedAgentIds',
  ];
  for (final key in knownLists) {
    final raw = body[key];
    if (raw is List<dynamic>) {
      final mapped = raw.whereType<String>().toSet();
      if (mapped.isNotEmpty) {
        return mapped;
      }
    }
  }
  return fallbackAgentIds;
}
