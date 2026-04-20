import 'package:checks/checks.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppLogger sink wiring', () {
    tearDown(() {
      AppLogger.sink = null;
    });

    test('forwards every level to the configured sink', () {
      final sink = _RecordingSink();
      AppLogger.sink = sink;

      AppLogger.debug(
        'breadcrumb',
        context: const <String, Object?>{'op': 'sample'},
      );
      AppLogger.info('info-msg');
      AppLogger.warning(
        'warn-msg',
        error: StateError('boom'),
        stackTrace: StackTrace.current,
      );
      AppLogger.error(
        'error-msg',
        context: const <String, Object?>{'op': 'crash'},
      );

      check(sink.events).length.equals(4);
      check(sink.events[0].level).equals(AppLogLevel.debug);
      check(sink.events[0].message).equals('breadcrumb');
      check(sink.events[0].context['op']).equals('sample');

      check(sink.events[1].level).equals(AppLogLevel.info);
      check(sink.events[2].level).equals(AppLogLevel.warning);
      check(sink.events[2].error).isA<StateError>();
      check(sink.events[2].stackTrace).isNotNull();
      check(sink.events[3].level).equals(AppLogLevel.error);
      check(sink.events[3].context['op']).equals('crash');
    });

    test('sink-less builds are zero-cost no-op', () {
      // Default state — `sink` is null. The call below MUST NOT
      // throw and MUST NOT touch any global state.
      AppLogger.sink = null;
      AppLogger.error('error-without-sink');
      // No way to assert the no-op directly; the test passing
      // (no NPE / crash) is the assertion.
    });

    test(
      'a throwing sink does not propagate into the caller '
      '(observability MUST NOT break business code)',
      () {
        AppLogger.sink = _ThrowingSink();
        // No try/catch — if the sink exception leaked the test would
        // fail with an uncaught error.
        AppLogger.error(
          'error-msg',
          context: const <String, Object?>{'op': 'crash'},
        );
        AppLogger.warning('warn-msg');
        AppLogger.info('info-msg');
        AppLogger.debug('debug-msg');
      },
    );
  });
}

class _RecordingSink implements AppLogSink {
  final List<_LoggedEvent> events = <_LoggedEvent>[];

  @override
  void onLog({
    required AppLogLevel level,
    required String message,
    required Map<String, Object?> context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    events.add(
      _LoggedEvent(
        level: level,
        message: message,
        context: context,
        error: error,
        stackTrace: stackTrace,
      ),
    );
  }
}

class _ThrowingSink implements AppLogSink {
  @override
  void onLog({
    required AppLogLevel level,
    required String message,
    required Map<String, Object?> context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    throw StateError('observability backend exploded: $message');
  }
}

class _LoggedEvent {
  _LoggedEvent({
    required this.level,
    required this.message,
    required this.context,
    this.error,
    this.stackTrace,
  });

  final AppLogLevel level;
  final String message;
  final Map<String, Object?> context;
  final Object? error;
  final StackTrace? stackTrace;
}
