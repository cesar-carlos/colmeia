import 'dart:async';

import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_access_request_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_access_request.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_catalog_item.dart';
import 'package:colmeia/features/client_agents/domain/entities/pending_agent_action.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agents_controller.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/actions/app_primary_button.dart';
import 'package:colmeia/shared/widgets/actions/app_secondary_button.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:colmeia/shared/widgets/navigation/app_tab_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ClientAgentsPage extends StatefulWidget {
  const ClientAgentsPage({super.key});

  @override
  State<ClientAgentsPage> createState() => _ClientAgentsPageState();
}

class _ClientAgentsPageState extends State<ClientAgentsPage> {
  late final ClientAgentsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = getIt<ClientAgentsController>();
    unawaited(_controller.initialize());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    return ChangeNotifierProvider<ClientAgentsController>.value(
      value: _controller,
      child: Consumer<ClientAgentsController>(
        builder: (context, controller, _) {
          final pendingCount = controller.pendingActions.length;
          return ListView(
            padding: context.pageScrollPadding(tokens),
            children: <Widget>[
              AppShellPageIntro(
                eyebrow: 'Fontes de dados',
                title: 'Gestao de agentes',
                subtitle:
                    'Gerencie os agentes aprovados para esta conta, solicite '
                    'novos acessos e acompanhe o status de sincronizacao.',
                footer: Wrap(
                  spacing: tokens.gapSm,
                  runSpacing: tokens.gapSm,
                  children: <Widget>[
                    if (pendingCount > 0)
                      Chip(label: Text('$pendingCount pendencias locais')),
                    AppSecondaryButton(
                      label: 'Atualizar',
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: controller.isLoading
                          ? null
                          : () => unawaited(controller.refreshAll()),
                    ),
                    if (pendingCount > 0)
                      AppPrimaryButton(
                        label: 'Sincronizar pendencias',
                        icon: const Icon(Icons.sync_rounded),
                        onPressed: controller.isSyncing
                            ? null
                            : () => unawaited(controller.syncPending()),
                        isLoading: controller.isSyncing,
                      ),
                  ],
                ),
              ),
              if (controller.errorMessage
                  case final String message) ...<Widget>[
                SizedBox(height: tokens.sectionSpacing),
                AppInlineErrorPanel(
                  title: 'Nao foi possivel concluir a operacao',
                  message: message,
                  onRetry: () => unawaited(controller.refreshAll()),
                ),
              ],
              SizedBox(height: tokens.sectionSpacing),
              AppSectionCardWithHeading(
                title: 'Manutencao de agentes',
                subtitle:
                    'Use as abas para acompanhar agentes aprovados, '
                    'catalogo disponivel e solicitacoes de acesso.',
                child: AppSkeleton(
                  enabled: controller.isLoading,
                  child: AppTabView(
                    items: <AppTabViewItem>[
                      AppTabViewItem(
                        label: 'Meus agentes',
                        child: _ApprovedAgentsTab(
                          agents:
                              controller.approvedAgents?.items ??
                              const <ClientAgent>[],
                          onRemoveAccess: (agent) => unawaited(
                            controller.removeAccess(agentIds: <String>{agent}),
                          ),
                          isMutating: controller.isSyncing,
                        ),
                      ),
                      AppTabViewItem(
                        label: 'Catalogo',
                        child: _CatalogTab(
                          catalog:
                              controller.catalog?.items ??
                              const <ClientAgentCatalogItem>[],
                          onRequestAccess: (agent) => unawaited(
                            controller.requestAccess(agentIds: <String>{agent}),
                          ),
                          isMutating: controller.isSyncing,
                        ),
                      ),
                      AppTabViewItem(
                        label: 'Solicitacoes',
                        child: _RequestsTab(
                          requests:
                              controller.accessRequests?.items ??
                              const <ClientAgentAccessRequest>[],
                          pendingActions: controller.pendingActions,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ApprovedAgentsTab extends StatelessWidget {
  const _ApprovedAgentsTab({
    required this.agents,
    required this.onRemoveAccess,
    required this.isMutating,
  });

  final List<ClientAgent> agents;
  final ValueChanged<String> onRemoveAccess;
  final bool isMutating;

  @override
  Widget build(BuildContext context) {
    if (agents.isEmpty) {
      return const Text(
        'Nenhum agente aprovado no momento. Solicite acesso na aba Catalogo.',
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: agents
          .map(
            (agent) => _AgentTile(
              title: agent.name,
              subtitle:
                  '${agent.tradeName ?? 'Sem nome fantasia'} - '
                  '${_catalogStatusLabel(agent)} - ${_connectionLabel(agent)}',
              onTap: () {
                context.goTo(
                  AppRoute.agentsDetail,
                  pathParameters: <String, String>{
                    'agentId': agent.agentId,
                  },
                );
              },
              trailing: AppSecondaryButton(
                label: 'Remover acesso',
                onPressed: isMutating
                    ? null
                    : () => onRemoveAccess(agent.agentId),
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  String _catalogStatusLabel(ClientAgent agent) {
    return switch (agent.catalogStatus.name) {
      'inactive' => 'inativo',
      _ => 'ativo',
    };
  }

  String _connectionLabel(ClientAgent agent) {
    return switch (agent.connectionStatus) {
      AgentConnectionStatus.online => 'online',
      AgentConnectionStatus.offline => 'offline',
      AgentConnectionStatus.unknown => 'status operacional indisponivel',
    };
  }
}

class _CatalogTab extends StatelessWidget {
  const _CatalogTab({
    required this.catalog,
    required this.onRequestAccess,
    required this.isMutating,
  });

  final List<ClientAgentCatalogItem> catalog;
  final ValueChanged<String> onRequestAccess;
  final bool isMutating;

  @override
  Widget build(BuildContext context) {
    if (catalog.isEmpty) {
      return const Text('Nenhum agente encontrado no catalogo.');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: catalog
          .map(
            (item) => _AgentTile(
              title: item.agent.name,
              subtitle:
                  item.agent.address?.shortLabel ?? 'Endereco nao informado',
              onTap: () {
                context.goTo(
                  AppRoute.agentsDetail,
                  pathParameters: <String, String>{
                    'agentId': item.agent.agentId,
                  },
                );
              },
              trailing: AppPrimaryButton(
                label: 'Solicitar acesso',
                onPressed: isMutating
                    ? null
                    : () => onRequestAccess(item.agent.agentId),
              ),
            ),
          )
          .toList(growable: false),
    );
  }
}

class _RequestsTab extends StatelessWidget {
  const _RequestsTab({
    required this.requests,
    required this.pendingActions,
  });

  final List<ClientAgentAccessRequest> requests;
  final List<PendingAgentAction> pendingActions;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty && pendingActions.isEmpty) {
      return const Text('Sem solicitacoes no momento.');
    }

    final children = <Widget>[
      ...pendingActions.map(
        (action) {
          final errorSuffix = action.errorMessage == null
              ? ''
              : ' (${action.errorMessage})';
          return _AgentTile(
            title: 'Pendencia local: ${action.agentId}',
            subtitle: '${action.type.name} - ${action.state.name}$errorSuffix',
          );
        },
      ),
      ...requests.map(
        (request) => _AgentTile(
          title: request.agentName,
          subtitle: _requestStatusLabel(request.status),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  String _requestStatusLabel(AgentAccessRequestStatus status) {
    return switch (status) {
      AgentAccessRequestStatus.pending => 'Aguardando aprovacao',
      AgentAccessRequestStatus.approved => 'Aprovado',
      AgentAccessRequestStatus.rejected => 'Rejeitado',
      AgentAccessRequestStatus.expired => 'Expirado',
      AgentAccessRequestStatus.unknown => 'Status indisponivel',
    };
  }
}

class _AgentTile extends StatelessWidget {
  const _AgentTile({
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final card = Padding(
      padding: EdgeInsets.only(bottom: tokens.gapSm),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(tokens.formFieldRadius),
        ),
        child: Padding(
          padding: EdgeInsets.all(tokens.gapMd),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: tokens.gapXs),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (trailing != null) ...<Widget>[
                SizedBox(height: tokens.gapSm),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
    if (onTap == null) {
      return card;
    }
    return InkWell(
      borderRadius: BorderRadius.circular(tokens.formFieldRadius),
      onTap: onTap,
      child: card,
    );
  }
}
