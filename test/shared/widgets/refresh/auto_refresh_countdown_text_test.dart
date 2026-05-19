import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/shared/widgets/refresh/app_second_ticker.dart';
import 'package:colmeia/shared/widgets/refresh/auto_refresh_countdown_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('updates the label while the countdown is active', (
    tester,
  ) async {
    final ticker = ValueNotifier<DateTime>(DateTime(2026, 5, 19, 12));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AutoRefreshCountdownText(
            nextDueAt: DateTime(2026, 5, 19, 12, 0, 5),
            isBackingOff: false,
            ticker: ticker,
            labelBuilder: (remaining, {required isBackingOff}) {
              return '${remaining.inSeconds}s';
            },
          ),
        ),
      ),
    );

    expect(find.text('5s'), findsOneWidget);

    ticker.value = DateTime(2026, 5, 19, 12, 0, 3);
    await tester.pump();

    expect(find.text('2s'), findsOneWidget);
  });

  testWidgets('stops listening to the shared ticker when the countdown ends', (
    tester,
  ) async {
    var current = DateTime(2026, 5, 19, 12);
    final ticker = AppSecondTicker.create(now: () => current);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AutoRefreshCountdownText(
            nextDueAt: current.add(const Duration(seconds: 2)),
            isBackingOff: false,
            ticker: ticker,
            labelBuilder: (remaining, {required isBackingOff}) {
              return '${remaining.inSeconds}s';
            },
          ),
        ),
      ),
    );

    expect(ticker.listenerCount, 1);
    expect(ticker.isTicking, isTrue);

    current = current.add(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 2));

    expect(find.text('0s'), findsOneWidget);
    expect(ticker.listenerCount, 0);
    expect(ticker.isTicking, isFalse);
  });

  testWidgets('resubscribes when a new future due time is provided', (
    tester,
  ) async {
    final current = DateTime(2026, 5, 19, 12);
    final ticker = AppSecondTicker.create(now: () => current);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AutoRefreshCountdownText(
            nextDueAt: current.subtract(const Duration(seconds: 1)),
            isBackingOff: false,
            ticker: ticker,
            labelBuilder: (remaining, {required isBackingOff}) {
              return '${remaining.inSeconds}s';
            },
          ),
        ),
      ),
    );

    expect(ticker.listenerCount, 0);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AutoRefreshCountdownText(
            nextDueAt: current.add(const Duration(seconds: 3)),
            isBackingOff: false,
            ticker: ticker,
            labelBuilder: (remaining, {required isBackingOff}) {
              return '${remaining.inSeconds}s';
            },
          ),
        ),
      ),
    );

    expect(ticker.listenerCount, 1);
    expect(ticker.isTicking, isTrue);
  });
}
