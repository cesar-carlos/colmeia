import 'package:colmeia/shared/utils/app_debouncer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'run executes action after duration and supersedes prior runs',
    () async {
      final debouncer = AppDebouncer(
        duration: const Duration(milliseconds: 40),
      );
      var executionCount = 0;

      debouncer
        ..run(() => executionCount++)
        ..run(() => executionCount += 10);

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(executionCount, 0);

      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(executionCount, 10);

      debouncer.dispose();
    },
  );

  test('cancel prevents scheduled action', () async {
    final debouncer = AppDebouncer(duration: const Duration(milliseconds: 30));
    var executed = false;

    debouncer
      ..run(() => executed = true)
      ..cancel();

    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(executed, isFalse);

    debouncer.dispose();
  });
}
