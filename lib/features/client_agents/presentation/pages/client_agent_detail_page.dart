import 'dart:async';

import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agent_detail_controller.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/presentation/localization/sync_app_localizations_mixin.dart';
import 'package:colmeia/shared/widgets/app_inline_error_panel.dart';
import 'package:colmeia/shared/widgets/app_section_card_with_heading.dart';
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
          final valueMissing = l10n.clientAgentValueNotAvailable;
          return ListView(
            padding: context.pageScrollPadding(tokens),
            children: <Widget>[
              AppShellPageIntro(
                eyebrow: l10n.clientAgentDetailEyebrow,
                title: l10n.clientAgentDetailTitle,
                subtitle: l10n.clientAgentDetailSubtitle,
              ),
              SizedBox(height: tokens.sectionSpacing),
              if (controller.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (controller.errorMessage != null)
                AppInlineErrorPanel(
                  title: l10n.clientAgentDetailLoadErrorTitle,
                  message: controller.errorMessage!,
                  onRetry: controller.reload,
                )
              else if (agent != null)
                AppSectionCardWithHeading(
                  title: agent.name,
                  subtitle: agent.tradeName ?? l10n.clientAgentsNoTradeName,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${l10n.clientAgentFieldDocument}: '
                        '${agent.registrationDocument ?? valueMissing}',
                      ),
                      Text(
                        '${l10n.clientAgentFieldEmail}: '
                        '${agent.email ?? valueMissing}',
                      ),
                      Text(
                        '${l10n.clientAgentFieldPhone}: '
                        '${agent.phone ?? agent.mobile ?? valueMissing}',
                      ),
                      Text(
                        '${l10n.clientAgentFieldCity}: '
                        '${_cityLine(l10n, agent)}',
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _cityLine(AppLocalizations l10n, ClientAgent agent) {
    final address = agent.address;
    if (address == null) {
      return l10n.clientAgentValueNotAvailable;
    }
    final label = address.shortLabel;
    if (label.isEmpty) {
      return l10n.clientAgentAddressNotProvided;
    }
    return label;
  }
}
