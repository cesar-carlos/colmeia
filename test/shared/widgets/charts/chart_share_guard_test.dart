import 'package:colmeia/shared/widgets/charts/chart_share_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('blocks only the same progress key', () {
    final firstKey = Object();
    final secondKey = Object();

    expect(ChartShareGuard.tryAcquire(firstKey), isTrue);
    expect(ChartShareGuard.tryAcquire(firstKey), isFalse);
    expect(ChartShareGuard.tryAcquire(secondKey), isTrue);

    ChartShareGuard.release(firstKey);
    expect(ChartShareGuard.tryAcquire(firstKey), isTrue);

    ChartShareGuard.release(firstKey);
    ChartShareGuard.release(secondKey);
  });

  test('listenableFor notifies only the matching key', () {
    final firstKey = Object();
    final secondKey = Object();
    var firstNotifications = 0;
    var secondNotifications = 0;

    ChartShareGuard.listenableFor(
      firstKey,
    ).addListener(() => firstNotifications++);
    ChartShareGuard.listenableFor(
      secondKey,
    ).addListener(() => secondNotifications++);

    ChartShareGuard.tryAcquire(firstKey);
    ChartShareGuard.release(firstKey);

    expect(firstNotifications, 2);
    expect(secondNotifications, 0);
  });

  test('releaseListenable drops unused notifiers', () {
    final key = Object();
    void listener() {}

    final first = ChartShareGuard.listenableFor(key)..addListener(listener);
    ChartShareGuard.releaseListenable(key);
    expect(identical(ChartShareGuard.listenableFor(key), first), isTrue);

    first.removeListener(listener);
    ChartShareGuard.releaseListenable(key);
    final second = ChartShareGuard.listenableFor(key);
    expect(identical(first, second), isFalse);
    ChartShareGuard.releaseListenable(key);
  });
}
