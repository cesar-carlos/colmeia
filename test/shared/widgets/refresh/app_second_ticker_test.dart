import 'package:colmeia/shared/widgets/refresh/app_second_ticker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
