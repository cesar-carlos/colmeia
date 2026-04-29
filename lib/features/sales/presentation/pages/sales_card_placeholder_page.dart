import 'dart:async';

import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/layout/app_responsive_spacing.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/features/sales/data/sales_preferences.dart';
import 'package:colmeia/features/sales/domain/load_available_agents_for_sales.dart';
import 'package:colmeia/features/sales/domain/sales_card_descriptor.dart';
import 'package:colmeia/features/sales/presentation/utils/reconcile_selected_sales_agent_id.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_agent_required_gate.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_single_agent_picker_control.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:colmeia/shared/widgets/app_section_card.dart';
import 'package:colmeia/shared/widgets/navigation/app_shell_page_intro.dart';
import 'package:colmeia/shared/widgets/reports/app_report_inline_filters_bar.dart';
import 'package:colmeia/shared/widgets/reports/app_report_models.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SalesCardPlaceholderPage extends StatefulWidget {
  const SalesCardPlaceholderPage({
    required this.cardDescriptor,
    super.key,
  });

  final SalesCardDescriptor cardDescriptor;

  @override
  State<SalesCardPlaceholderPage> createState() =>
      _SalesCardPlaceholderPageState();
}

class _SalesCardPlaceholderPageState extends State<SalesCardPlaceholderPage> {
  late final SalesPreferences _prefs;
  late final LoadAvailableAgentsForSales _loadAgentsUseCase;
  String? _selectedAgentId;
  List<OverviewAgentOption> _availableAgents = <OverviewAgentOption>[];
  Map<String, Object?> _filters = <String, Object?>{};

  @override
  void initState() {
    super.initState();
    _prefs = getIt<SalesPreferences>();
    _loadAgentsUseCase = getIt<LoadAvailableAgentsForSales>();
    _selectedAgentId = _prefs.selectedAgentId;
    _filters = _prefs.restoreCardFilters(widget.cardDescriptor.id);
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

  void _onFiltersChanged(Map<String, Object?> filters) {
    setState(() => _filters = filters);
    unawaited(
      _prefs.persistCardFilters(widget.cardDescriptor.id, filters),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = Theme.of(context).extension<AppThemeTokens>()!;
    final cardTitle = _getCardTitle(l10n, widget.cardDescriptor.l10nTitleKey);

    return SingleChildScrollView(
      padding: context.pageScrollPadding(tokens),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AppShellPageIntro(
            sectionLabel: l10n.shellNavSalesLabel,
            title: cardTitle,
            subtitle: l10n.salesHubSubtitle,
          ),
          SizedBox(height: tokens.sectionSpacing),
          SalesSingleAgentPickerControl(
            l10n: l10n,
            availableAgents: _availableAgents,
            selectedAgentId: _selectedAgentId,
            onSelectionChanged: _onAgentChanged,
          ),
          SizedBox(height: tokens.gapMd),
          AppReportInlineFiltersBar(
            filters: const <AppReportFilterDescriptor>[],
            initialValues: _filters,
            onFiltersChanged: _onFiltersChanged,
          ),
          SizedBox(height: tokens.sectionSpacing),
          SalesAgentRequiredGate(
            selectedAgentId: _selectedAgentId,
            child: AppSectionCard(
              child: Padding(
                padding: EdgeInsets.all(tokens.contentSpacing),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.shellPlaceholderUnderConstructionTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: tokens.gapMd),
                    Text(
                      l10n.shellPlaceholderUnderConstructionBody,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
      _ => key,
    };
  }
}
