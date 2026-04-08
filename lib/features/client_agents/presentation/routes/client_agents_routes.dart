import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/features/client_agents/presentation/pages/client_agent_detail_page.dart';
import 'package:colmeia/features/client_agents/presentation/pages/client_agents_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

const String _agentIdPathParameter = 'agentId';

List<RouteBase> buildClientAgentsRoutes() {
  return <RouteBase>[
    GoRoute(
      name: AppRoute.agents.name,
      path: AppRoute.agents.path,
      builder: (context, state) => const ClientAgentsPage(),
      routes: <RouteBase>[
        GoRoute(
          name: AppRoute.agentsDetail.name,
          path: ':$_agentIdPathParameter',
          builder: (context, state) {
            final agentId = state.pathParameters[_agentIdPathParameter]!;
            return ClientAgentDetailPage(
              key: ValueKey<String>(agentId),
              agentId: agentId,
            );
          },
        ),
      ],
    ),
  ];
}
