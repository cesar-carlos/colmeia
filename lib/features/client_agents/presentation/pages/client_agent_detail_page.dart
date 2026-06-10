import 'dart:async';

import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/core/formatters/app_br_formatters.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/features/agent_meta/domain/entities/client_token_policy.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_catalog_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agent_detail_controller.dart';
import 'package:colmeia/features/client_agents/presentation/localization/client_agents_presentation_message_l10n.dart';
import 'package:colmeia/features/client_agents/presentation/models/client_agents_presentation_message.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agent_profile_edit_card.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agent_unsaved_changes_dialog.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_colors.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/design_system/app_typography_tokens.dart';
import 'package:colmeia/shared/widgets/actions/app_primary_button.dart';
import 'package:colmeia/shared/widgets/actions/app_secondary_button.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
import 'package:colmeia/shared/widgets/app_skeleton.dart';
import 'package:colmeia/shared/widgets/app_tag_chip.dart';
import 'package:colmeia/shared/widgets/forms/app_text_field.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:colmeia/shared/widgets/navigation/app_tab_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Visual constants for the agent detail page.
///
/// Centralized so spinner/icon sizes do not drift between the token status
/// row, the policy loading state, the policy line glyphs and the copy
/// affordance.
const double _kStatusSpinnerSize = 18;
const double _kStatusIconSize = 20;
const double _kPolicyLoadingHeight = 64;
const double _kPolicyLoadingSpinnerSize = 22;
const double _kSpinnerStrokeWidth = 2;
const double _kPolicyLineIconSize = 18;
const double _kCopyIconSize = 20;
const double _kCopyTouchTargetSize = 40;
const Duration _kRefreshScrollDuration = Duration(milliseconds: 250);
const int _kDetailTabProfile = 0;
const int _kDetailTabConnection = 2;

class ClientAgentDetailPage extends StatefulWidget {
  const ClientAgentDetailPage({
    required this.agentId,
    required this.controller,
    super.key,
  });

  final String agentId;
  final ClientAgentDetailController controller;

  @override
  State<ClientAgentDetailPage> createState() => _ClientAgentDetailPageState();
}

class _ClientAgentDetailPageState extends State<ClientAgentDetailPage> {
  late final ClientAgentDetailController _controller;
  bool _initialLoadScheduled = false;
  ClientAgentsPresentationMessage? _refreshFromAgentNotice;
  ClientAgentsPresentationMessage? _refreshFromAgentError;

