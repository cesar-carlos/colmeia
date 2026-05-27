import 'package:colmeia/features/client_agents/data/sync/pending_client_agent_actions_view.dart';
import 'package:colmeia/features/client_agents/domain/entities/pending_agent_action.dart';
import 'package:flutter_test/flutter_test.dart';

PendingAgentAction _action(
  String id, {
  PendingAgentActionState state = PendingAgentActionState.queued,
  String? agentId,
  String? errorMessage,
}) {
  return PendingAgentAction(
    id: id,
    agentId: agentId ?? 'agent-$id',
    type: PendingAgentActionType.requestAccess,
    state: state,
    createdAt: DateTime(2026),
    attemptCount: 0,
    errorMessage: errorMessage,
  );
}

void main() {
  group('PendingClientAgentActionsView', () {
    test('toList preserves the initial entries', () {
      final view = PendingClientAgentActionsView([
        _action('a'),
        _action('b'),
      ]);

      expect(view.toList().map((a) => a.id), <String>['a', 'b']);
    });

    test('operator [] returns null for unknown ids', () {
      final view = PendingClientAgentActionsView([_action('a')]);

      expect(view['missing'], isNull);
      expect(view['a'], isNotNull);
    });

    test('update applies the mutator only to the matching id', () {
      final view = PendingClientAgentActionsView([
        _action('a'),
        _action('b'),
      ])
        ..update(
          'a',
          (a) => a.copyWith(
            state: PendingAgentActionState.syncing,
            errorMessage: 'updated',
          ),
        );

      expect(view['a']!.state, PendingAgentActionState.syncing);
      expect(view['a']!.errorMessage, 'updated');
      expect(view['b']!.state, PendingAgentActionState.queued);
    });

    test('update is a no-op when the id is not in the view', () {
      final view = PendingClientAgentActionsView([_action('a')])
        ..update('missing', (a) => a.copyWith(errorMessage: 'should not run'));

      expect(view['a']!.errorMessage, isNull);
      expect(view.toList(), hasLength(1));
    });

    test('updateAll mutates every id in the iterable', () {
      final view = PendingClientAgentActionsView([
        _action('a'),
        _action('b'),
        _action('c'),
      ])
        ..updateAll(
          const <String>['a', 'c'],
          (a) => a.copyWith(state: PendingAgentActionState.failed),
        );

      expect(view['a']!.state, PendingAgentActionState.failed);
      expect(view['b']!.state, PendingAgentActionState.queued);
      expect(view['c']!.state, PendingAgentActionState.failed);
    });

    test('removeIds drops the matching entries and keeps the others', () {
      final view = PendingClientAgentActionsView([
        _action('a'),
        _action('b'),
        _action('c'),
      ])
        ..removeIds(const <String>['a', 'missing', 'c']);

      expect(view.toList().map((a) => a.id), <String>['b']);
    });
  });
}
