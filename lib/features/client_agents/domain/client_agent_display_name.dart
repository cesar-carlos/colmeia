import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';

String resolveClientAgentDisplayName(
  ClientAgent? agent,
  String fallbackAgentId,
) {
  final legalName = agent?.name.trim();
  if (legalName != null && legalName.isNotEmpty) {
    return legalName;
  }

  final tradeName = agent?.tradeName?.trim();
  if (tradeName != null && tradeName.isNotEmpty) {
    return tradeName;
  }

  return fallbackAgentId.trim();
}