  /// Anchor used by the policy card when the user taps "Save new token"
  /// after the server reports the current token as revoked. We scroll
  /// the token card back into view and focus its input so the user can
  /// type a replacement without hunting up the page.
  final GlobalKey _tokenCardAnchorKey = GlobalKey();
  final FocusNode _tokenInputFocusNode = FocusNode(
    debugLabel: 'AgentClientTokenInput',
  );
  late final ValueNotifier<int> _detailTabIndex;
  bool _profileFormDirty = false;
  bool _tokenFieldDirty = false;
  int _profileDiscardRevision = 0;
  int _tokenDiscardRevision = 0;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
    _detailTabIndex = ValueNotifier<int>(_kDetailTabProfile);
    _controller.addListener(_consumeControllerNotices);
  }

  Future<bool> _guardDetailTabChange(int fromIndex, int toIndex) async {
    if (fromIndex == toIndex) {
      return true;
    }
    final l10n = AppLocalizations.of(context);
    final leavingProfile = fromIndex == _kDetailTabProfile && _profileFormDirty;
    final leavingConnection =
        fromIndex == _kDetailTabConnection && _tokenFieldDirty;
    if (!leavingProfile && !leavingConnection) {
      return true;
    }
    final discard = await confirmDiscardClientAgentUnsavedChanges(
      context,
      l10n,
    );
    if (!discard || !mounted) {
      return false;
    }
    setState(() {
      if (leavingProfile) {
        _profileFormDirty = false;
        _profileDiscardRevision++;
      }
      if (leavingConnection) {
        _tokenFieldDirty = false;
        _tokenDiscardRevision++;
      }
    });
    return true;
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
    _controller.removeListener(_consumeControllerNotices);
    _detailTabIndex.dispose();
    _tokenInputFocusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _consumeControllerNotices() {
    final c = _controller;
    var nextNotice = _refreshFromAgentNotice;
    var nextError = _refreshFromAgentError;
    var changed = false;

    if (c.isRefreshingFromAgent && (nextNotice != null || nextError != null)) {
      nextNotice = null;
      nextError = null;
      changed = true;
    }
    if (c.refreshFromAgentFeedback != null || c.refreshFromAgentError != null) {
      nextNotice = c.refreshFromAgentFeedback;
      nextError = c.refreshFromAgentError;
      c.clearRefreshFromAgentFeedback();
      changed = true;
    }
    if (changed && mounted) {
      setState(() {
        _refreshFromAgentNotice = nextNotice;
        _refreshFromAgentError = nextError;
      });
    }
  }

  /// Scrolls the token card back into view and focuses its input.
  /// Triggered by the policy card's "Save new token" CTA after a
  /// revocation. Defensive: does nothing when the anchor is detached
  /// (e.g. card not visible because the user already cleared the
  /// token elsewhere in the meantime).
  Future<void> _focusTokenInput() async {
    _detailTabIndex.value = _kDetailTabConnection;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) {
      return;
    }
    final ctx = _tokenCardAnchorKey.currentContext;
    if (ctx != null && ctx.mounted) {
      await Scrollable.ensureVisible(
        ctx,
        duration: _kRefreshScrollDuration,
        alignment: 0.1,
        curve: Curves.easeOutCubic,
      );
    }
    if (mounted) {
      _tokenInputFocusNode.requestFocus();
    }
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
          final loadErrorMessage = _localizeMessage(
            controller.errorMessage,
            l10n,
          );
          final refreshFromAgentNotice = _localizeMessage(
            _refreshFromAgentNotice,
            l10n,
          );
          final refreshFromAgentError = _localizeMessage(
            _refreshFromAgentError,
            l10n,
          );
          final initialTabSkeletons =
              controller.isLoading && agent == null && !controller.isRefreshing;
          final blockingError = loadErrorMessage != null && agent == null;
          final showRefreshFooter = !initialTabSkeletons;

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
                  sectionLabel: l10n.shellNavAgentsLabel,
                  onSectionLabelTap: () => context.goTo(AppRoute.agents),
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
                                        ? l10n.clientAgentDetailRetryAfterCountdown(
                                            controller
                                                    .retryAfterGate
                                                    .remaining
                                                    ?.inSeconds ??
                                                0,
                                          )
                                        : l10n.clientAgentDetailRefreshFromAgent,
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
                            if (refreshFromAgentNotice != null) ...<Widget>[
                              SizedBox(height: tokens.gapSm),
                              _FeedbackInlineText(
                                message: refreshFromAgentNotice,
                                tone: _FeedbackTone.info,
                              ),
                            ],
                            if (refreshFromAgentError != null) ...<Widget>[
                              SizedBox(height: tokens.gapSm),
                              _FeedbackInlineText(
                                message: refreshFromAgentError,
                                tone: _FeedbackTone.error,
                              ),
                            ],
                          ],
                        )
                      : null,
                ),
                SizedBox(height: tokens.sectionSpacing),
                if (blockingError)
                  AppInlineErrorPanel(
                    title: l10n.clientAgentDetailLoadErrorTitle,
                    message: loadErrorMessage,
                    onRetry: controller.reload,
                    retryLabel: l10n.appInlineErrorRetry,
                  )
                else ...<Widget>[
                  if (agent != null && loadErrorMessage != null) ...<Widget>[
                    AppInlineErrorPanel(
                      title: l10n.clientAgentDetailLoadErrorTitle,
                      message: loadErrorMessage,
                      onRetry: () => unawaited(
                        _controller.refresh(widget.agentId),
                      ),
                      retryLabel: l10n.appInlineErrorRetry,
                    ),
                    SizedBox(height: tokens.gapMd),
                  ],
                  AppTabView(
                    tabIndexListenable: _detailTabIndex,
                    onTabChangeGuard: agent == null
                        ? null
                        : _guardDetailTabChange,
                    items: <AppTabViewItem>[
                      AppTabViewItem(
                        label: l10n.clientAgentDetailTabProfile,
                        child: initialTabSkeletons
                            ? _ClientAgentDetailTabSkeleton(tokens: tokens)
                            : ClientAgentProfileEditCard(
                                agent: agent!,
                                controller: controller,
                                l10n: l10n,
                                tokens: tokens,
                                discardRevision: _profileDiscardRevision,
                                onDirtyChanged: (dirty) {
                                  if (_profileFormDirty != dirty && mounted) {
                                    setState(() => _profileFormDirty = dirty);
                                  }
                                },
                              ),
                      ),
                      AppTabViewItem(
                        label: l10n.clientAgentDetailTabDetails,
                        child: initialTabSkeletons
                            ? _ClientAgentDetailTabSkeleton(tokens: tokens)
                            : _ClientAgentDetailInfoTab(
                                agent: agent!,
                                l10n: l10n,
                                tokens: tokens,
                              ),
                      ),
                      AppTabViewItem(
                        label: l10n.clientAgentDetailTabConnection,
                        child: initialTabSkeletons
                            ? _ClientAgentDetailTabSkeleton(tokens: tokens)
                            : _ClientAgentDetailConnectionTab(
                                agentId: agent!.agentId,
                                controller: controller,
                                l10n: l10n,
                                tokens: tokens,
                                tokenCardAnchorKey: _tokenCardAnchorKey,
                                inputFocusNode: _tokenInputFocusNode,
                                onRequestNewToken: () =>
                                    unawaited(_focusTokenInput()),
                                tokenDiscardRevision: _tokenDiscardRevision,
                                onTokenDirtyChanged: (dirty) {
                                  if (_tokenFieldDirty != dirty && mounted) {
                                    setState(() => _tokenFieldDirty = dirty);
                                  }
                                },
                              ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  String? _localizeMessage(
    ClientAgentsPresentationMessage? message,
    AppLocalizations l10n,
  ) {
    if (message == null) {
      return null;
    }
    return localizeClientAgentsPresentationMessage(message, l10n);
  }
}

class _AgentClientTokenCard extends StatefulWidget {
  const _AgentClientTokenCard({
    required this.agentId,
    required this.controller,
    required this.l10n,
    required this.tokens,
    this.inputFocusNode,
    this.onDirtyChanged,
    this.discardRevision = 0,
  });

  final String agentId;
  final ClientAgentDetailController controller;
  final AppLocalizations l10n;
  final AppThemeTokens tokens;

  /// Optional focus node owned by the page so the policy card can ask
  /// us to focus the input when the user reacts to a token revocation.
  final FocusNode? inputFocusNode;
  final ValueChanged<bool>? onDirtyChanged;
  final int discardRevision;

  @override
  State<_AgentClientTokenCard> createState() => _AgentClientTokenCardState();
}

class _AgentClientTokenCardState extends State<_AgentClientTokenCard> {
  late final TextEditingController _tokenController;
  int _lastSyncedRevision = -1;
  bool _obscureToken = true;
  String _lastAppliedTokenText = '';
  bool _forceApplyNextRevision = false;
  bool _suppressTokenDirtyNotify = false;
  ClientAgentsPresentationMessage? _ephemeralFeedback;
  ClientAgentsPresentationMessage? _ephemeralError;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController();
    _tokenController.addListener(_notifyTokenDirty);
    widget.controller.addListener(_syncTokenFieldFromController);
    _syncTokenFieldFromController();
  }

  @override
  void didUpdateWidget(covariant _AgentClientTokenCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.discardRevision != oldWidget.discardRevision) {
      _forceApplyNextRevision = true;
      _syncTokenFieldFromController();
    }
  }

  void _notifyTokenDirty() {
    if (_suppressTokenDirtyNotify) {
      return;
    }
    final onDirtyChanged = widget.onDirtyChanged;
    if (onDirtyChanged == null) {
      return;
    }
    // Controller sync can run from initState while the connection tab is
    // mounting; defer so the page does not setState during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      onDirtyChanged(_tokenController.text != _lastAppliedTokenText);
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncTokenFieldFromController);
    _tokenController
      ..removeListener(_notifyTokenDirty)
      ..dispose();
    super.dispose();
  }

  void _syncTokenFieldFromController() {
    final c = widget.controller;
    if (c.isSavingClientToken &&
        (_ephemeralFeedback != null || _ephemeralError != null)) {
      setState(() {
        _ephemeralFeedback = null;
        _ephemeralError = null;
      });
    }
    if (c.clientTokenFeedback != null || c.clientTokenError != null) {
      setState(() {
        _ephemeralFeedback = c.clientTokenFeedback;
        _ephemeralError = c.clientTokenError;
      });
      if (c.clientTokenRevision == _lastSyncedRevision) {
        _forceApplyNextRevision = false;
      }
      c.clearClientTokenFeedback();
    }
    if (_lastSyncedRevision == c.clientTokenRevision) {
      return;
    }
    final text = c.persistedClientTokenForField;
    final hasUnsavedLocalEdits = _tokenController.text != _lastAppliedTokenText;
    if (!_forceApplyNextRevision &&
        hasUnsavedLocalEdits &&
        _tokenController.text != text) {
      return;
    }
    _lastSyncedRevision = c.clientTokenRevision;
    if (_tokenController.text != text) {
      _suppressTokenDirtyNotify = true;
      try {
        _tokenController.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      } finally {
        _suppressTokenDirtyNotify = false;
      }
    }
    _lastAppliedTokenText = text;
    _forceApplyNextRevision = false;
    _notifyTokenDirty();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final feedback = _localizeClientAgentsMessage(
      _ephemeralFeedback,
      widget.l10n,
    );
    final feedbackError = _localizeClientAgentsMessage(
      _ephemeralError,
      widget.l10n,
    );
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
            focusNode: widget.inputFocusNode,
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
                    : () {
                        _forceApplyNextRevision = true;
                        unawaited(
                          c.saveClientAgentToken(
                            agentId: widget.agentId,
                            rawToken: _tokenController.text,
                          ),
                        );
                      },
              ),
              AppSecondaryButton(
                label: widget.l10n.clientAgentDetailServerTokenRemove,
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: isMutating || c.isOnRetryCooldown
                    ? null
                    : () {
                        _forceApplyNextRevision = true;
                        unawaited(
                          c.removeClientAgentToken(agentId: widget.agentId),
                        );
                      },
              ),
            ],
          ),
          if (feedback != null) ...<Widget>[
            SizedBox(height: widget.tokens.gapSm),
            _FeedbackInlineText(message: feedback, tone: _FeedbackTone.info),
          ],
          if (feedbackError != null) ...<Widget>[
            SizedBox(height: widget.tokens.gapSm),
            _FeedbackInlineText(
              message: feedbackError,
              tone: _FeedbackTone.error,
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
            dimension: _kStatusSpinnerSize,
            child: CircularProgressIndicator(
              strokeWidth: _kSpinnerStrokeWidth,
              color: color,
            ),
          )
        else
          Icon(icon, size: _kStatusIconSize, color: color),
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
    this.onRequestNewToken,
  });

  final String agentId;
  final ClientAgentDetailController controller;
  final AppLocalizations l10n;
  final AppThemeTokens tokens;

  /// Invoked when the user taps the in-card "Save new token" CTA after
  /// the policy reports the current token as revoked. The page wires
  /// this to scroll the token card into view and focus its input.
  final VoidCallback? onRequestNewToken;

  @override
  State<_ClientTokenPolicyCard> createState() => _ClientTokenPolicyCardState();
}

