import 'dart:async';

import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/features/sales/data/sales_preferences.dart';
import 'package:colmeia/features/sales/domain/load_available_agents_for_sales.dart';
import 'package:colmeia/features/sales/domain/sales_card_descriptor.dart';
import 'package:colmeia/features/sales/presentation/utils/reconcile_selected_sales_agent_id.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_hub_card.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_single_agent_picker_control.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SalesHubPage extends StatefulWidget {
  const SalesHubPage({super.key});

  @override
  State<SalesHubPage> createState() => _SalesHubPageState();
}

class _SalesHubPageState extends State<SalesHubPage> {
  late final SalesPreferences _prefs;
  late final LoadAvailableAgentsForSales _loadAgentsUseCase;
  String? _selectedAgentId;
  List<OverviewAgentOption> _availableAgents = <OverviewAgentOption>[];

  @override
  void initState() {
    super.initState();
    _prefs = getIt<SalesPreferences>();
    _loadAgentsUseCase = getIt<LoadAvailableAgentsForSales>();
    _selectedAgentId = _prefs.selectedAgentId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadAgents());
    });
  }

  Future<void> _loadAgents() async {
    final auth = context.read<AuthController>();
    final userId = auth.session?.userId;
    if (userId == null) {
      return;
    }

    final agents = await _loadAgentsUseCase(userId);
    if (!mounted) {
      return;
    }

    final authAfter = context.read<AuthController>();
    if (authAfter.session?.userId != userId) {
      return;
    }

    setState(() {
      _availableAgents = agents;
      final nextSelection = reconcileSelectedSalesAgentId(
        agents: agents,
        previousSelectedId: _selectedAgentId,
      );
      if (nextSelection != _selectedAgentId) {
        _selectedAgentId = nextSelection;
        unawaited(_prefs.setSelectedAgentId(nextSelection));
      }
    });
  }

  void _onAgentChanged(String agentId) {
    setState(() => _selectedAgentId = agentId);
    unawaited(_prefs.setSelectedAgentId(agentId));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;

    return SingleChildScrollView(
      padding: context.pageScrollPadding(tokens),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppShellPageIntro(
            sectionLabel: l10n.shellNavSalesLabel,
            title: l10n.salesHubTitle,
            subtitle: l10n.salesHubSubtitle,
          ),
          SizedBox(height: tokens.sectionSpacing),
          SalesSingleAgentPickerControl(
            l10n: l10n,
            availableAgents: _availableAgents,
            selectedAgentId: _selectedAgentId,
            onSelectionChanged: _onAgentChanged,
          ),
          SizedBox(height: tokens.sectionSpacing),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 600;
              final cols = isWide ? 4 : 2;
              final gap = tokens.gapMd;

              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: allSalesCards.map((card) {
                  final width =
                      ((constraints.maxWidth - (gap * (cols - 1))) / cols)
                          .floorToDouble();
                  return SizedBox(
                    width: width,
                    child: SalesHubCard(
                      icon: card.icon,
                      label: _getCardTitle(l10n, card.l10nTitleKey),
                      onTap: () => context.go(card.route),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  String _getCardTitle(AppLocalizations l10n, String key) {
    return switch (key) {
      'salesCardOpenAccountsTitle' => l10n.salesCardOpenAccountsTitle,
      'salesCardPaidAccountsTitle' => l10n.salesCardPaidAccountsTitle,
      'salesCardPaymentHistoryTitle' => l10n.salesCardPaymentHistoryTitle,
      'salesCardNewPaymentTitle' => l10n.salesCardNewPaymentTitle,
      'salesCardProdutoRankLucroTitle' => l10n.salesCardProdutoRankLucroTitle,
      _ => key,
    };
  }
}
