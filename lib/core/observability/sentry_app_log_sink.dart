import 'dart:async';

import 'package:colmeia/core/logging/app_logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Adapter that forwards [AppLogger] entries to Sentry.
///
/// Mapping:
///
/// * `error` / `warning` → `Sentry.captureException` (or
///   `captureMessage` when no `error` was supplied). Carries the
///   `context` map as a Sentry contexts entry so it is queryable in
///   the issue UI without dumping raw payloads into the message.
/// * `info` / `debug` → `Sentry.addBreadcrumb` so the event shows up
///   in the trail of any later capture, but does NOT create an issue
///   on its own. Mirrors the existing mental model — only
///   `warning`/`error` were paying for stack traces upstream.
///
/// PII discipline: relies on callers to redact sensitive fields BEFORE
/// invoking `AppLogger.*` (see `core/logging/log_redaction.dart`). The
/// sink does NOT scrub the `context` map — pre-existing redaction
/// keeps the seam single-purpose.
class SentryAppLogSink implements AppLogSink {
  /// Optional [Hub] override so tests can inject a fake without
  /// initialising the real Sentry SDK. Production wiring (via
  /// `bootstrap.dart`) leaves this `null`, falling back to the
  /// process-wide hub via the public top-level helpers
  /// (`Sentry.captureException`, etc.).
  SentryAppLogSink({this._hub});

  final Hub? _hub;

  @override
  void onLog({
    required AppLogLevel level,
    required String message,
    required Map<String, Object?> context,
    Object? error,
    StackTrace? stackTrace,
  }) {
    switch (level) {
      case AppLogLevel.debug:
      case AppLogLevel.info:
        _addBreadcrumb(level: level, message: message, context: context);
      case AppLogLevel.warning:
      case AppLogLevel.error:
        _capture(
          level: level,
          message: message,
          context: context,
          error: error,
          stackTrace: stackTrace,
        );
    }
  }

  void _addBreadcrumb({
    required AppLogLevel level,
    required String message,
    required Map<String, Object?> context,
  }) {
    final breadcrumb = Breadcrumb(
      message: message,
      level: _toSentryLevel(level),
      category: 'app_logger',
      data: context.isEmpty ? null : Map<String, Object?>.from(context),
      timestamp: DateTime.now().toUtc(),
    );
    final hub = _hub;
    // Fire-and-forget: breadcrumbs are best-effort and the caller
    // (ultimately `AppLogger`) treats observability as side-effect.
    // `unawaited` documents the discard explicitly.
    if (hub != null) {
      unawaited(hub.addBreadcrumb(breadcrumb));
    } else {
      unawaited(Sentry.addBreadcrumb(breadcrumb));
    }
  }

  void _capture({
    required AppLogLevel level,
    required String message,
    required Map<String, Object?> context,
    required Object? error,
    required StackTrace? stackTrace,
  }) {
    void configureScope(Scope scope) {
      scope.level = _toSentryLevel(level);
      // Surface the structured context as a Sentry "contexts" entry
      // so it stays queryable in the issue UI instead of being
      // flattened into the message text. Empty maps are omitted to
      // keep the issue surface clean. The Sentry SDK returns
      // `Future<void>` from `setContexts` / `setTag` for legacy
      // reasons; we treat both as fire-and-forget — the values are
      // already in the scope object passed back to the capture call.
      if (context.isNotEmpty) {
        // `setContexts` returns `FutureOr<void>` (legacy SDK shape).
        // We cannot use `unawaited` directly with a `FutureOr`, so we
        // assign to `_` to document the discard.
        final _ = scope.setContexts(
          'app_logger',
          Map<String, Object?>.from(context),
        );
      }
      // Pivot tag so dashboards can group by operation / queryKey
      // / agentId without scanning the whole context payload.
      final operation = context['operation'];
      if (operation is String && operation.isNotEmpty) {
        final _ = scope.setTag('operation', operation);
      }
    }

    final hub = _hub;
    // Same fire-and-forget discipline as breadcrumbs: capturing is
    // a best-effort side-effect; AppLogger callers MUST never block
    // on a flush. `unawaited` documents the discard.
    if (error != null) {
      if (hub != null) {
        unawaited(
          hub.captureException(
            error,
            stackTrace: stackTrace,
            withScope: configureScope,
          ),
        );
      } else {
        unawaited(
          Sentry.captureException(
            error,
            stackTrace: stackTrace,
            withScope: configureScope,
          ),
        );
      }
    } else {
      // No exception bound — surface the message itself. Sentry
      // groups by `message` template so giving up the structured
      // error means we lose stack-based fingerprinting; setting
      // `template` keeps groups stable across context changes.
      if (hub != null) {
        unawaited(
          hub.captureMessage(
            message,
            level: _toSentryLevel(level),
            template: message,
            withScope: configureScope,
          ),
        );
      } else {
        unawaited(
          Sentry.captureMessage(
            message,
            level: _toSentryLevel(level),
            template: message,
            withScope: configureScope,
          ),
        );
      }
    }
  }

  SentryLevel _toSentryLevel(AppLogLevel level) {
    return switch (level) {
      AppLogLevel.debug => SentryLevel.debug,
      AppLogLevel.info => SentryLevel.info,
      AppLogLevel.warning => SentryLevel.warning,
      AppLogLevel.error => SentryLevel.error,
    };
  }
}