class _ClientTokenPolicyCardState extends State<_ClientTokenPolicyCard> {
  bool _hasRequested = false;
  int _lastSeenTokenRevision = -1;

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
    if (!mounted) {
      return;
    }
    final c = widget.controller;
    if (_lastSeenTokenRevision != c.clientTokenRevision) {
      _lastSeenTokenRevision = c.clientTokenRevision;
      _hasRequested = false;
    }
    if (_hasRequested) {
      return;
    }
    if (c.clientTokenStatus != ClientAgentTokenStatus.configured) {
      return;
    }
    if (c.isLoadingClientTokenPolicy) {
      return;
    }
    if (c.clientTokenPolicyError != null) {
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
        height: _kPolicyLoadingHeight,
        child: Center(
          child: SizedBox.square(
            dimension: _kPolicyLoadingSpinnerSize,
            child: CircularProgressIndicator(
              strokeWidth: _kSpinnerStrokeWidth,
              color: colors.primary,
            ),
          ),
        ),
      );
    } else if (c.clientTokenPolicyError != null) {
      body = Text(
        _localizeClientAgentsMessage(c.clientTokenPolicyError, widget.l10n) ??
            '',
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
          controller: c,
          agentId: widget.agentId,
          onRequestNewToken: widget.onRequestNewToken,
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
    this.controller,
    this.agentId,
    this.onRequestNewToken,
  });

  final ClientTokenPolicy policy;
  final AppLocalizations l10n;
  final AppThemeTokens tokens;

  /// Optional controller wiring used to render the in-card recovery
  /// CTAs ("Remove token" / "Save new token") after a revocation. When
  /// `null` the body falls back to the read-only rendering — useful
  /// for tests and for cases where the parent does not want to expose
  /// destructive actions.
  final ClientAgentDetailController? controller;
  final String? agentId;
  final VoidCallback? onRequestNewToken;

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
      // Surface the recovery shortcut right next to the revocation
      // banner so the user does not have to scroll back to the token
      // card to react. Hidden when the parent did not wire a
      // controller (tests, snapshot rendering).
      final c = controller;
      final agent = agentId;
      if (c != null && agent != null) {
        lines.add(
          _RevokedTokenRecoveryActions(
            l10n: l10n,
            tokens: tokens,
            controller: c,
            agentId: agent,
            onRequestNewToken: onRequestNewToken,
          ),
        );
      }
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

