import 'package:flutter_test/flutter_test.dart';

/// Drains the microtask queue after `agents:command_response` callbacks that
/// schedule async PayloadFrameCodec work (`decodeJsonAsync`).
///
/// Attach [expectLater] to failing dispatcher futures *before* calling this,
/// otherwise the test harness treats the completed error as unhandled.
Future<void> flushAgentsCommandRouting() => pumpEventQueue();
