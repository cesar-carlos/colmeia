import 'dart:async';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/value_objects/email_address.dart';
import 'package:colmeia/features/auth/domain/entities/auth_session.dart';
import 'package:colmeia/features/auth/domain/entities/client_account_status.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/client_agents/application/usecases/approve_owner_access_request_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_managed_agents_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_owner_access_requests_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_owner_approved_clients_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/reject_owner_access_request_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/revoke_owner_client_access_use_case.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_catalog_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_connection_status.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/owner_approved_client.dart';
import 'package:colmeia/features/client_agents/domain/entities/owner_client_access_request.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agents_owner_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockAuthController extends Mock implements AuthController {}

class _MockLoadManagedAgentsUseCase extends Mock
    implements LoadManagedAgentsUseCase {}

class _MockLoadOwnerAccessRequestsUseCase extends Mock
    implements LoadOwnerAccessRequestsUseCase {}

class _MockApproveOwnerAccessRequestUseCase extends Mock
    implements ApproveOwnerAccessRequestUseCase {}

class _MockRejectOwnerAccessRequestUseCase extends Mock
    implements RejectOwnerAccessRequestUseCase {}

class _MockLoadOwnerApprovedClientsUseCase extends Mock
    implements LoadOwnerApprovedClientsUseCase {}

class _MockRevokeOwnerClientAccessUseCase extends Mock
    implements RevokeOwnerClientAccessUseCase {}

ClientAgent _managedAgent(String agentId) {
  return ClientAgent(
    agentId: agentId,
    name: 'Managed $agentId',
    catalogStatus: AgentCatalogStatus.active,
    connectionStatus: AgentConnectionStatus.online,
    createdAt: DateTime.utc(2026, 4, 4),
    updatedAt: DateTime.utc(2026, 4, 4),
  );
}

OwnerApprovedClient _approvedClient(String id) {
  return OwnerApprovedClient(clientId: id, clientName: 'Client $id');
}

void main() {
  late _MockAuthController authController;
  late _MockLoadManagedAgentsUseCase loadManagedAgents;
  late _MockLoadOwnerAccessRequestsUseCase loadOwnerAccessRequests;
  late _MockApproveOwnerAccessRequestUseCase approveRequest;
  late _MockRejectOwnerAccessRequestUseCase rejectRequest;
  late _MockLoadOwnerApprovedClientsUseCase loadApprovedClients;
  late _MockRevokeOwnerClientAccessUseCase revokeClientAccess;
  late ClientAgentsOwnerController controller;

  final session = AuthSession(
    userId: 'owner-1',
    email: EmailAddress('owner@example.com'),
    accessToken: 'token',
    refreshToken: 'refresh',
    expiresAt: DateTime(2099),
    accountStatus: ClientAccountStatus.active,
  );

  setUp(() {
    authController = _MockAuthController();
    loadManagedAgents = _MockLoadManagedAgentsUseCase();
    loadOwnerAccessRequests = _MockLoadOwnerAccessRequestsUseCase();
    approveRequest = _MockApproveOwnerAccessRequestUseCase();
    rejectRequest = _MockRejectOwnerAccessRequestUseCase();
    loadApprovedClients = _MockLoadOwnerApprovedClientsUseCase();
    revokeClientAccess = _MockRevokeOwnerClientAccessUseCase();
    when(() => authController.session).thenReturn(session);

    controller = ClientAgentsOwnerController(
      authController: authController,
      loadManagedAgentsUseCase: loadManagedAgents,
      loadOwnerAccessRequestsUseCase: loadOwnerAccessRequests,
      approveOwnerAccessRequestUseCase: approveRequest,
      rejectOwnerAccessRequestUseCase: rejectRequest,
      loadOwnerApprovedClientsUseCase: loadApprovedClients,
      revokeOwnerClientAccessUseCase: revokeClientAccess,
    );
  });

  tearDown(() {
    controller.dispose();
  });

  test('ignores stale approved-clients response after switching selection again', () async {
    when(() => loadManagedAgents(userId: any(named: 'userId'))).thenAnswer(
      (_) async => Success<List<ClientAgent>, AppFailure>(
        <ClientAgent>[_managedAgent('agent-a'), _managedAgent('agent-b')],
      ),
    );
    when(
      () => loadOwnerAccessRequests(userId: any(named: 'userId')),
    ).thenAnswer(
      (_) async =>
          const Success<List<OwnerClientAccessRequest>, AppFailure>(<OwnerClientAccessRequest>[]),
    );
    when(
      () => loadApprovedClients(
        userId: any(named: 'userId'),
        agentId: 'agent-a',
      ),
    ).thenAnswer(
      (_) async => Success<List<OwnerApprovedClient>, AppFailure>(
        <OwnerApprovedClient>[_approvedClient('initial-a')],
      ),
    );

    await controller.initialize();

    final staleB = Completer<AppResult<List<OwnerApprovedClient>>>();
    final freshA = Completer<AppResult<List<OwnerApprovedClient>>>();
    when(
      () => loadApprovedClients(
        userId: any(named: 'userId'),
        agentId: 'agent-b',
      ),
    ).thenAnswer((_) => staleB.future);
    when(
      () => loadApprovedClients(
        userId: any(named: 'userId'),
        agentId: 'agent-a',
      ),
    ).thenAnswer((_) => freshA.future);

    unawaited(controller.selectManagedAgent('agent-b'));
    await Future<void>.delayed(Duration.zero);
    unawaited(controller.selectManagedAgent('agent-a'));
    await Future<void>.delayed(Duration.zero);

    staleB.complete(
      Success<List<OwnerApprovedClient>, AppFailure>(
        <OwnerApprovedClient>[_approvedClient('stale-b')],
      ),
    );
    await Future<void>.delayed(Duration.zero);

    freshA.complete(
      Success<List<OwnerApprovedClient>, AppFailure>(
        <OwnerApprovedClient>[_approvedClient('fresh-a')],
      ),
    );
    await Future<void>.delayed(Duration.zero);

    expect(controller.selectedManagedAgentId, 'agent-a');
    expect(controller.approvedClients.single.clientId, 'fresh-a');
  });
}