/// In-card recovery actions surfaced when `client_token.getPolicy`
/// reports the current token as revoked. Wraps two buttons:
///
/// * **Remove token** — calls
///   [ClientAgentDetailController.removeClientAgentToken], same
///   semantics as the button on the token card above. Disabled when
///   the controller is mutating or when a `Retry-After` cool-down is
///   active.
/// * **Save new token** — invokes the [onRequestNewToken] callback
///   provided by the page so the token card scrolls into view and
///   focuses its input. Hidden when no callback is wired.
class _RevokedTokenRecoveryActions extends StatelessWidget {
  const _RevokedTokenRecoveryActions({
    required this.l10n,
    required this.tokens,
    required this.controller,
    required this.agentId,
    this.onRequestNewToken,
  });

  final AppLocalizations l10n;
  final AppThemeTokens tokens;
  final ClientAgentDetailController controller;
  final String agentId;
  final VoidCallback? onRequestNewToken;

  @override
  Widget build(BuildContext context) {
    final isMutating = controller.isSavingClientToken;
    final isCooldown = controller.isOnRetryCooldown;
    final removeDisabled = isMutating || isCooldown;
    final removeLabel = isCooldown
        ? l10n.clientAgentDetailRetryAfterCountdown(
            controller.retryAfterGate.remaining?.inSeconds ?? 0,
          )
        : l10n.clientAgentDetailServerTokenRemove;
    return Padding(
      padding: EdgeInsets.only(top: tokens.gapSm),
      child: Wrap(
        spacing: tokens.gapSm,
        runSpacing: tokens.gapSm,
        children: <Widget>[
          AppSecondaryButton(
            label: removeLabel,
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: removeDisabled
                ? null
                : () => unawaited(
                    controller.removeClientAgentToken(agentId: agentId),
                  ),
          ),
          if (onRequestNewToken != null)
            AppSecondaryButton(
              label: l10n.clientAgentDetailPolicyRevokedSaveNewToken,
              icon: const Icon(Icons.edit_rounded),
              onPressed: isMutating ? null : onRequestNewToken,
            ),
        ],
      ),
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
        Icon(icon, size: _kPolicyLineIconSize, color: color),
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
            for (final entry in entries) AppTagChip(label: entry),
          ],
        ),
      ],
    );
  }
}

