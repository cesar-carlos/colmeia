import 'dart:async';

import 'package:colmeia/app/router/app_navigation.dart';
import 'package:colmeia/app/router/app_routes.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agent_detail_controller.dart';
import 'package:colmeia/features/client_agents/presentation/models/client_agents_presentation_message.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agent_detail_feedback_text.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agent_detail_tabs.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agent_detail_visual_tokens.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agent_profile_edit_card.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agent_unsaved_changes_dialog.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/actions/app_secondary_button.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:colmeia/shared/widgets/navigation/app_tab_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
        duration: kClientAgentDetailRefreshScrollDuration,
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
          final loadErrorMessage = localizeClientAgentDetailPresentationMessage(
            controller.errorMessage,
            l10n,
          );
          final refreshFromAgentNotice =
              localizeClientAgentDetailPresentationMessage(
                _refreshFromAgentNotice,
                l10n,
              );
          final refreshFromAgentError =
              localizeClientAgentDetailPresentationMessage(
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
                              ClientAgentDetailFeedbackText(
                                message: refreshFromAgentNotice,
                                tone: ClientAgentDetailFeedbackTone.info,
                              ),
                            ],
                            if (refreshFromAgentError != null) ...<Widget>[
                              SizedBox(height: tokens.gapSm),
                              ClientAgentDetailFeedbackText(
                                message: refreshFromAgentError,
                                tone: ClientAgentDetailFeedbackTone.error,
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
                            ? ClientAgentDetailTabSkeleton(tokens: tokens)
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
                            ? ClientAgentDetailTabSkeleton(tokens: tokens)
                            : ClientAgentDetailInfoTab(
                                agent: agent!,
                                l10n: l10n,
                                tokens: tokens,
                              ),
                      ),
                      AppTabViewItem(
                        label: l10n.clientAgentDetailTabConnection,
                        child: initialTabSkeletons
                            ? ClientAgentDetailTabSkeleton(tokens: tokens)
                            : ClientAgentDetailConnectionTab(
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
}
