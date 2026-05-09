import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/features/overview/domain/entities/overview_filter.dart';
import 'package:colmeia/features/sales/domain/entities/sales_live_map_filter.dart';
import 'package:colmeia/features/sales/presentation/widgets/sales_live_map_filters_sheet.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
