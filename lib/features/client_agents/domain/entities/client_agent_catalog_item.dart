import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';

class ClientAgentCatalogItem {
  const ClientAgentCatalogItem({
    required this.agent,
    this.isStaleCache = false,
  });

  final ClientAgent agent;
  final bool isStaleCache;
}