class _ClientAgentDetailTabSkeleton extends StatelessWidget {
  const _ClientAgentDetailTabSkeleton({required this.tokens});

  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      enabled: true,
      child: AppSectionCardWithHeading(
        title: ' ',
        child: SizedBox(height: tokens.contentSpacing * 4),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab bodies
// ---------------------------------------------------------------------------

class _ClientAgentDetailInfoTab extends StatelessWidget {
  const _ClientAgentDetailInfoTab({
    required this.agent,
    required this.l10n,
    required this.tokens,
  });

  final ClientAgent agent;
  final AppLocalizations l10n;
  final AppThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _MetadataCard(agent: agent, l10n: l10n),
        SizedBox(height: tokens.gapMd),
        _RecordCard(agent: agent, l10n: l10n),
      ],
    );
  }
}

class _ClientAgentDetailConnectionTab extends StatelessWidget {
  const _ClientAgentDetailConnectionTab({
    required this.agentId,
    required this.controller,
    required this.l10n,
    required this.tokens,
    required this.tokenCardAnchorKey,
    required this.inputFocusNode,
    required this.onRequestNewToken,
    this.onTokenDirtyChanged,
    this.tokenDiscardRevision = 0,
  });

  final String agentId;
  final ClientAgentDetailController controller;
  final AppLocalizations l10n;
  final AppThemeTokens tokens;
  final GlobalKey tokenCardAnchorKey;
  final FocusNode inputFocusNode;
  final VoidCallback onRequestNewToken;
  final ValueChanged<bool>? onTokenDirtyChanged;
  final int tokenDiscardRevision;

