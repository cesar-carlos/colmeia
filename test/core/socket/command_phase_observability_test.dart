import 'package:colmeia/core/socket/command_phase_observability.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('disposal removes the per-request listener', () {
    final observers = CommandPhaseObservers();
    final phases = <String>[];
    final dispose = observers.observe(
      'request',
      (phase, _) => phases.add(phase),
    );
    observers.record('request', 'connection', Duration.zero);
    dispose();
    observers.record('request', 'late', Duration.zero);
    expect(phases, ['connection']);
  });
  test('an old disposer cannot remove a newer listener with the same id', () {
    final observers = CommandPhaseObservers();
    final dispose = observers.observe('request', (_, _) {});
    var calls = 0;
    final disposeNew = observers.observe('request', (_, _) => calls++);
    dispose();
    observers.record('request', 'connection', Duration.zero);
    disposeNew();
    expect(calls, 1);
  });
  test('diagnostic errors do not affect transport processing', () {
    final observers = CommandPhaseObservers();
    final dispose = observers.observe(
      'request',
      (_, _) => throw StateError('diagnostics failed'),
    );
    expect(
      () => observers.record('request', 'connection', Duration.zero),
      returnsNormally,
    );
    dispose();
  });
}
