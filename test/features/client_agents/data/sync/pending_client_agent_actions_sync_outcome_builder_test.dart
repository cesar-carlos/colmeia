import 'package:colmeia/features/client_agents/data/sync/pending_client_agent_actions_sync_outcome_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PendingClientAgentActionsSyncOutcomeBuilder', () {
    test('empty builder yields an empty SyncPendingAgentActionsResult', () {
      final result = PendingClientAgentActionsSyncOutcomeBuilder().build();

      expect(result.successfulRequestAccessAgentIds, isEmpty);
      expect(result.successfulRemoveAccessAgentIds, isEmpty);
      expect(result.failedRequestAccessAgentIds, isEmpty);
      expect(result.failedRemoveAccessAgentIds, isEmpty);
      expect(result.requestAccessPollAgentIds, isEmpty);
      expect(result.requestAccessAlreadyApprovedAgentIds, isEmpty);
      expect(result.requestAccessDebouncedAgentIds, isEmpty);
      expect(result.requestAccessNewRequestsAgentIds, isEmpty);
    });

    test('recordRequestAccessSuccess routes flags to the right buckets', () {
      final builder = PendingClientAgentActionsSyncOutcomeBuilder()
        ..recordRequestAccessSuccess(
          actionId: 'action-1',
          agentId: 'agent-1',
          shouldPollApproval: true,
          alreadyApproved: false,
          debounced: false,
          isNewRequest: true,
        )
        ..recordRequestAccessSuccess(
          actionId: 'action-2',
          agentId: 'agent-2',
          shouldPollApproval: false,
          alreadyApproved: true,
          debounced: true,
          isNewRequest: false,
        );

      expect(builder.successfulActionIds, {'action-1', 'action-2'});
      final result = builder.build();
      expect(result.successfulRequestAccessAgentIds, {'agent-1', 'agent-2'});
      expect(result.requestAccessPollAgentIds, {'agent-1'});
      expect(result.requestAccessNewRequestsAgentIds, {'agent-1'});
      expect(result.requestAccessAlreadyApprovedAgentIds, {'agent-2'});
      expect(result.requestAccessDebouncedAgentIds, {'agent-2'});
    });

    test('recordRequestAccessFailure does not promote to the success bucket',
        () {
      final builder = PendingClientAgentActionsSyncOutcomeBuilder()
        ..recordRequestAccessFailure('agent-1')
        ..recordRequestAccessFailure('agent-1')
        ..recordRequestAccessFailure('agent-2');

      final result = builder.build();
      expect(result.failedRequestAccessAgentIds, {'agent-1', 'agent-2'});
      expect(result.successfulRequestAccessAgentIds, isEmpty);
      expect(builder.successfulActionIds, isEmpty);
    });

    test('remove-access success accumulates on the right buckets', () {
      final builder = PendingClientAgentActionsSyncOutcomeBuilder()
        ..recordRemoveAccessSuccess(actionId: 'r-1', agentId: 'a-1')
        ..recordRemoveAccessSuccess(actionId: 'r-2', agentId: 'a-2');

      expect(builder.successfulActionIds, {'r-1', 'r-2'});
      expect(builder.successfulRemoveAccessAgentIds, {'a-1', 'a-2'});
      final result = builder.build();
      expect(result.successfulRemoveAccessAgentIds, {'a-1', 'a-2'});
      expect(result.failedRemoveAccessAgentIds, isEmpty);
    });

    test('remove-access failure does not touch success buckets', () {
      final builder = PendingClientAgentActionsSyncOutcomeBuilder()
        ..recordRemoveAccessFailure('a-1');

      final result = builder.build();
      expect(result.failedRemoveAccessAgentIds, {'a-1'});
      expect(result.successfulRemoveAccessAgentIds, isEmpty);
      expect(builder.successfulActionIds, isEmpty);
    });

    test('counts mirror the underlying sets', () {
      final builder = PendingClientAgentActionsSyncOutcomeBuilder()
        ..recordRequestAccessSuccess(
          actionId: 'a',
          agentId: 'agent-a',
          shouldPollApproval: true,
          alreadyApproved: false,
          debounced: false,
          isNewRequest: true,
        )
        ..recordRequestAccessFailure('agent-b')
        ..recordRemoveAccessSuccess(actionId: 'rm', agentId: 'agent-c')
        ..recordRemoveAccessFailure('agent-d');

      expect(builder.successfulRequestAccessCount, 1);
      expect(builder.failedRequestAccessCount, 1);
      expect(builder.successfulRemoveAccessCount, 1);
      expect(builder.failedRemoveAccessCount, 1);
      expect(builder.requestAccessPollCount, 1);
      expect(builder.requestAccessNewRequestsCount, 1);
    });

    test('successfulActionIds getter exposes a defensive copy', () {
      final builder = PendingClientAgentActionsSyncOutcomeBuilder()
        ..recordRequestAccessSuccess(
          actionId: 'a',
          agentId: 'agent-a',
          shouldPollApproval: false,
          alreadyApproved: false,
          debounced: false,
          isNewRequest: false,
        );

      final snapshot = builder.successfulActionIds;
      expect(() => snapshot.add('mutated'), throwsUnsupportedError);
    });

    test('build is idempotent — multiple builds emit identical sets', () {
      final builder = PendingClientAgentActionsSyncOutcomeBuilder()
        ..recordRequestAccessSuccess(
          actionId: 'a',
          agentId: 'agent-a',
          shouldPollApproval: true,
          alreadyApproved: false,
          debounced: false,
          isNewRequest: true,
        )
        ..recordRemoveAccessSuccess(actionId: 'r', agentId: 'agent-r');

      final first = builder.build();
      final second = builder.build();
      expect(
        first.successfulRequestAccessAgentIds,
        second.successfulRequestAccessAgentIds,
      );
      expect(
        first.successfulRemoveAccessAgentIds,
        second.successfulRemoveAccessAgentIds,
      );
    });
  });
}