  @override
  Widget build(BuildContext context) {
    final status = controller.clientTokenStatus;
    final showTokenSkeleton =
        controller.isLoadingClientToken &&
        status == ClientAgentTokenStatus.unknown;
    final showMissingTokenBanner = status == ClientAgentTokenStatus.missing;
    final policyRevoked = controller.clientTokenPolicy?.revoked ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        if (showMissingTokenBanner || policyRevoked)
          Padding(
            padding: EdgeInsets.only(bottom: tokens.gapMd),
            child: _ConnectionTokenEmptyState(
              l10n: l10n,
              tokens: tokens,
              revoked: policyRevoked,
              onConfigureToken: onRequestNewToken,
            ),
          ),
        if (showTokenSkeleton)
          AppSkeleton(
            enabled: true,
            child: AppSectionCardWithHeading(
              title: ' ',
              child: SizedBox(height: tokens.contentSpacing * 3),
            ),
          )
        else
          KeyedSubtree(
            key: tokenCardAnchorKey,
            child: _AgentClientTokenCard(
              agentId: agentId,
              controller: controller,
              l10n: l10n,
              tokens: tokens,
              inputFocusNode: inputFocusNode,
              onDirtyChanged: onTokenDirtyChanged,
              discardRevision: tokenDiscardRevision,
            ),
          ),
        if (status == ClientAgentTokenStatus.configured) ...<Widget>[
          SizedBox(height: tokens.gapMd),
          _ClientTokenPolicyCard(
            agentId: agentId,
            controller: controller,
            l10n: l10n,
            tokens: tokens,
            onRequestNewToken: onRequestNewToken,
          ),
        ],
      ],
    );
  }
}

class _ConnectionTokenEmptyState extends StatelessWidget {
  const _ConnectionTokenEmptyState({
    required this.l10n,
    required this.tokens,
    required this.revoked,
    required this.onConfigureToken,
  });

  final AppLocalizations l10n;
  final AppThemeTokens tokens;
  final bool revoked;
  final VoidCallback onConfigureToken;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final title = revoked
        ? l10n.clientAgentDetailConnectionTokenRevokedTitle
        : l10n.clientAgentDetailConnectionTokenMissingTitle;
    final message = revoked
        ? l10n.clientAgentDetailConnectionTokenRevokedMessage
        : l10n.clientAgentDetailConnectionTokenMissingMessage;

