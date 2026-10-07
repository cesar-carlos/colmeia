import 'package:colmeia/features/agent_queries/domain/entities/agent_query_diagnostics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'completion freezes diagnostics against late results and scope disposal',
    () {
      final diagnostics = AgentQueryDiagnostics()
        ..attempts = 1
        ..route('rest')
        ..mark('first_response')
        ..complete();
      final snapshot = diagnostics.toJson();
      diagnostics
        ..cancelled = true
        ..attempts = 2
        ..route('relay')
        ..addDuration('decode', const Duration(seconds: 10))
        ..agentPhases({'late': 10000});
      expect(diagnostics.toJson(), snapshot);
      expect((snapshot['phasesMs']! as Map).containsKey('complete'), true);
    },
  );

  test('relay streaming and unary modes do not imply transport fallback', () {
    final diagnostics = AgentQueryDiagnostics()
      ..route('relay_streaming')
      ..route('relay');
    expect(diagnostics.toJson()['fallback'], false);
    diagnostics.route('rest');
    expect(diagnostics.toJson()['fallback'], true);
    expect(diagnostics.toJson()['transport'], 'rest');
  });
}
