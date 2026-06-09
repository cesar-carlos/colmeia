import 'package:colmeia/features/client_agents/domain/entities/agent_access_request_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_access_request.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agents_requests_tab.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/localized_test_app.dart';

void main() {
  ClientAgentAccessRequest buildRequest({
    required String agentName,
    AgentAccessRequestStatus status = AgentAccessRequestStatus.approved,
    DateTime? requestedAt,
  }) {
    return ClientAgentAccessRequest(
      agentId: '11111111-1111-1111-8111-111111111111',
      agentName: agentName,
      status: status,
      requestedAt: requestedAt ?? DateTime(2026, 4, 4, 10, 30),
    );
  }

  testWidgets('renders requests in table with column headers', (tester) async {
    final l10n = lookupAppLocalizations(const Locale('pt', 'BR'));

    await tester.pumpWidget(
      LocalizedTestApp(
        child: ListView(
          children: <Widget>[
            ClientAgentsRequestsTab(
              requests: <ClientAgentAccessRequest>[
                buildRequest(agentName: 'VILHENA RO'),
                buildRequest(agentName: 'PEIXOTO'),
              ],
              pendingActions: const [],
              errorMessage: null,
              pendingErrorMessage: null,
              onRetry: () {},
              isMutating: false,
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('VILHENA RO'), findsOneWidget);
    expect(find.text('PEIXOTO'), findsOneWidget);
    expect(find.text(l10n.clientAgentsRequestsColDescription), findsOneWidget);
    expect(find.text(l10n.clientAgentsRequestsColStatus), findsOneWidget);
    expect(find.text(l10n.clientAgentsRequestsColDate), findsOneWidget);
    expect(find.text(l10n.clientAgentsRequestStatusApproved), findsNWidgets(2));
    expect(
      find.text(l10n.clientAgentsRequestDescApproved),
      findsNWidgets(2),
    );
  });

  testWidgets('paginates requests with shared table footer', (tester) async {
    final l10n = lookupAppLocalizations(const Locale('pt', 'BR'));
    final requests = List<ClientAgentAccessRequest>.generate(
      12,
      (index) => buildRequest(agentName: 'Agent $index'),
    );

    await tester.pumpWidget(
      LocalizedTestApp(
        child: ListView(
          children: <Widget>[
            ClientAgentsRequestsTab(
              requests: requests,
              pendingActions: const [],
              errorMessage: null,
              pendingErrorMessage: null,
              onRetry: () {},
              isMutating: false,
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
      find.textContaining(l10n.clientAgentsRequestsPaginationEntityLabel),
      findsOneWidget,
    );
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('shows empty state when there are no requests', (tester) async {
    final l10n = lookupAppLocalizations(const Locale('pt', 'BR'));

    await tester.pumpWidget(
      LocalizedTestApp(
        child: ClientAgentsRequestsTab(
          requests: const [],
          pendingActions: const [],
          errorMessage: null,
          pendingErrorMessage: null,
          onRetry: () {},
          isMutating: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.clientAgentsNoRequestsYet), findsOneWidget);
  });
}
