import 'package:colmeia/features/client_agents/domain/entities/agent_catalog_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agents_approved_agents_tab.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/widgets/pagination/app_table_pagination_footer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/localized_test_app.dart';

void main() {
  ClientAgent buildAgent(String agentId, String label) {
    return ClientAgent(
      agentId: agentId,
      name: 'Agent $label',
      catalogStatus: AgentCatalogStatus.active,
      connectionStatus: AgentConnectionStatus.online,
      createdAt: DateTime(2026, 4, 4),
      updatedAt: DateTime(2026, 4, 4),
    );
  }

  testWidgets('bulk select, confirm and queue remove access', (tester) async {
    final removedIds = <Set<String>>[];
    final l10n = lookupAppLocalizations(const Locale('pt', 'BR'));
    const agentOne = '11111111-1111-1111-8111-111111111111';
    const agentTwo = '22222222-2222-2222-8222-222222222222';

    await tester.pumpWidget(
      LocalizedTestApp(
        child: ClientAgentsApprovedAgentsTab(
          agents: <ClientAgent>[
            buildAgent(agentOne, 'One'),
            buildAgent(agentTwo, 'Two'),
          ],
          totalCount: 2,
          errorMessage: null,
          onQueueRemoveAccess: (ids) async {
            removedIds.add(ids);
          },
          onRetry: () {},
          isMutating: false,
          requestAccessTabLabel: l10n.clientAgentsTabRequestAccess,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.clientAgentsApprovedBulkSelect));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.clientAgentsApprovedBulkSelectAll));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.clientAgentsApprovedBulkRemove(2)));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.clientAgentsBulkRemoveConfirmAction));
    await tester.pumpAndSettle();

    expect(removedIds, hasLength(1));
    expect(removedIds.single, hasLength(2));
    expect(find.text(l10n.clientAgentsApprovedBulkSelect), findsOneWidget);
  });

  testWidgets('paginates approved agents with shared table footer', (
    tester,
  ) async {
    final l10n = lookupAppLocalizations(const Locale('pt', 'BR'));
    final agents = List<ClientAgent>.generate(
      12,
      (index) => buildAgent(
        'aaaaaaaa-aaaa-aaaa-8aaa-${index.toString().padLeft(12, '0')}',
        '$index',
      ),
    );

    await tester.pumpWidget(
      LocalizedTestApp(
        child: ListView(
          children: <Widget>[
            ClientAgentsApprovedAgentsTab(
              agents: agents,
              totalCount: agents.length,
              errorMessage: null,
              onQueueRemoveAccess: (_) async {},
              onRetry: () {},
              isMutating: false,
              requestAccessTabLabel: l10n.clientAgentsTabRequestAccess,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Agent 0'), findsOneWidget);
    expect(find.text('Agent 11'), findsNothing);
    expect(
      find.text(l10n.salesProdutoTendenciaFilterPageSize),
      findsOneWidget,
    );
    expect(
      find.textContaining(l10n.clientAgentsApprovedPaginationEntityLabel),
      findsOneWidget,
    );
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('page size menu opens as overlay without growing footer', (
    tester,
  ) async {
    final l10n = lookupAppLocalizations(const Locale('pt', 'BR'));
    final agents = List<ClientAgent>.generate(
      12,
      (index) => buildAgent(
        'bbbbbbbb-bbbb-bbbb-8bbb-${index.toString().padLeft(12, '0')}',
        '$index',
      ),
    );

    await tester.pumpWidget(
      LocalizedTestApp(
        child: ListView(
          children: <Widget>[
            ClientAgentsApprovedAgentsTab(
              agents: agents,
              totalCount: agents.length,
              errorMessage: null,
              onQueueRemoveAccess: (_) async {},
              onRetry: () {},
              isMutating: false,
              requestAccessTabLabel: l10n.clientAgentsTabRequestAccess,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byType(MenuAnchor),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final footerBox = tester.renderObject<RenderBox>(
      find.byType(AppTablePaginationFooter),
    );
    final heightBefore = footerBox.size.height;

    await tester.tap(
      find.descendant(
        of: find.byType(MenuAnchor),
        matching: find.text('10'),
      ),
    );
    await tester.pumpAndSettle();

    expect(footerBox.size.height, heightBefore);
    expect(find.byType(MenuItemButton), findsNWidgets(4));
  });
}
