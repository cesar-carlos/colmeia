import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/shared/widgets/refresh/app_second_ticker.dart';
import 'package:colmeia/shared/widgets/refresh/auto_refresh_countdown_text.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

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

    for (final theme in [AppTheme.light(), AppTheme.dark()]) {
      for (final backingOff in [true, false]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            home: Scaffold(
              body: AutoRefreshCountdownText(
                nextDueAt: DateTime(2026, 5, 19, 12, 0, 5),
                isBackingOff: backingOff,
                ticker: ticker,
                labelBuilder: (remaining, {required isBackingOff}) =>
                    '${remaining.inSeconds}s',
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final text = tester.widget<Text>(find.text('2s'));
        final foreground = text.style!.color!.computeLuminance();
        final background = theme.scaffoldBackgroundColor.computeLuminance();
        final contrast = foreground > background
            ? (foreground + 0.05) / (background + 0.05)
            : (background + 0.05) / (foreground + 0.05);
        expect(contrast, greaterThanOrEqualTo(4.5));
        expect(
          text.style!.fontWeight,
          backingOff ? FontWeight.w700 : FontWeight.w500,
        );
      }
    }
    await tester.pumpWidget(const SizedBox.shrink());
    ticker.dispose();
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
