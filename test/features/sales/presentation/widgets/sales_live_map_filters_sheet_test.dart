import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_live_map_filters_sheet.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('applies selected municipality detail and marker visual', (
    tester,
  ) async {
    SalesLiveMapFilter? appliedFilter;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: SalesLiveMapFiltersSheet(
                l10n: AppLocalizations.of(context),
                availableAgents: const <OverviewAgentOption>[
                  OverviewAgentOption(
                    agentId: 'agent-1',
                    name: 'Branch with token',
                  ),
                ],
                availableBranches: const <SalesLiveMapBranchOption>[
                  SalesLiveMapBranchOption(
                    id: 'agent-1-1-1',
                    agentId: 'agent-1',
                    agentName: 'Branch with token',
                    codEmpresa: 1,
                    codFilial: 1,
                    name: 'Branch with token',
                    city: 'Sinop',
                    uf: 'MT',
                  ),
                ],
                initialFilter: const SalesLiveMapFilter(),
                onApply: (filter) => appliedFilter = filter,
              ),
            );
          },
        ),
      ),
    );

    await tester.scrollUntilVisible(find.text('Cities'), 240);
    await tester.tap(find.text('Cities'));
    await tester.pump();
    await tester.scrollUntilVisible(find.text('Bubbles'), 240);
    await tester.tap(find.text('Bubbles'));
    await tester.pump();
    await tester.tap(find.text('Apply filters'));
    await tester.pump();

    expect(appliedFilter?.detailLevel, SalesLiveMapMapDetail.municipalities);
    expect(appliedFilter?.markerVisual, SalesLiveMapMarkerVisual.bubble);
  });

  testWidgets('applies selected branch ids and matching agent ids', (
    tester,
  ) async {
    SalesLiveMapFilter? appliedFilter;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: SalesLiveMapFiltersSheet(
                l10n: AppLocalizations.of(context),
                availableAgents: const <OverviewAgentOption>[
                  OverviewAgentOption(agentId: 'agent-1', name: 'Agent 1'),
                  OverviewAgentOption(agentId: 'agent-2', name: 'Agent 2'),
                ],
                availableBranches: const <SalesLiveMapBranchOption>[
                  SalesLiveMapBranchOption(
                    id: 'agent-1-1-1',
                    agentId: 'agent-1',
                    agentName: 'Agent 1',
                    codEmpresa: 1,
                    codFilial: 1,
                    name: 'Branch 1',
                    city: 'Sinop',
                    uf: 'MT',
                  ),
                  SalesLiveMapBranchOption(
                    id: 'agent-2-1-2',
                    agentId: 'agent-2',
                    agentName: 'Agent 2',
                    codEmpresa: 1,
                    codFilial: 2,
                    name: 'Branch 2',
                    city: 'Cuiaba',
                    uf: 'MT',
                  ),
                ],
                initialFilter: const SalesLiveMapFilter(),
                onApply: (filter) => appliedFilter = filter,
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Branch 2'));
    await tester.pump();
    await tester.tap(find.text('Apply filters'));
    await tester.pump();

    expect(appliedFilter?.selectedBranchIds, <String>{'agent-1-1-1'});
    expect(appliedFilter?.selectedAgentIds, <String>{'agent-1'});
  });

  testWidgets('does not apply when selected branch has no local token', (
    tester,
  ) async {
    var applied = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: SalesLiveMapFiltersSheet(
                l10n: AppLocalizations.of(context),
                availableAgents: const <OverviewAgentOption>[
                  OverviewAgentOption(
                    agentId: 'agent-1',
                    name: 'Branch without token',
                    missingLocalClientToken: true,
                  ),
                ],
                availableBranches: const <SalesLiveMapBranchOption>[],
                initialFilter: const SalesLiveMapFilter(
                  selectedAgentIds: <String>{'agent-1'},
                ),
                onApply: (_) => applied = true,
              ),
            );
          },
        ),
      ),
    );

    expect(
      find.text('Select at least one branch with a local token.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Apply filters'));
    await tester.pump();

    expect(applied, isFalse);
  });
}
