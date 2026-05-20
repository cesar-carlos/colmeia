import 'package:colmeia/features/agent_meta/application/usecases/discover_agent_rpc_methods_use_case.dart';
import 'package:colmeia/features/agent_meta/application/usecases/load_client_token_policy_use_case.dart';
import 'package:colmeia/features/agent_meta/application/usecases/refresh_agent_profile_use_case.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/client_agents/application/usecases/get_client_agent_token_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_agent_detail_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/remove_client_agent_token_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/save_client_agent_token_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/update_client_agent_profile_use_case.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agent_detail_controller.dart';
import 'package:colmeia/features/client_agents/presentation/pages/client_agent_detail_page.dart';
import 'package:colmeia/l10n/app_localizations_pt.dart';
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

void main() {
  testWidgets('localizes typed controller errors on the detail page', (
    tester,
  ) async {
    final authController = _MockAuthController();
    when(() => authController.session).thenReturn(null);

    final controller = ClientAgentDetailController(
      authController: authController,
      loadClientAgentDetailUseCase: _MockLoadClientAgentDetailUseCase(),
      updateClientAgentProfileUseCase: _MockUpdateClientAgentProfileUseCase(),
      getClientAgentTokenUseCase: _MockGetClientAgentTokenUseCase(),
      saveClientAgentTokenUseCase: _MockSaveClientAgentTokenUseCase(),
      removeClientAgentTokenUseCase: _MockRemoveClientAgentTokenUseCase(),
      refreshAgentProfileUseCase: _MockRefreshAgentProfileUseCase(),
      loadClientTokenPolicyUseCase: _MockLoadClientTokenPolicyUseCase(),
      discoverAgentRpcMethodsUseCase: _MockDiscoverAgentRpcMethodsUseCase(),
    );

    await tester.pumpWidget(
      LocalizedTestApp(
        child: ClientAgentDetailPage(
          agentId: '11111111-1111-1111-8111-111111111111',
          controller: controller,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text(AppLocalizationsPt().clientAgentDetailSessionUnavailable),
      findsOneWidget,
    );
  });
}
