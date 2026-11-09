import 'dart:async';

import 'package:colmeia/shared/widgets/navigation/app_tab_change_guard_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('should ignore an older approval after a newer tab request', () async {
    final controller = AppTabChangeGuardController();
    final applied = <int>[];
    final first = Completer<bool>();
    final second = Completer<bool>();
    final oldRequest = controller.requestChange(
      onAllowed: () => applied.add(1),
      fromIndex: 0,
      toIndex: 1,
      guard: (_, _) => first.future,
    );
    final newRequest = controller.requestChange(
      onAllowed: () => applied.add(2),
      fromIndex: 0,
      toIndex: 2,
      guard: (_, _) => second.future,
    );
    second.complete(true);
    expect(await newRequest, isTrue);
    first.complete(true);
    expect(await oldRequest, isFalse);
    expect(applied, [2]);
  });

  test(
    'should ignore approval after selection or lifecycle invalidation',
    () async {
      final controller = AppTabChangeGuardController();
      final decision = Completer<bool>();
      final pending = controller.requestChange(
        onAllowed: () {},
        fromIndex: 0,
        toIndex: 1,
        guard: (_, _) => decision.future,
      );
      controller.invalidate();
      decision.complete(true);
      expect(await pending, isFalse);
      expect(
        await controller.requestChange(
          onAllowed: () {},
          fromIndex: 1,
          toIndex: 2,
        ),
        isTrue,
      );
    },
  );

  test(
    'should invalidate pending navigation when the current tab is selected',
    () async {
      final controller = AppTabChangeGuardController();
      final decision = Completer<bool>();
      final pending = controller.requestChange(
        onAllowed: () {},
        fromIndex: 0,
        toIndex: 1,
        guard: (_, _) => decision.future,
      );
      expect(
        await controller.requestChange(
          onAllowed: () {},
          fromIndex: 0,
          toIndex: 0,
        ),
        isFalse,
      );
      decision.complete(true);
      expect(await pending, isFalse);
    },
  );

  test('should preserve rejection and propagate guard errors', () async {
    final controller = AppTabChangeGuardController();
    expect(
      await controller.requestChange(
        onAllowed: () {},
        fromIndex: 0,
        toIndex: 1,
        guard: (_, _) async => false,
      ),
      isFalse,
    );
    await expectLater(
      controller.requestChange(
        onAllowed: () {},
        fromIndex: 0,
        toIndex: 1,
        guard: (_, _) async => throw StateError('guard failed'),
      ),
      throwsStateError,
    );
    expect(
      await controller.requestChange(
        onAllowed: () {},
        fromIndex: 0,
        toIndex: 1,
      ),
      isTrue,
    );
  });
}
