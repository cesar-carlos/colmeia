import 'dart:async';

import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_catalog_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_profile_address.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agent_detail_controller.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/presentation/localization/sync_app_localizations_mixin.dart';
import 'package:colmeia/shared/widgets/actions/app_secondary_button.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
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
                      ? AppSecondaryButton(
                          label: l10n.clientAgentsRefresh,
                          icon: const Icon(Icons.refresh_rounded),
                          isLoading: controller.isRefreshing,
                          onPressed:
                              controller.isRefreshing ||
                                  (controller.isLoading && agent == null)
                              ? null
                              : () => unawaited(
                                  _controller.refresh(widget.agentId),
                                ),
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