    return AppSectionCardWithHeading(
      title: title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(
                revoked ? Icons.block_rounded : Icons.vpn_key_off_rounded,
                color: revoked ? colors.error : colors.onSurfaceVariant,
              ),
              SizedBox(width: tokens.gapSm),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: tokens.gapMd),
          AppSecondaryButton(
            label: l10n.clientAgentDetailConnectionTokenConfigureAction,
            icon: const Icon(Icons.edit_rounded),
            onPressed: onConfigureToken,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Cards
// ---------------------------------------------------------------------------

class _MetadataCard extends StatelessWidget {
  const _MetadataCard({required this.agent, required this.l10n});

  final ClientAgent agent;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final statusLabel = _catalogStatusLabel(l10n, agent.catalogStatus);
    final connectionLabel = _connectionLabel(l10n, agent.connectionStatus);
    final documentTypeLabel = _trimmedOrNull(agent.documentType);
    return AppSectionCardWithHeading(
      title: l10n.clientAgentDetailSectionMetadata,
      subtitle: l10n.clientAgentDetailSectionMetadataSubtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _AgentDetailRow(
            label: l10n.clientAgentFieldId,
            value: agent.agentId,
            clipboardText: agent.agentId,
          ),
          if (documentTypeLabel != null)
            _AgentDetailRow(
              label: l10n.clientAgentFieldDocumentType,
              value: documentTypeLabel,
              clipboardText: documentTypeLabel,
            ),
          _AgentDetailRow(
            label: l10n.clientAgentFieldStatus,
            value: statusLabel,
            clipboardText: statusLabel,
          ),
          _AgentDetailRow(
            label: l10n.clientAgentFieldConnection,
            value: connectionLabel,
            clipboardText: connectionLabel,
          ),
        ],
      ),
    );
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

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.agent, required this.l10n});

  final ClientAgent agent;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final na = l10n.clientAgentValueNotAvailable;
    final createdLabel = AppBrFormatters.shortDate(agent.createdAt);
    final updatedLabel = agent.updatedAt.isAfter(agent.createdAt)
        ? AppBrFormatters.shortDateTime(agent.updatedAt)
        : na;
    return AppSectionCardWithHeading(
      title: l10n.clientAgentDetailSectionRecord,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (agent.profileUpdatedAt != null)
            _AgentDetailRow(
              label: l10n.clientAgentFieldProfileUpdatedAt,
              value: AppBrFormatters.shortDateTime(agent.profileUpdatedAt!),
              clipboardText: AppBrFormatters.shortDateTime(
                agent.profileUpdatedAt!,
              ),
            ),
          _AgentDetailRow(
            label: l10n.clientAgentFieldCreatedAt,
            value: createdLabel,
            clipboardText: createdLabel,
          ),
          _AgentDetailRow(
            label: l10n.clientAgentFieldUpdatedAt,
            value: updatedLabel,
            clipboardText: updatedLabel == na ? null : updatedLabel,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared row widget
// ---------------------------------------------------------------------------

String? _trimmedOrNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) {
    return null;
  }
  return trimmed;
}

const Duration _kAgentDetailCopySnackDuration = Duration(seconds: 2);

Future<void> _copyAgentDetailFieldValue(
  BuildContext context,
  String text,
) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (!context.mounted) {
    return;
  }
  final messenger = ScaffoldMessenger.maybeOf(context);
  final l10n = AppLocalizations.of(context);
  if (messenger == null) {
    return;
  }
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      duration: _kAgentDetailCopySnackDuration,
      content: Text(l10n.clientAgentDetailCopiedSnackbar),
    ),
  );
}

class _AgentDetailRow extends StatelessWidget {
  const _AgentDetailRow({
    required this.label,
    required this.value,
    this.clipboardText,
  });

  final String label;
  final String value;
  final String? clipboardText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final typography = theme.appTypography;
    final colors = theme.appColors;
    final tokens = theme.extension<AppThemeTokens>()!;
    final l10n = AppLocalizations.of(context);
    final trimmedCopy = clipboardText?.trim();
    final copyPayload = trimmedCopy != null && trimmedCopy.isNotEmpty
        ? trimmedCopy
        : null;
    return Padding(
      padding: EdgeInsets.only(bottom: tokens.gapSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: typography.caption.copyWith(color: colors.onSurfaceVariant),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: Text(value, style: typography.body)),
              if (copyPayload != null)
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: _kCopyIconSize),
                  tooltip: l10n.clientAgentDetailCopyFieldTooltip(label),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: _kCopyTouchTargetSize,
                    minHeight: _kCopyTouchTargetSize,
                  ),
                  onPressed: () => unawaited(
                    _copyAgentDetailFieldValue(context, copyPayload),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

String? _localizeClientAgentsMessage(
  ClientAgentsPresentationMessage? message,
  AppLocalizations l10n,
) {
  if (message == null) {
    return null;
  }
  return localizeClientAgentsPresentationMessage(message, l10n);
}

enum _FeedbackTone { info, error }

/// Tiny inline feedback line used by the detail page wherever a localized
/// success/error message must render below a CTA cluster without the visual
/// weight of an [AppInlineErrorPanel] or a banner.
///
/// Centralizes the `bodySmall` + `primary`/`error` color combination that
/// previously appeared inline in the header, the token card and the policy
/// card so changes to that style happen in one place.
class _FeedbackInlineText extends StatelessWidget {
  const _FeedbackInlineText({required this.message, required this.tone});

  final String message;
  final _FeedbackTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = switch (tone) {
      _FeedbackTone.info => theme.colorScheme.primary,
      _FeedbackTone.error => theme.colorScheme.error,
    };
    return Text(
      message,
      style: theme.textTheme.bodySmall?.copyWith(color: color),
    );
  }
}
