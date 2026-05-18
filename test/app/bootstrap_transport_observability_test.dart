import 'package:checks/checks.dart';
import 'package:colmeia/app/bootstrap.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    AppLogger.sink = null;
    dotenv.loadFromString(
      envString: '''
AGENT_BRIDGE_TRANSPORT=rest
SOCKET_RELAY_ENABLED=false
SOCKET_PRESENCE_LISTENER_ENABLED=false
SOCKET_WARM_UP_AFTER_LOGIN=true
''',
    );
  });

  test(
    'logs an explicit warning and resolved transport when AGENT_BRIDGE_TRANSPORT is invalid',
    () {
      final sink = _RecordingSink();
      AppLogger.sink = sink;
      dotenv.loadFromString(
        envString: '''
AGENT_BRIDGE_TRANSPORT=grpc
SOCKET_RELAY_ENABLED=false
SOCKET_PRESENCE_LISTENER_ENABLED=false
SOCKET_WARM_UP_AFTER_LOGIN=true
''',
      );

      logResolvedAgentBridgeTransportAtBootstrap();

      check(sink.events).length.equals(2);

      final warning = sink.events[0];
      check(warning.level).equals(AppLogLevel.warning);
      check(warning.message).equals(
        'Bootstrap: invalid AGENT_BRIDGE_TRANSPORT value; falling back to default transport',
      );
      check(warning.context['rawTransport']).equals('grpc');
      check(warning.context['resolvedTransport']).equals('rest');
      check(warning.context['fallbackApplied']).equals(true);

      final info = sink.events[1];
      check(info.level).equals(AppLogLevel.info);
      check(info.message).equals('Bootstrap: agent bridge transport resolved');
      check(info.context['transport']).equals('rest');
      check(info.context['rawTransport']).equals('grpc');
    },
  );
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
      _LoggedEvent(level: level, message: message, context: context),
    );
  }
}

class _LoggedEvent {
  const _LoggedEvent({
    required this.level,
    required this.message,
    required this.context,
  });

  final AppLogLevel level;
  final String message;
  final Map<String, Object?> context;
}
