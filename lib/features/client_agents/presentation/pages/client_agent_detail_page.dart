import 'dart:async';

import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/features/agent_meta/domain/entities/client_token_policy.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_catalog_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_profile_address.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agent_detail_controller.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agent_profile_edit_card.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/presentation/localization/sync_app_localizations_mixin.dart';
import 'package:colmeia/shared/widgets/actions/app_primary_button.dart';
import 'package:colmeia/shared/widgets/actions/app_secondary_button.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ClientAgentDetailPage extends StatefulWidget {
  const ClientAgentDetailPage({
    required this.agentId,
    super.key,
  });

  final String agentId;

  @override
  State<ClientAgentDetailPage> createState() => _ClientAgentDetailPageState();
}

class _ClientAgentDetailPageState extends State<ClientAgentDetailPage>
    with SyncAppLocalizationsMixin<ClientAgentDetailPage> {
  late final ClientAgentDetailController _controller;
  bool _initialLoadScheduled = false;

  @override
  void initState() {
    super.initState();
    _controller = getIt<ClientAgentDetailController>();
  }

  @override
  void bindAppLocalizations(AppLocalizations l10n) {
    _controller.activeLocalizations = l10n;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialLoadScheduled) {
      _initialLoadScheduled = true;
      unawaited(_controller.load(widget.agentId));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final l10n = AppLocalizations.of(context);
    return ChangeNotifierProvider<ClientAgentDetailController>.value(
      value: _controller,
      child: Consumer<ClientAgentDetailController>(
        builder: (context, controller, _) {
          final agent = controller.agent;
          final initialLoading =
              controller.isLoading && agent == null && !controller.isRefreshing;
          final blockingError =
              controller.errorMessage != null && agent == null;
          final showRefreshFooter = !initialLoading;

          return RefreshIndicator(
            onRefresh: () async {
              final c = _controller;
              if (c.isRefreshing || (c.isLoading && c.agent == null)) {
                return;
              }
              await c.refresh(widget.agentId);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: context.pageScrollPadding(tokens),
              children: <Widget>[
                AppShellPageIntro(
                  eyebrow: l10n.clientAgentDetailEyebrow,
                  title: l10n.clientAgentDetailTitle,
                  subtitle: l10n.clientAgentDetailSubtitle,
                  footer: showRefreshFooter
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Wrap(
                              spacing: tokens.gapSm,
                              runSpacing: tokens.gapSm,
                              children: <Widget>[
                                AppSecondaryButton(
                                  label: l10n.clientAgentsRefresh,
                                  icon: const Icon(Icons.refresh_rounded),
                                  isLoading: controller.isRefreshing,
                                  onPressed:
                                      controller.isRefreshing ||
                                          (controller.isLoading &&
                                              agent == null)
                                      ? null
                                      : () => unawaited(
                                          _controller.refresh(widget.agentId),
                                        ),
                                ),
                                if (agent != null &&
                                    controller.agentSupportsRpcMethod(
                                      'agent.getProfile',
                                    ))
                                  AppSecondaryButton(
                                    label: controller.isOnRetryCooldown
                                        ? l10n
                                              .clientAgentDetailRetryAfterCountdown(
                                                controller
                                                        .retryAfterGate
                                                        .remaining
                                                        ?.inSeconds ??
                                                    0,
                                              )
                                        : l10n
                                              .clientAgentDetailRefreshFromAgent,
                                    icon: const Icon(Icons.cloud_sync_rounded),
                                    isLoading: controller.isRefreshingFromAgent,
                                    onPressed:
                                        controller.isRefreshingFromAgent ||
                                            controller.isOnRetryCooldown
                                        ? null
                                        : () => unawaited(
                                            _controller.refreshFromAgent(
                                              agentId: widget.agentId,
                                            ),
                                          ),
                                  ),
                              ],
                            ),
                          ],
                        )
                      : null,
                ),
                SizedBox(height: tokens.sectionSpacing),
                if (initialLoading)
                  _ClientAgentDetailLoadingSkeleton(tokens: tokens)
                else if (blockingError)
                  AppInlineErrorPanel(
                    title: l10n.clientAgentDetailLoadErrorTitle,
                    message: controller.errorMessage!,
                    onRetry: controller.reload,
                    retryLabel: l10n.appInlineErrorRetry,
                  )
                else ...<Widget>[
                  if (agent != null &&
                      controller.errorMessage != null) ...<Widget>[
                    AppInlineErrorPanel(
                      title: l10n.clientAgentDetailLoadErrorTitle,
                      message: controller.errorMessage!,
                      onRetry: () => unawaited(
                        _controller.refresh(widget.agentId),
                      ),
                      retryLabel: l10n.appInlineErrorRetry,
                    ),
                    SizedBox(height: tokens.gapMd),
                  ],
                  if (agent != null) ...<Widget>[
                    ClientAgentProfileEditCard(
                      agent: agent,
                      controller: controller,
                      l10n: l10n,
                      tokens: tokens,
                    ),
                    SizedBox(height: tokens.gapMd),
                    _IdentityCard(agent: agent, l10n: l10n),
                    SizedBox(height: tokens.gapMd),
                    _ContactCard(agent: agent, l10n: l10n),
                    if (_hasAddress(agent)) ...<Widget>[
                      SizedBox(height: tokens.gapMd),
                      _AddressCard(address: agent.address!, l10n: l10n),
                    ],
                    if (agent.notes != null ||
                        agent.observation != null) ...<Widget>[
                      SizedBox(height: tokens.gapMd),
                      _NotesCard(agent: agent, l10n: l10n),
                    ],
                    SizedBox(height: tokens.gapMd),
                    _RecordCard(agent: agent, l10n: l10n),
                    SizedBox(height: tokens.gapMd),
                    _AgentClientTokenCard(
                      agentId: agent.agentId,
                      controller: _controller,
                      l10n: l10n,
                      tokens: tokens,
                    ),
                    if (controller.clientTokenStatus ==
                        ClientAgentTokenStatus.configured) ...<Widget>[
                      SizedBox(height: tokens.gapMd),
                      _ClientTokenPolicyCard(
                        agentId: agent.agentId,
                        controller: _controller,
                        l10n: l10n,
                        tokens: tokens,
                      ),
                    ],
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  bool _hasAddress(ClientAgent agent) {
    final a = agent.address;
    if (a == null) return false;
    return (a.street?.isNotEmpty ?? false) ||
        (a.district?.isNotEmpty ?? false) ||
        (a.postalCode?.isNotEmpty ?? false) ||
        (a.city?.isNotEmpty ?? false) ||
        (a.state?.isNotEmpty ?? false);
  }
}

class _AgentClientTokenCard extends StatefulWidget {
  const _AgentClientTokenCard({
    required this.agentId,
    required this.controller,
    required this.l10n,
    required this.tokens,
  });

  final String agentId;
  final ClientAgentDetailController controller;
  final AppLocalizations l10n;
  final AppThemeTokens tokens;

  @override
  State<_AgentClientTokenCard> createState() => _AgentClientTokenCardState();
}

class _AgentClientTokenCardState extends State<_AgentClientTokenCard> {
  late final TextEditingController _tokenController;
  int _lastSyncedRevision = -1;
  bool _obscureToken = true;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController();
    widget.controller.addListener(_syncTokenFieldFromController);
    _syncTokenFieldFromController();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncTokenFieldFromController);
    _tokenController.dispose();
    super.dispose();
  }

  void _syncTokenFieldFromController() {
    final c = widget.controller;
    if (_lastSyncedRevision == c.clientTokenRevision) {
      return;
    }
    _lastSyncedRevision = c.clientTokenRevision;
    final text = c.persistedClientTokenForField;
    if (_tokenController.text != text) {
      _tokenController.text = text;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final theme = Theme.of(context);
    final feedback = c.clientTokenFeedback;
    final feedbackError = c.clientTokenError;
    final isMutating = c.isSavingClientToken;

    return AppSectionCardWithHeading(
      title: widget.l10n.clientAgentDetailSectionServerToken,
      subtitle: widget.l10n.clientAgentDetailSectionServerTokenSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _ClientTokenStatusRow(
            status: c.clientTokenStatus,
            isLoading: c.isLoadingClientToken,
            l10n: widget.l10n,
            tokens: widget.tokens,
          ),
          SizedBox(height: widget.tokens.gapMd),
          AppTextField(
            controller: _tokenController,
            label: widget.l10n.clientAgentsClientTokenLabel,
            hintText: widget.l10n.clientAgentsClientTokenHint,
            obscureText: _obscureToken,
            textInputAction: TextInputAction.done,
            suffix: IconButton(
              tooltip: _obscureToken
                  ? widget.l10n.clientAgentsClientTokenShow
                  : widget.l10n.clientAgentsClientTokenHide,
              onPressed: () {
                setState(() {
                  _obscureToken = !_obscureToken;
                });
              },
              icon: Icon(
                _obscureToken
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
              ),
            ),
          ),
          SizedBox(height: widget.tokens.gapMd),
          Wrap(
            spacing: widget.tokens.gapSm,
            runSpacing: widget.tokens.gapSm,
            children: <Widget>[
              AppPrimaryButton(
                label: c.isOnRetryCooldown
                    ? widget.l10n.clientAgentDetailRetryAfterCountdown(
                        c.retryAfterGate.remaining?.inSeconds ?? 0,
                      )
                    : widget.l10n.clientAgentDetailServerTokenSave,
                icon: const Icon(Icons.cloud_upload_rounded),
                isLoading: isMutating,
                onPressed: isMutating || c.isOnRetryCooldown
                    ? null
                    : () => unawaited(
                        c.saveClientAgentToken(
                          agentId: widget.agentId,
                          rawToken: _tokenController.text,
                        ),
                      ),
              ),
              AppSecondaryButton(
                label: widget.l10n.clientAgentDetailServerTokenRemove,
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: isMutating || c.isOnRetryCooldown
                    ? null
                    : () => unawaited(
                        c.removeClientAgentToken(agentId: widget.agentId),
                      ),
              ),
            ],
          ),
          if (feedback != null) ...<Widget>[
            SizedBox(height: widget.tokens.gapSm),
            Text(
              feedback,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
          if (feedbackError != null) ...<Widget>[
            SizedBox(height: widget.tokens.gapSm),
            Text(
              feedbackError,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ClientTokenStatusRow extends StatelessWidget {
  const _ClientTokenStatusRow({
    required this.status,
    required this.isLoading,
    required this.l10n,
    required this.tokens,
  });

  final ClientAgentTokenStatus status;
  final bool isLoading;
  final AppLocalizations l10n;
  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final (IconData icon, Color color, String label) = switch (status) {
      ClientAgentTokenStatus.configured => (
        Icons.verified_rounded,
        colors.primary,
        l10n.clientAgentDetailServerTokenStatusConfigured,
      ),
      ClientAgentTokenStatus.missing => (
        Icons.info_outline_rounded,
        colors.onSurfaceVariant,
        l10n.clientAgentDetailServerTokenStatusMissing,
      ),
      ClientAgentTokenStatus.unknown => (
        Icons.help_outline_rounded,
        colors.onSurfaceVariant,
        l10n.clientAgentDetailServerTokenStatusUnknown,
      ),
    };

    return Row(
      children: <Widget>[
        if (isLoading)
          SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: color,
            ),
          )
        else
          Icon(icon, size: 20, color: color),
        SizedBox(width: tokens.gapSm),
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

/// Renders the policy returned by `client_token.getPolicy` for the token
/// the server currently holds for this `(client, agent)` pair. Displays
/// graceful fallbacks when the agent does not implement the introspection
/// method or has not been queried yet.
class _ClientTokenPolicyCard extends StatefulWidget {
  const _ClientTokenPolicyCard({
    required this.agentId,
    required this.controller,
    required this.l10n,
    required this.tokens,
  });

  final String agentId;
  final ClientAgentDetailController controller;
  final AppLocalizations l10n;
  final AppThemeTokens tokens;

  @override
  State<_ClientTokenPolicyCard> createState() =>
      _ClientTokenPolicyCardState();
}

class _ClientTokenPolicyCardState extends State<_ClientTokenPolicyCard> {
  bool _hasRequested = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_maybeKickoff);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeKickoff();
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_maybeKickoff);
    super.dispose();
  }

  /// Triggers the policy load only once per visible mount, when the
  /// token snapshot has resolved to "configured" and the controller is
  /// not already busy with another policy call.
  void _maybeKickoff() {
    if (!mounted || _hasRequested) {
      return;
    }
    final c = widget.controller;
    if (c.clientTokenStatus != ClientAgentTokenStatus.configured) {
      return;
    }
    if (c.isLoadingClientTokenPolicy) {
      return;
    }
    if (c.clientTokenPolicy != null || c.clientTokenPolicyUnsupported) {
      return;
    }
    _hasRequested = true;
    unawaited(c.loadClientTokenPolicy(agentId: widget.agentId));
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final Widget body;
    if (c.isLoadingClientTokenPolicy) {
      body = SizedBox(
        height: 64,
        child: Center(
          child: SizedBox.square(
            dimension: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: colors.primary,
            ),
          ),
        ),
      );
    } else if (c.clientTokenPolicyError != null) {
      body = Text(
        c.clientTokenPolicyError!,
        style: theme.textTheme.bodySmall?.copyWith(color: colors.error),
      );
    } else if (c.clientTokenPolicyUnsupported) {
      body = Text(
        widget.l10n.clientAgentDetailPolicyUnsupported,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colors.onSurfaceVariant,
        ),
      );
    } else {
      final policy = c.clientTokenPolicy;
      if (policy == null) {
        body = Text(
          widget.l10n.clientAgentDetailPolicyEmpty,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        );
      } else {
        body = _ClientTokenPolicyBody(
          policy: policy,
          l10n: widget.l10n,
          tokens: widget.tokens,
        );
      }
    }

    return AppSectionCardWithHeading(
      title: widget.l10n.clientAgentDetailSectionPolicy,
      subtitle: widget.l10n.clientAgentDetailSectionPolicySubtitle,
      child: body,
    );
  }
}

class _ClientTokenPolicyBody extends StatelessWidget {
  const _ClientTokenPolicyBody({
    required this.policy,
    required this.l10n,
    required this.tokens,
  });

  final ClientTokenPolicy policy;
  final AppLocalizations l10n;
  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final lines = <Widget>[];

    if (policy.revoked) {
      lines.add(
        _ClientTokenPolicyLine(
          icon: Icons.block_rounded,
          color: colors.error,
          text: l10n.clientAgentDetailPolicyRevoked,
        ),
      );
    }

    if (policy.hasFullAccess) {
      lines.add(
        _ClientTokenPolicyLine(
          icon: Icons.verified_user_rounded,
          color: colors.primary,
          text: l10n.clientAgentDetailPolicyFullAccess,
        ),
      );
    } else {
      if (policy.allTables) {
        lines.add(
          _ClientTokenPolicyLine(
            icon: Icons.table_chart_rounded,
            color: colors.onSurface,
            text: l10n.clientAgentDetailPolicyAllTables,
          ),
        );
      } else if (policy.tableRules.isNotEmpty) {
        lines.add(
          _ClientTokenPolicyChips(
            label: l10n.clientAgentDetailPolicyTablesLabel,
            entries: policy.tableRules,
          ),
        );
      }
      if (policy.allViews) {
        lines.add(
          _ClientTokenPolicyLine(
            icon: Icons.view_list_rounded,
            color: colors.onSurface,
            text: l10n.clientAgentDetailPolicyAllViews,
          ),
        );
      } else if (policy.viewRules.isNotEmpty) {
        lines.add(
          _ClientTokenPolicyChips(
            label: l10n.clientAgentDetailPolicyViewsLabel,
            entries: policy.viewRules,
          ),
        );
      }
      if (policy.allPermissions) {
        lines.add(
          _ClientTokenPolicyLine(
            icon: Icons.admin_panel_settings_rounded,
            color: colors.onSurface,
            text: l10n.clientAgentDetailPolicyAllPermissions,
          ),
        );
      } else if (policy.permissionRules.isNotEmpty) {
        lines.add(
          _ClientTokenPolicyChips(
            label: l10n.clientAgentDetailPolicyPermissionsLabel,
            entries: policy.permissionRules,
          ),
        );
      }
    }

    if (lines.isEmpty) {
      return Text(
        l10n.clientAgentDetailPolicyEmpty,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colors.onSurfaceVariant,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (var i = 0; i < lines.length; i++) ...<Widget>[
          if (i > 0) SizedBox(height: tokens.gapSm),
          lines[i],
        ],
      ],
    );
  }
}

class _ClientTokenPolicyLine extends StatelessWidget {
  const _ClientTokenPolicyLine({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    return Row(
      children: <Widget>[
        Icon(icon, size: 18, color: color),
        SizedBox(width: tokens.gapSm),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class _ClientTokenPolicyChips extends StatelessWidget {
  const _ClientTokenPolicyChips({
    required this.label,
    required this.entries,
  });

  final String label;
  final List<String> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = theme.extension<AppThemeTokens>()!;
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colors.onSurfaceVariant,
          ),
        ),
        SizedBox(height: tokens.gapXs),
        Wrap(
          spacing: tokens.gapXs,
          runSpacing: tokens.gapXs,
          children: <Widget>[
            for (final entry in entries)
              Chip(
                label: Text(entry),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
          ],
        ),
      ],
    );
  }
}

class _ClientAgentDetailLoadingSkeleton extends StatelessWidget {
  const _ClientAgentDetailLoadingSkeleton({required this.tokens});

  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      enabled: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppSectionCardWithHeading(
            title: ' ',
            child: SizedBox(height: tokens.contentSpacing * 4),
          ),
          SizedBox(height: tokens.gapMd),
          AppSectionCardWithHeading(
            title: ' ',
            child: SizedBox(height: tokens.contentSpacing * 2),
          ),
          SizedBox(height: tokens.gapMd),
          AppSectionCardWithHeading(
            title: ' ',
            child: SizedBox(height: tokens.contentSpacing * 2),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cards
// ---------------------------------------------------------------------------

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.agent, required this.l10n});

  final ClientAgent agent;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final na = l10n.clientAgentValueNotAvailable;
    return AppSectionCardWithHeading(
      title: agent.name,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _AgentDetailRow(
            label: l10n.clientAgentFieldTradeName,
            value: _nonEmptyOr(agent.tradeName, na),
          ),
          _AgentDetailRow(
            label: l10n.clientAgentFieldId,
            value: agent.agentId,
          ),
          ..._documentIdentityRows(agent, l10n, na),
          if (_nonEmptyTrim(agent.documentType) != null)
            _AgentDetailRow(
              label: l10n.clientAgentFieldDocumentType,
              value: _nonEmptyTrim(agent.documentType)!,
            ),
          _AgentDetailRow(
            label: l10n.clientAgentFieldStatus,
            value: _catalogStatusLabel(l10n, agent.catalogStatus),
          ),
          _AgentDetailRow(
            label: l10n.clientAgentFieldConnection,
            value: _connectionLabel(l10n, agent.connectionStatus),
          ),
        ],
      ),
    );
  }

  String _nonEmptyOr(String? value, String fallback) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return fallback;
    }
    return trimmed;
  }

  String? _nonEmptyTrim(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  /// Document and CNPJ/CPF from API; one row when both match.
  List<Widget> _documentIdentityRows(
    ClientAgent agent,
    AppLocalizations l10n,
    String na,
  ) {
    final doc = agent.document?.trim();
    final cnpj = agent.cnpjCpf?.trim();
    final hasDoc = doc != null && doc.isNotEmpty;
    final hasCnpj = cnpj != null && cnpj.isNotEmpty;
    if (hasDoc && hasCnpj && doc == cnpj) {
      return <Widget>[
        _AgentDetailRow(
          label: l10n.clientAgentFieldDocument,
          value: doc,
        ),
      ];
    }
    return <Widget>[
      _AgentDetailRow(
        label: l10n.clientAgentFieldDocument,
        value: hasDoc ? doc : na,
      ),
      _AgentDetailRow(
        label: l10n.clientAgentFieldCnpjCpf,
        value: hasCnpj ? cnpj : na,
      ),
    ];
  }

  String _catalogStatusLabel(AppLocalizations l10n, AgentCatalogStatus status) {
    return switch (status) {
      AgentCatalogStatus.inactive => l10n.agentCatalogInactive,
      AgentCatalogStatus.active => l10n.agentCatalogActive,
    };
  }

  String _connectionLabel(AppLocalizations l10n, AgentConnectionStatus status) {
    return switch (status) {
      AgentConnectionStatus.online => l10n.agentConnectionOnline,
      AgentConnectionStatus.offline => l10n.agentConnectionOffline,
      AgentConnectionStatus.unknown => l10n.agentConnectionUnknown,
    };
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.agent, required this.l10n});

  final ClientAgent agent;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final na = l10n.clientAgentValueNotAvailable;
    return AppSectionCardWithHeading(
      title: l10n.clientAgentDetailSectionContact,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _AgentDetailRow(
            label: l10n.clientAgentFieldEmail,
            value: agent.email ?? na,
          ),
          _AgentDetailRow(
            label: l10n.clientAgentFieldPhone,
            value: agent.phone ?? na,
          ),
          _AgentDetailRow(
            label: l10n.clientAgentFieldMobile,
            value: agent.mobile ?? na,
          ),
        ],
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({required this.address, required this.l10n});

  final AgentProfileAddress address;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final na = l10n.clientAgentValueNotAvailable;
    final streetLine = _streetLine(address);
    return AppSectionCardWithHeading(
      title: l10n.clientAgentDetailSectionAddress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (streetLine.isNotEmpty)
            _AgentDetailRow(
              label: l10n.clientAgentFieldStreet,
              value: streetLine,
            ),
          _AgentDetailRow(
            label: l10n.clientAgentFieldDistrict,
            value: address.district ?? na,
          ),
          _AgentDetailRow(
            label: l10n.clientAgentFieldPostalCode,
            value: address.postalCode ?? na,
          ),
          _AgentDetailRow(
            label: l10n.clientAgentFieldCity,
            value: address.city ?? na,
          ),
          _AgentDetailRow(
            label: l10n.clientAgentFieldState,
            value: address.state ?? na,
          ),
        ],
      ),
    );
  }

  String _streetLine(AgentProfileAddress a) {
    final street = a.street?.trim() ?? '';
    final number = a.number?.trim() ?? '';
    if (street.isEmpty) return number;
    if (number.isEmpty) return street;
    return '$street, $number';
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({required this.agent, required this.l10n});

  final ClientAgent agent;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final notes = agent.notes;
    final observation = agent.observation;
    return AppSectionCardWithHeading(
      title: l10n.clientAgentDetailSectionNotes,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (notes != null && notes.isNotEmpty)
            _AgentDetailRow(
              label: l10n.clientAgentFieldNotes,
              value: notes,
            ),
          if (observation != null && observation.isNotEmpty)
            _AgentDetailRow(
              label: l10n.clientAgentFieldObservation,
              value: observation,
            ),
        ],
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.agent, required this.l10n});

  final ClientAgent agent;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final na = l10n.clientAgentValueNotAvailable;
    return AppSectionCardWithHeading(
      title: l10n.clientAgentDetailSectionRecord,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (agent.profileUpdatedAt != null)
            _AgentDetailRow(
              label: l10n.clientAgentFieldProfileUpdatedAt,
              value: AppBrFormatters.shortDateTime(agent.profileUpdatedAt!),
            ),
          _AgentDetailRow(
            label: l10n.clientAgentFieldCreatedAt,
            value: AppBrFormatters.shortDate(agent.createdAt),
          ),
          _AgentDetailRow(
            label: l10n.clientAgentFieldUpdatedAt,
            value: agent.updatedAt.isAfter(agent.createdAt)
                ? AppBrFormatters.shortDateTime(agent.updatedAt)
                : na,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared row widget
// ---------------------------------------------------------------------------

class _AgentDetailRow extends StatelessWidget {
  const _AgentDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typography = theme.appTypography;
    final colors = theme.appColors;
    final tokens = theme.extension<AppThemeTokens>()!;
    return Padding(
      padding: EdgeInsets.only(bottom: tokens.gapSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: typography.caption.copyWith(color: colors.onSurfaceVariant),
          ),
          Text(value, style: typography.body),
        ],
      ),
    );
  }
}
