import 'package:colmeia/core/observability/socket/agent_phase_timings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('should tolerate missing or structurally invalid phases', () {
    expect(AgentPhaseTimings.tryParse(null), isNull);
    expect(AgentPhaseTimings.tryParse('invalid'), isNull);
    expect(AgentPhaseTimings.fromRelayBody({}), isNull);
  });
  test('should preserve unknown numeric phases and reject invalid values', () {
    final phases = AgentPhaseTimings.tryParse({
      'sql_execute_ms': 12.5,
      'future_phase': 0,
      'negative': -1,
      'infinite': double.infinity,
      'nan': double.nan,
      'text': '12',
      7: 2,
    })!;
    expect(phases.phasesMs, {'sql_execute_ms': 12.5, 'future_phase': 0.0});
    expect(() => phases.phasesMs['mutation'] = 1, throwsUnsupportedError);
  });
}
