import 'dart:async';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_access_requests_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_access_status_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_agent_detail_use_case.dart';
import 'package:colmeia/features/client_agents/application/usecases/load_client_approved_agents_use_case.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_access_request.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_query.dart';
import 'package:colmeia/features/client_agents/domain/entities/paginated_result.dart';
import 'package:colmeia/features/client_agents/presentation/controllers/client_agents_approval_polling_coordinator.dart';
import 'package:colmeia/features/client_agents/presentation/models/client_agents_presentation_message.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:result_dart/result_dart.dart';

class _MockLoadAccessRequestsUseCase extends Mock
    implements LoadClientAccessRequestsUseCase {}

class _MockLoadClientAgentDetailUseCase extends Mock
    implements LoadClientAgentDetailUseCase {}

class _MockLoadClientAccessStatusUseCase extends Mock
    implements LoadClientAccessStatusUseCase {}

class _MockLoadApprovedAgentsUseCase extends Mock
    implements LoadClientApprovedAgentsUseCase {}

class _FakeHost implements ClientAgentsApprovalPollingHost {
  _FakeHost({required this.userId});

  bool disposed = false;
  final String userId;
  @override
  bool isBusy = false;

  @override
  bool get isDisposed => disposed;
  @override
  PaginatedResult<ClientAgent>? approvedAgentsSnapshot;
  @override
  PaginatedResult<ClientAgentAccessRequest>? accessRequestsSnapshot;
  int hostMutationCount = 0;

  @override
  String? get currentUserId => disposed ? null : userId;

  @override
  ClientAgentAccessRequest? accessRequestForAgentId(String agentId) => null;

  @override
  void invalidateTargetResolution({required String userId}) {}

  @override
  void notifyApprovalPollingChanged() {
    if (!disposed) {
      hostMutationCount++;
    }
  }

  @override
  void replaceAccessRequests(PaginatedResult<ClientAgentAccessRequest> value) {
    if (disposed) {
      return;
    }
    accessRequestsSnapshot = value;
    hostMutationCount++;
  }

  @override
  void replaceApprovedAgents(PaginatedResult<ClientAgent> value) {
    if (disposed) {
      return;
    }
    approvedAgentsSnapshot = value;
    hostMutationCount++;
  }

  @override
  void scheduleLocalTokenServerFlush({
    required String userId,
    required Iterable<String> agentIds,
  }) {}

  @override
  void setAccessRequestsError(ClientAgentsPresentationMessage? error) {}

  @override
  void setActionFeedback({
    required ClientAgentsPresentationMessage message,
    required ClientAgentsActionFeedbackKind kind,
  }) {}

  @override
  void setApprovedAgentsError(ClientAgentsPresentationMessage? error) {}

  @override
  void upsertApprovedAgentsInMemory(List<ClientAgent> agents) {
    if (disposed) {
      return;
    }
    hostMutationCount++;
  }
}

void main() {
  late _MockLoadAccessRequestsUseCase loadAccessRequestsUseCase;
  late _MockLoadClientAgentDetailUseCase loadClientAgentDetailUseCase;
  late _MockLoadClientAccessStatusUseCase loadClientAccessStatusUseCase;
  late _MockLoadApprovedAgentsUseCase loadApprovedAgentsUseCase;
  late _FakeHost host;

  setUpAll(() {
    registerFallbackValue(const PaginatedQuery());
  });

  setUp(() {
    loadAccessRequestsUseCase = _MockLoadAccessRequestsUseCase();
    loadClientAgentDetailUseCase = _MockLoadClientAgentDetailUseCase();
    loadClientAccessStatusUseCase = _MockLoadClientAccessStatusUseCase();
    loadApprovedAgentsUseCase = _MockLoadApprovedAgentsUseCase();
    host = _FakeHost(userId: 'user-1');
  });

  test(
    'dispose during poll does not mutate host after await completes',
    () async {
      final requestsCompleter =
          Completer<AppResult<PaginatedResult<ClientAgentAccessRequest>>>();
      when(
        () => loadAccessRequestsUseCase(
          userId: any(named: 'userId'),
          query: any(named: 'query'),
        ),
      ).thenAnswer((_) async => requestsCompleter.future);
      when(
        () => loadClientAgentDetailUseCase(
          userId: any(named: 'userId'),
          agentId: any(named: 'agentId'),
        ),
      ).thenAnswer(
        (_) async => const Failure<ClientAgent, AppFailure>(
          UnknownFailure(message: 'not yet'),
        ),
      );

      final coordinator = ClientAgentsApprovalPollingCoordinator(
        host: host,
        loadAccessRequestsUseCase: loadAccessRequestsUseCase,
        loadClientAgentDetailUseCase: loadClientAgentDetailUseCase,
        loadClientAccessStatusUseCase: loadClientAccessStatusUseCase,
        loadApprovedAgentsUseCase: loadApprovedAgentsUseCase,
        pollingInterval: const Duration(hours: 1),
      );

      coordinator.startPolling(
        userId: host.userId,
        agentIds: <String>{'agent-1'},
      );

      await Future<void>.delayed(Duration.zero);
      host.disposed = true;
      requestsCompleter.complete(
        const Success<PaginatedResult<ClientAgentAccessRequest>, AppFailure>(
          PaginatedResult<ClientAgentAccessRequest>(
            items: <ClientAgentAccessRequest>[],
            count: 0,
            total: 0,
            page: 1,
            pageSize: 50,
          ),
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));
      coordinator.dispose();

      expect(host.hostMutationCount, 0);
    },
  );
}
