import 'package:colmeia/features/agent_meta/application/usecases/discover_agent_rpc_methods_use_case.dart';
import 'package:colmeia/features/agent_meta/application/usecases/load_client_token_policy_use_case.dart';
import 'package:colmeia/features/agent_meta/application/usecases/refresh_agent_profile_use_case.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/client_agents/application/usecases/get_client_agent_token_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_agent_detail_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/remove_client_agent_token_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/save_client_agent_token_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/update_client_agent_profile_use_case.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_catalog_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agent_detail_controller.dart';
import 'package:colmeia/features/client_agents/presentation/widgets/client_agent_profile_edit_card.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:colmeia/shared/design_system/app_theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/localized_test_app.dart';

class _MockAuthController extends Mock implements AuthController {}

class _MockLoadClientAgentDetailUseCase extends Mock
    implements LoadClientAgentDetailUseCase {}

class _MockUpdateClientAgentProfileUseCase extends Mock
    implements UpdateClientAgentProfileUseCase {}

class _MockGetClientAgentTokenUseCase extends Mock
    implements GetClientAgentTokenUseCase {}

class _MockSaveClientAgentTokenUseCase extends Mock
    implements SaveClientAgentTokenUseCase {}

class _MockRemoveClientAgentTokenUseCase extends Mock
    implements RemoveClientAgentTokenUseCase {}

class _MockRefreshAgentProfileUseCase extends Mock
    implements RefreshAgentProfileUseCase {}

class _MockLoadClientTokenPolicyUseCase extends Mock
    implements LoadClientTokenPolicyUseCase {}

class _MockDiscoverAgentRpcMethodsUseCase extends Mock
    implements DiscoverAgentRpcMethodsUseCase {}

ClientAgent _agent({
  required String name,
  required DateTime profileUpdatedAt,
}) {
  return ClientAgent(
    agentId: 'agent-1',
    name: name,
    tradeName: 'Trade',
    catalogStatus: AgentCatalogStatus.active,
    connectionStatus: AgentConnectionStatus.online,
    createdAt: DateTime.utc(2026, 4, 4),
    updatedAt: DateTime.utc(2026, 4, 4),
    profileUpdatedAt: profileUpdatedAt,
  );
}

void main() {
  testWidgets('keeps local edits when the agent refreshes underneath the form', (
    tester,
  ) async {
    final controller = ClientAgentDetailController(
      authController: _MockAuthController(),
      loadClientAgentDetailUseCase: _MockLoadClientAgentDetailUseCase(),
      updateClientAgentProfileUseCase: _MockUpdateClientAgentProfileUseCase(),
      getClientAgentTokenUseCase: _MockGetClientAgentTokenUseCase(),
      saveClientAgentTokenUseCase: _MockSaveClientAgentTokenUseCase(),
      removeClientAgentTokenUseCase: _MockRemoveClientAgentTokenUseCase(),
      refreshAgentProfileUseCase: _MockRefreshAgentProfileUseCase(),
      loadClientTokenPolicyUseCase: _MockLoadClientTokenPolicyUseCase(),
      discoverAgentRpcMethodsUseCase: _MockDiscoverAgentRpcMethodsUseCase(),
    );
    addTearDown(controller.dispose);

    final first = _agent(
      name: 'Server Name',
      profileUpdatedAt: DateTime.utc(2026, 4, 4, 10),
    );
    final refreshed = _agent(
      name: 'Fresh Server Name',
      profileUpdatedAt: DateTime.utc(2026, 4, 4, 11),
    );

    await tester.pumpWidget(
      LocalizedTestApp(
        child: SingleChildScrollView(
          child: Builder(
            builder: (context) {
              final tokens = Theme.of(context).extension<AppThemeTokens>()!;
              return ClientAgentProfileEditCard(
                agent: first,
                controller: controller,
                l10n: AppLocalizations.of(context),
                tokens: tokens,
              );
            },
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField).first, 'Local Edit');
    await tester.pump();

    await tester.pumpWidget(
      LocalizedTestApp(
        child: SingleChildScrollView(
          child: Builder(
            builder: (context) {
              final tokens = Theme.of(context).extension<AppThemeTokens>()!;
              return ClientAgentProfileEditCard(
                agent: refreshed,
                controller: controller,
                l10n: AppLocalizations.of(context),
                tokens: tokens,
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Local Edit'), findsOneWidget);
    expect(find.text('Fresh Server Name'), findsNothing);
  });
}
