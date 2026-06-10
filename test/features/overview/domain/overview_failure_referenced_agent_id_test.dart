import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/overview/domain/overview_failure_referenced_agent_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'returns bridge id when failure message references a different uuid',
    () {
      const branchId = '11111111-1111-1111-1111-111111111111';
      const bridgeId = '22222222-2222-2222-2222-222222222222';
      const failure = RpcFailure(
        message: 'agent $bridgeId rejected command',
        userMessage: 'u',
        rpcCode: -32001,
        retryable: false,
      );

      expect(
        overviewFailureReferencedAgentId(
          detailAgentId: branchId,
          failure: failure,
        ),
        bridgeId,
      );
    },
  );

  test('returns null when only the branch id appears in failure text', () {
    const branchId = '11111111-1111-1111-1111-111111111111';
    const failure = ValidationFailure(
      message: 'validation failed for $branchId',
    );

    expect(
      overviewFailureReferencedAgentId(
        detailAgentId: branchId,
        failure: failure,
      ),
      isNull,
    );
  });
}
