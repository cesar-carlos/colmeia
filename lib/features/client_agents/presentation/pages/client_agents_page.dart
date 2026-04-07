import 'dart:async';

import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_access_request_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_access_request.dart';
import 'package:colmeia/features/client_agents/domain/entities/pending_agent_action.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agents_controller.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/actions/app_primary_button.dart';
import 'package:colmeia/shared/widgets/actions/app_secondary_button.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/feedback/inline_alert_banner.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
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
                    'Acompanhe seus agentes aprovados, solicite novos acessos '
                    'e consulte o andamento das solicitacoes.',
                footer: Wrap(
                  spacing: tokens.gapSm,
                  runSpacing: tokens.gapSm,
                  children: <Widget>[
                    if (pendingCount > 0)
                      Chip(label: Text('$pendingCount acoes para enviar')),
                    AppSecondaryButton(
                      label: 'Atualizar',
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: controller.isLoading
                          ? null
                          : () => unawaited(controller.refreshAll()),
                    ),
                    if (pendingCount > 0)
                      AppPrimaryButton(
                        label: 'Enviar solicitacoes',
                        icon: const Icon(Icons.sync_rounded),
                        onPressed: controller.isSyncing
                            ? null
                            : () => unawaited(controller.syncPending()),
                        isLoading: controller.isSyncing,
                      ),
                  ],
                ),
              ),
              if (controller.actionErrorMessage
                  case final String message) ...<Widget>[
                SizedBox(height: tokens.sectionSpacing),
                AppInlineErrorPanel(
                  title: 'Nao foi possivel concluir a acao',
                  message: message,
                ),
              ],
              if (controller.actionFeedbackMessage
                  case final String message) ...<Widget>[
                SizedBox(height: tokens.gapMd),
                _ActionFeedbackBanner(
                  message: message,
                  kind: controller.actionFeedbackKind,
                ),
              ],
              SizedBox(height: tokens.sectionSpacing),
              AppSectionCardWithHeading(
                title: 'Manutencao de agentes',
                subtitle:
                    'Use as abas para ver agentes aprovados, pedir novos '
                    'acessos e acompanhar o historico das solicitacoes.',
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
                          errorMessage: controller.approvedAgentsErrorMessage,
                          onRemoveAccess: (agent) => unawaited(
                            controller.removeAccess(agentIds: <String>{agent}),
                          ),
                          onRetry: () => unawaited(controller.refreshAll()),
                          isMutating: controller.isSyncing,
                        ),
                      ),
                      AppTabViewItem(
                        label: 'Solicitar acesso',
                        child: _RequestAccessTab(
                          onRequestAccess: (agentIds) => unawaited(
                            controller.requestAccess(agentIds: agentIds),
                          ),
                          onClearMessages: () {
                            controller
                              ..clearActionError()
                              ..clearActionFeedback();
                          },
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
                          errorMessage: controller.accessRequestsErrorMessage,
                          pendingErrorMessage:
                              controller.pendingActionsErrorMessage,
                          onRetry: () => unawaited(controller.refreshAll()),
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
    required this.errorMessage,
    required this.onRemoveAccess,
    required this.onRetry,
    required this.isMutating,
  });

  final List<ClientAgent> agents;
  final String? errorMessage;
  final ValueChanged<String> onRemoveAccess;
  final VoidCallback onRetry;
  final bool isMutating;

  @override
  Widget build(BuildContext context) {
    if (errorMessage case final String message) {
      return AppInlineErrorPanel(
        title: 'Nao foi possivel carregar seus agentes',
        message: message,
        onRetry: onRetry,
      );
    }

    if (agents.isEmpty) {
      return const Text(
        'Nenhum agente aprovado no momento. Solicite acesso na aba '
        '"Solicitar acesso".',
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

class _RequestAccessTab extends StatefulWidget {
  const _RequestAccessTab({
    required this.onRequestAccess,
    required this.onClearMessages,
    required this.isMutating,
  });

  final ValueChanged<Set<String>> onRequestAccess;
  final VoidCallback onClearMessages;
  final bool isMutating;

  @override
  State<_RequestAccessTab> createState() => _RequestAccessTabState();
}

class _RequestAccessTabState extends State<_RequestAccessTab> {
  static final RegExp _uuidPattern = RegExp(
    '^[0-9a-fA-F]{8}-'
    '[0-9a-fA-F]{4}-'
    '[1-5][0-9a-fA-F]{3}-'
    '[89abAB][0-9a-fA-F]{3}-'
    r'[0-9a-fA-F]{12}$',
  );

  final TextEditingController _agentIdsController = TextEditingController();
  String? _validationMessage;
  String? _inputNoteMessage;

  @override
  void dispose() {
    _agentIdsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const Text(
          'Informe um ou mais agentIds para solicitar acesso a esta '
          'conta. '
          'Use virgula, espaco ou quebra de linha para separar os UUIDs.',
        ),
        SizedBox(height: tokens.gapSm),
        const Text(
          'O agentId deve ser informado pelo responsavel do agente ou por um '
          'fluxo externo. Quando a solicitacao for aprovada, o agente sera '
          'liberado automaticamente para esta conta.',
        ),
        SizedBox(height: tokens.gapMd),
        AppTextField(
          controller: _agentIdsController,
          label: 'Agent IDs',
          hintText: '11111111-1111-1111-1111-111111111111',
          maxLines: 4,
          minLines: 3,
          textInputAction: TextInputAction.newline,
          onChanged: (_) {
            if (_validationMessage != null || _inputNoteMessage != null) {
              setState(() {
                _validationMessage = null;
                _inputNoteMessage = null;
              });
            }
            widget.onClearMessages();
          },
        ),
        if (_validationMessage case final String message) ...<Widget>[
          SizedBox(height: tokens.gapSm),
          Text(
            message,
            style:
                Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
        ],
        if (_inputNoteMessage case final String message) ...<Widget>[
          SizedBox(height: tokens.gapSm),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
        SizedBox(height: tokens.gapMd),
        AppPrimaryButton(
          label: 'Solicitar acesso',
          icon: const Icon(Icons.send_rounded),
          isLoading: widget.isMutating,
          onPressed: widget.isMutating ? null : _submit,
        ),
      ],
    );
  }

  void _submit() {
    final parsed = _parseAgentIds(_agentIdsController.text);
    if (parsed.validAgentIds.isEmpty) {
      setState(() {
        _validationMessage = parsed.invalidAgentIds.isEmpty
            ? 'Informe pelo menos um agentId valido para continuar.'
            : 'Os seguintes agentIds sao invalidos: '
                  '${parsed.invalidAgentIds.join(', ')}.';
        _inputNoteMessage = null;
      });
      return;
    }

    widget.onRequestAccess(parsed.validAgentIds);
    setState(() {
      _validationMessage = null;
      _inputNoteMessage = parsed.duplicatedAgentIds.isEmpty
          ? null
          : 'IDs duplicados foram ignorados automaticamente: '
                '${parsed.duplicatedAgentIds.join(', ')}.';
    });
  }

  _ParsedAgentIds _parseAgentIds(String rawValue) {
    final rawAgentIds = rawValue
        .split(RegExp(r'[\s,;]+'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);

    if (rawAgentIds.isEmpty) {
      return const _ParsedAgentIds();
    }

    final validAgentIds = <String>{};
    final duplicatedAgentIds = <String>{};
    final invalidAgentIds = <String>[];

    for (final agentId in rawAgentIds) {
      if (!_uuidPattern.hasMatch(agentId)) {
        invalidAgentIds.add(agentId);
        continue;
      }
      if (!validAgentIds.add(agentId)) {
        duplicatedAgentIds.add(agentId);
      }
    }

    return _ParsedAgentIds(
      validAgentIds: validAgentIds,
      duplicatedAgentIds: duplicatedAgentIds.toSet(),
      invalidAgentIds: invalidAgentIds,
    );
  }
}

class _ParsedAgentIds {
  const _ParsedAgentIds({
    this.validAgentIds = const <String>{},
    this.duplicatedAgentIds = const <String>{},
    this.invalidAgentIds = const <String>[],
  });

  final Set<String> validAgentIds;
  final Set<String> duplicatedAgentIds;
  final List<String> invalidAgentIds;
}

class _RequestsTab extends StatelessWidget {
  const _RequestsTab({
    required this.requests,
    required this.pendingActions,
    required this.errorMessage,
    required this.pendingErrorMessage,
    required this.onRetry,
  });

  final List<ClientAgentAccessRequest> requests;
  final List<PendingAgentAction> pendingActions;
  final String? errorMessage;
  final String? pendingErrorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      if (errorMessage case final String message) ...<Widget>[
        AppInlineErrorPanel(
          title: 'Nao foi possivel carregar as solicitacoes',
          message: message,
          onRetry: onRetry,
        ),
      ],
      if (pendingErrorMessage case final String message) ...<Widget>[
        AppInlineErrorPanel(
          title: 'Nao foi possivel carregar os envios pendentes',
          message: message,
          onRetry: onRetry,
        ),
      ],
    ];

    if (requests.isEmpty && pendingActions.isEmpty) {
      if (children.isNotEmpty) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        );
      }
      return const Text('Sem solicitacoes no momento.');
    }

    children
      ..addAll(
        pendingActions.map(
          (action) {
            final errorSuffix = action.errorMessage == null
                ? ''
                : ' (${action.errorMessage})';
            return _AgentTile(
              title: 'Envio pendente: ${action.agentId}',
              subtitle: '${_pendingActionDescription(action)}$errorSuffix',
              trailing: _StatusChip(
                label: _pendingActionChipLabel(action),
                kind: _pendingActionChipKind(action),
              ),
            );
          },
        ),
      )
      ..addAll(
        requests.map(
          (request) => _AgentTile(
            title: request.agentName,
            subtitle: _requestStatusDescription(request.status),
            trailing: _StatusChip(
              label: _requestStatusLabel(request.status),
              kind: _requestStatusChipKind(request.status),
            ),
          ),
        ),
      );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  String _requestStatusLabel(AgentAccessRequestStatus status) {
    return switch (status) {
      AgentAccessRequestStatus.pending => 'Pendente',
      AgentAccessRequestStatus.approved => 'Aprovado',
      AgentAccessRequestStatus.rejected => 'Rejeitado',
      AgentAccessRequestStatus.expired => 'Expirado',
      AgentAccessRequestStatus.unknown => 'Status indisponivel',
    };
  }

  String _requestStatusDescription(AgentAccessRequestStatus status) {
    return switch (status) {
      AgentAccessRequestStatus.pending =>
        'Em analise pelo responsavel do agente.',
      AgentAccessRequestStatus.approved =>
        'Aprovado e disponivel para esta conta.',
      AgentAccessRequestStatus.rejected =>
        'Nao foi aprovado pelo responsavel do agente.',
      AgentAccessRequestStatus.expired =>
        'A solicitacao expirou. Envie novamente se necessario.',
      AgentAccessRequestStatus.unknown =>
        'O status dessa solicitacao ainda nao esta disponivel.',
    };
  }

  String _pendingActionDescription(PendingAgentAction action) {
    return switch (action.state) {
      PendingAgentActionState.queued =>
        'Pronto para envio.',
      PendingAgentActionState.syncing =>
        'Enviando agora.',
      PendingAgentActionState.failed =>
        'Nao foi possivel enviar. Tente novamente.',
      PendingAgentActionState.synced => 'Enviado.',
    };
  }

  String _pendingActionChipLabel(PendingAgentAction action) {
    final prefix = switch (action.type) {
      PendingAgentActionType.requestAccess => 'Solicitar',
      PendingAgentActionType.removeAccess => 'Remover',
    };
    final suffix = switch (action.state) {
      PendingAgentActionState.queued => 'pronto para envio',
      PendingAgentActionState.syncing => 'enviando',
      PendingAgentActionState.failed => 'falhou',
      PendingAgentActionState.synced => 'enviado',
    };
    return '$prefix: $suffix';
  }

  _StatusChipKind _pendingActionChipKind(PendingAgentAction action) {
    return switch (action.state) {
      PendingAgentActionState.queued => _StatusChipKind.info,
      PendingAgentActionState.syncing => _StatusChipKind.success,
      PendingAgentActionState.failed => _StatusChipKind.error,
      PendingAgentActionState.synced => _StatusChipKind.neutral,
    };
  }

  _StatusChipKind _requestStatusChipKind(AgentAccessRequestStatus status) {
    return switch (status) {
      AgentAccessRequestStatus.pending => _StatusChipKind.info,
      AgentAccessRequestStatus.approved => _StatusChipKind.success,
      AgentAccessRequestStatus.rejected => _StatusChipKind.error,
      AgentAccessRequestStatus.expired => _StatusChipKind.neutral,
      AgentAccessRequestStatus.unknown => _StatusChipKind.neutral,
    };
  }
}

class _ActionFeedbackBanner extends StatelessWidget {
  const _ActionFeedbackBanner({
    required this.message,
    required this.kind,
  });

  final String message;
  final ClientAgentsActionFeedbackKind? kind;

  @override
  Widget build(BuildContext context) {
    final resolvedKind = kind ?? ClientAgentsActionFeedbackKind.info;
    return switch (resolvedKind) {
      ClientAgentsActionFeedbackKind.info => InlineAlertBanner(
        message: message,
        icon: Icons.schedule_send_rounded,
      ),
      ClientAgentsActionFeedbackKind.success => DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(
            Theme.of(context).extension<AppThemeTokens>()?.gapSm ?? 8,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(
            Theme.of(context).extension<AppThemeTokens>()?.gapMd ?? 12,
          ),
          child: Row(
            children: <Widget>[
              Icon(
                Icons.check_circle_outline_rounded,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                size: 18,
              ),
              SizedBox(
                width:
                    Theme.of(context).extension<AppThemeTokens>()?.gapSm ?? 8,
              ),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    };
  }
}

enum _StatusChipKind { info, success, error, neutral }

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.kind,
  });

  final String label;
  final _StatusChipKind kind;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (backgroundColor, foregroundColor) = switch (kind) {
      _StatusChipKind.info => (
        colorScheme.secondaryContainer,
        colorScheme.onSecondaryContainer,
      ),
      _StatusChipKind.success => (
        colorScheme.primaryContainer,
        colorScheme.onPrimaryContainer,
      ),
      _StatusChipKind.error => (
        colorScheme.errorContainer,
        colorScheme.onErrorContainer,
      ),
      _StatusChipKind.neutral => (
        colorScheme.surfaceContainerHighest,
        colorScheme.onSurfaceVariant,
      ),
    };

    return Align(
      alignment: Alignment.centerLeft,
      child: Chip(
        label: Text(label),
        backgroundColor: backgroundColor,
        labelStyle: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: foregroundColor),
        side: BorderSide.none,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      ),
    );
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
