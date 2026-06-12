import 'package:colmeia/features/agent_queries/presentation/widgets/agent_query_chart_failure_placeholder_content.dart';
import 'package:colmeia/features/overview/presentation/widgets/overview_rankings_section.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/localized_test_app.dart';

void main() {
  testWidgets('OverviewAgentRankingCard shows error panel when load fails', (
    tester,
  ) async {
    final l10n = lookupAppLocalizations(const Locale('pt', 'BR'));

    await tester.pumpWidget(
      LocalizedTestApp(
        child: OverviewAgentRankingCard(
          l10n: l10n,
          agentRankings: const [],
          loadFailed: true,
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.byType(AgentQueryChartFailurePlaceholderContent),
      findsOneWidget,
    );
    expect(find.text(l10n.overviewLoadFailedUserMessage), findsOneWidget);
  });
}
