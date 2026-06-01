import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/entities/agent_query_execution_participant.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_query_failure_detail.dart';
import 'package:colmeia/features/overview/domain/overview_agent_query_failure_mapper.dart';
import 'package:colmeia/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('overviewPartialFailuresFromParticipants', () {
    test('returns empty when no failures', () {
      final participants = <AgentQueryExecutionParticipant<String>>[
        const AgentQueryExecutionParticipant<String>(
          agentId: 'a1',
          displayName: 'Agent One',
          rows: <String>[],
          elapsedMs: 10,
        ),
      ];

      expect(overviewPartialFailuresFromParticipants(participants), isEmpty);
    });

    test('maps participant with ValidationFailure', () {
      const failure = ValidationFailure(
        message: 'technical',
        userMessage: 'User sees this',
      );
      final participants = <AgentQueryExecutionParticipant<String>>[
        const AgentQueryExecutionParticipant<String>(
          agentId: 'a1',
          displayName: 'Agent One',
          rows: <String>[],
          elapsedMs: 10,
          failure: failure,
        ),
      ];

      final details = overviewPartialFailuresFromParticipants(participants);
      expect(details, hasLength(1));
      final d = details.single;
      expect(d.agentId, 'a1');
      expect(d.displayName, 'Agent One');
      expect(d.source, OverviewAgentQueryFailureSource.paymentResumo);
      expect(d.userMessageFor(AppLocalizationsEn()), 'User sees this');
      expect(
        d.technicalSummary,
        'ValidationFailure: technical',
      );
    });

    test('maps RpcFailure technical summary with rpc fields', () {
      const failure = RpcFailure(
        message: 'rpc-msg',
        userMessage: 'rpc-user',
        rpcCode: 42,
        retryable: false,
        reason: 'busy',
        correlationId: 'corr-1',
      );
      final participants = <AgentQueryExecutionParticipant<int>>[
        const AgentQueryExecutionParticipant<int>(
          agentId: 'b2',
          displayName: 'Agent Two',
          rows: <int>[],
          elapsedMs: 5,
          failure: failure,
        ),
      ];

      final details = overviewPartialFailuresFromParticipants(participants);
      expect(details.single.userMessageFor(AppLocalizationsEn()), 'rpc-user');
      expect(
        details.single.technicalSummary,
        'RpcFailure: rpc-msg | rpcCode=42 | reason=busy | correlationId=corr-1',
      );
    });

    test('skips null failure and collects multiple failures', () {
      final participants = <AgentQueryExecutionParticipant<String>>[
        const AgentQueryExecutionParticipant<String>(
          agentId: 'ok',
          displayName: 'OK',
          rows: <String>[],
          elapsedMs: 1,
        ),
        const AgentQueryExecutionParticipant<String>(
          agentId: 'bad',
          displayName: 'Bad',
          rows: <String>[],
          elapsedMs: 2,
          failure: ValidationFailure(message: 'm'),
        ),
      ];

      final details = overviewPartialFailuresFromParticipants(participants);
      expect(details, hasLength(1));
      expect(details.single.agentId, 'bad');
    });
  });
}
