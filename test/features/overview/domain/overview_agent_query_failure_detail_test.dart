import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/domain/agent_sql_rpc_failure_ui_key.dart';
import 'package:colmeia/features/overview/domain/entities/overview_agent_query_failure_detail.dart';
import 'package:colmeia/features/overview/domain/overview_partial_failure_details_plain_text.dart';
import 'package:colmeia/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('overviewAgentQueryFailureTechnicalSummary', () {
    test(
      'truncates very long RpcFailure reason and correlationId segments',
      () {
        final longReason = 'x' * 600;
        final longCorr = 'c' * 600;
        final failure = RpcFailure(
          message: 'm',
          userMessage: 'u',
          rpcCode: 1,
          retryable: false,
          reason: longReason,
          correlationId: longCorr,
        );
        final summary = overviewAgentQueryFailureTechnicalSummary(failure);
        expect(summary.length, lessThanOrEqualTo(4096 + 32));
        expect(summary, contains('(600 chars)'));
        expect(summary, isNot(contains(longReason)));
      },
    );

    test('caps entire technical summary length', () {
      final hugeMessage = 'z' * 5000;
      final failure = ValidationFailure(message: hugeMessage);
      final summary = overviewAgentQueryFailureTechnicalSummary(failure);
      expect(summary, endsWith('…(truncated)'));
      expect(summary.length, lessThanOrEqualTo(4096 + 16));
    });
  });

  group('overviewAppFailureDiagnosticBody', () {
    test('includes friendly line and wire diagnostic fields', () {
      const failure = ValidationFailure(
        message: 'msg',
        userMessage: 'friendly',
      );
      final body = overviewAppFailureDiagnosticBody(
        failure,
        localizedUserMessage: 'friendly',
      );
      expect(body, startsWith('userFacingMessage: friendly'));
      expect(body, contains('failureType: ValidationFailure'));
      expect(body, contains('message: msg'));
    });
  });

  group('overviewLucratividadePartialFailureDetail', () {
    test('uses lucratividade source and technical summary', () {
      const failure = ValidationFailure(message: 'm');
      final d = overviewLucratividadePartialFailureDetail(
        agentId: 'id1',
        displayName: 'N1',
        failure: failure,
      );
      expect(d.source, OverviewAgentQueryFailureSource.lucratividadePeriod);
      expect(d.agentId, 'id1');
      expect(d.displayName, 'N1');
      expect(d.userMessageFor(AppLocalizationsEn()), 'm');
      expect(d.technicalSummary, 'ValidationFailure: m');
    });
  });

  group('formatOverviewPartialFailureDetailsPlainText', () {
    test('returns empty message when details empty', () {
      final l10n = AppLocalizationsEn();
      final out = formatOverviewPartialFailureDetailsPlainText(
        details: const <OverviewAgentQueryFailureDetail>[],
        l10n: l10n,
        emptyMessage: 'EMPTY',
        sourceLabel: (_) => 'src',
        userLineLabel: 'U',
        technicalLineLabel: 'T',
      );
      expect(out, 'EMPTY');
    });

    test('formats multiple entries with separators', () {
      final l10n = AppLocalizationsEn();
      final details = <OverviewAgentQueryFailureDetail>[
        const OverviewAgentQueryFailureDetail(
          agentId: 'a',
          displayName: 'A',
          source: OverviewAgentQueryFailureSource.paymentResumo,
          failure: ValidationFailure(message: 'u1'),
        ),
        const OverviewAgentQueryFailureDetail(
          agentId: 'b',
          displayName: 'B',
          source: OverviewAgentQueryFailureSource.lucratividadePeriod,
          failure: RpcFailure(
            message: 'u2',
            userMessage: 'u2',
            rpcCode: -32013,
            retryable: false,
            context: <String, Object?>{
              AgentSqlRpcFailureUiKey.field:
                  AgentSqlRpcFailureUiKey.rateLimited,
            },
          ),
        ),
      ];
      final out = formatOverviewPartialFailureDetailsPlainText(
        details: details,
        l10n: l10n,
        emptyMessage: 'EMPTY',
        sourceLabel: (s) => s.name,
        userLineLabel: 'User',
        technicalLineLabel: 'Tech',
      );
      expect(out, contains('A (a)'));
      expect(out, contains('paymentResumo'));
      expect(out, contains('User: u1'));
      expect(out, contains('Tech: ValidationFailure: u1'));
      expect(out, contains('Tech: RpcFailure: u2'));
      expect(out, contains('---'));
      expect(out, contains('B (b)'));
      expect(out, contains('lucratividadePeriod'));
      expect(out, contains('User: ${l10n.agentSqlErrorRateLimited}'));
      expect(RegExp('Tech:').allMatches(out).length, 2);
    });
  });
}
