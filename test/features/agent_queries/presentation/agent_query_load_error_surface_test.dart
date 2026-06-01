import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/agent_queries/presentation/widgets/agent_query_load_error_surface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('hasErrorFor is true when loadFailure is set', () {
    check(
      AgentQueryLoadErrorSurface.hasErrorFor(
        loadFailure: const NetworkFailure(message: 'timeout'),
      ),
    ).isTrue();
  });

  test('hasErrorFor is true when errorMessage is non-empty', () {
    check(
      AgentQueryLoadErrorSurface.hasErrorFor(errorMessage: ' Falha '),
    ).isTrue();
  });

  test('hasErrorFor is false when both are absent', () {
    check(AgentQueryLoadErrorSurface.hasErrorFor()).isFalse();
    check(AgentQueryLoadErrorSurface.hasErrorFor(errorMessage: '  ')).isFalse();
  });
}
