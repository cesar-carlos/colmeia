import 'package:colmeia/shared/widgets/refresh/app_second_ticker.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reports listener errors and keeps other counters updating', () {
    fakeAsync((clock) {
      final ticker = AppSecondTicker.create();
      final errors = <FlutterErrorDetails>[];
      final previousHandler = FlutterError.onError;
      FlutterError.onError = errors.add;
      var calls = 0;
      void failingListener() => throw StateError('Counter failed');
      void healthyListener() => calls++;
      try {
        ticker
          ..addListener(failingListener)
          ..addListener(healthyListener);
        clock.elapse(const Duration(seconds: 2));
        expect(calls, 2);
        expect(errors, hasLength(2));
        expect(errors.first.exception, isA<StateError>());
      } finally {
        ticker
          ..removeListener(failingListener)
          ..removeListener(healthyListener);
        FlutterError.onError = previousHandler;
      }
      expect(ticker.isTicking, isFalse);
    });
  });

  testWidgets('shares one timer across multiple listeners and stops cleanly', (
    tester,
  ) async {
    var current = DateTime(2026, 5, 19, 12);
    final ticker = AppSecondTicker.create(now: () => current);
    var firstCalls = 0;
    var secondCalls = 0;

    void firstListener() => firstCalls += 1;
    void secondListener() => secondCalls += 1;

    ticker.addListener(firstListener);

    expect(ticker.listenerCount, 1);
    expect(ticker.isTicking, isTrue);

    current = current.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(firstCalls, 1);
    expect(secondCalls, 0);
    expect(ticker.value, current);

    ticker.addListener(secondListener);

    expect(ticker.listenerCount, 2);
    expect(ticker.isTicking, isTrue);

    current = current.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(firstCalls, 2);
    expect(secondCalls, 1);

    ticker
      ..removeListener(firstListener)
      ..removeListener(secondListener);

    expect(ticker.listenerCount, 0);
    expect(ticker.isTicking, isFalse);
  });
}
