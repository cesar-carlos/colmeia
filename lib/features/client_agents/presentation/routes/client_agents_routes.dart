import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/features/client_agents/application/client_agents_page_session_service.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agent_detail_controller.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agents_controller.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agents_owner_controller.dart';
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
      builder: (context, state) {
        // Factory-scoped controllers: [ClientAgentsPage] disposes them on
        // route exit. RetryAfterGates are owned by the controller unless
        // injected from GetIt (see project_architecture DI lifecycle).
        return ClientAgentsPage(
          controller: getIt<ClientAgentsController>(),
          ownerController: getIt<ClientAgentsOwnerController>(),
          pageSessionService: getIt<ClientAgentsPageSessionService>(),
        );
      },
      routes: <RouteBase>[
        GoRoute(
          name: AppRoute.agentsDetail.name,
          path: ':$_agentIdPathParameter',
          builder: (context, state) {
            final agentId = state.pathParameters[_agentIdPathParameter]!;
            return ClientAgentDetailPage(
              key: ValueKey<String>(agentId),
              agentId: agentId,
              controller: getIt<ClientAgentDetailController>(),
            );
          },
        ),
      ],
    ),
  ];
}
