import 'package:flutter_test/flutter_test.dart';

/// Drains the microtask queue after relay socket callbacks that schedule
/// async PayloadFrameCodec work (`decodeJsonAsync` / `encodeJsonAsync`).
Future<void> flushRelayFrameRouting() => pumpEventQueue();
