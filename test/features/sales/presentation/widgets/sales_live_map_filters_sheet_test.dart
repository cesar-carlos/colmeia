import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_branch_ref.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_live_map_filters_sheet.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows company and branch on a separate branch row', (
    tester,
  ) async {
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
                ],
                availableBranches: const <SalesLiveMapBranchOption>[
                  SalesLiveMapBranchOption(
                    id: 'agent-1-1-1',
                    agentId: 'agent-1',
                    agentName: 'Agent 1',
                    codEmpresa: 1,
                    codFilial: 1,
                    registrationName: 'Branch 1',
                    city: 'Sinop',
                    uf: 'MT',
                  ),
                ],
                initialFilter: const SalesLiveMapFilter(),
                onApply: (_) {},
              ),
            );
          },
        ),
      ),
    );

    expect(find.text('Sinop/MT \u2014 Branch 1'), findsOneWidget);
    expect(find.text('Company: 1  Branch: 1'), findsOneWidget);
    expect(
      find.text('Sinop/MT - Agente Agent 1 - Empresa 1 - Filial 1'),
      findsNothing,
    );
  });

  testWidgets(
    'applies municipality detail and marker visual from the current selection',
    (tester) async {
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
                      registrationName: 'Branch with token',
                      city: 'Sinop',
                      uf: 'MT',
                    ),
                  ],
                  initialFilter: const SalesLiveMapFilter(
                    detailLevel: SalesLiveMapMapDetail.municipalities,
                    markerVisual: SalesLiveMapMarkerVisual.bubble,
                  ),
                  onApply: (filter) => appliedFilter = filter,
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Apply filters'));
      await tester.pump();

      expect(appliedFilter?.detailLevel, SalesLiveMapMapDetail.municipalities);
      expect(appliedFilter?.markerVisual, SalesLiveMapMarkerVisual.bubble);
    },
  );

  testWidgets(
    'shows fantasy as secondary info and finds branches by fantasy search',
    (tester) async {
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
                  ],
                  availableBranches: const <SalesLiveMapBranchOption>[
                    SalesLiveMapBranchOption(
                      id: 'agent-1-1-1',
                      agentId: 'agent-1',
                      agentName: 'Agent 1',
                      codEmpresa: 1,
                      codFilial: 1,
                      registrationName: 'Filial Centro',
                      fantasyName: 'Casa do Mel Centro',
                      city: 'Sinop',
                      uf: 'MT',
                    ),
                  ],
                  initialFilter: const SalesLiveMapFilter(),
                  onApply: (_) {},
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Filial Centro'), findsOneWidget);
      expect(find.text('Casa do Mel Centro'), findsOneWidget);

      await tester.enterText(find.byType(EditableText).first, 'Casa do Mel');
      await tester.pump();

      expect(find.text('Filial Centro'), findsOneWidget);
      expect(find.text('Casa do Mel Centro'), findsOneWidget);
    },
  );

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
                    registrationName: 'Branch 1',
                    city: 'Sinop',
                    uf: 'MT',
                  ),
                  SalesLiveMapBranchOption(
                    id: 'agent-2-1-2',
                    agentId: 'agent-2',
                    agentName: 'Agent 2',
                    codEmpresa: 1,
                    codFilial: 2,
                    registrationName: 'Branch 2',
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

    expect(
      appliedFilter?.selectedBranchIds,
      <SalesLiveMapBranchRef>{
        const SalesLiveMapBranchRef(
          agentId: 'agent-1',
          codEmpresa: 1,
          codFilial: 1,
        ),
      },
    );
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
