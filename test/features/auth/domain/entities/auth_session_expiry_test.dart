import 'package:checks/checks.dart';
import 'package:colmeia/core/value_objects/email_address.dart';
import 'package:colmeia/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthSession.isExpiredAt', () {
    test('returns false when now is strictly before expiresAt', () {
      final session = _session(
        expiresAt: DateTime.utc(2026, 4, 18, 10, 0, 30),
      );
      check(
        session.isExpiredAt(DateTime.utc(2026, 4, 18, 10)),
      ).isFalse();
    });

    test(
      'returns true at the exact expiry boundary (inclusive)',
      () {
        // Boundary is treated as expired because the bridge rejects
        // tokens whose `exp` equals the current second.
        final expiresAt = DateTime.utc(2026, 4, 18, 10);
        final session = _session(expiresAt: expiresAt);
        check(session.isExpiredAt(expiresAt)).isTrue();
      },
    );

    test('returns true when now is past expiresAt', () {
      final session = _session(
        expiresAt: DateTime.utc(2026, 4, 18, 10),
      );
      check(
        session.isExpiredAt(DateTime.utc(2026, 4, 18, 10, 0, 1)),
      ).isTrue();
    });
  });

  group('AuthSession.isExpiringWithin', () {
    test('false when expiry is far beyond the window', () {
      final session = _session(
        expiresAt: DateTime.utc(2026, 4, 18, 10, 5),
      );
      check(
        session.isExpiringWithin(
          const Duration(seconds: 30),
          now: DateTime.utc(2026, 4, 18, 10),
        ),
      ).isFalse();
    });

    test('true at the cutoff (expiresAt - window)', () {
      // Window 30s, expiresAt = 10:00:30, cutoff = 10:00:00 — the
      // boundary itself counts as "expiring" so we refresh on the
      // same tick the cutoff is reached.
      final session = _session(
        expiresAt: DateTime.utc(2026, 4, 18, 10, 0, 30),
      );
      check(
        session.isExpiringWithin(
          const Duration(seconds: 30),
          now: DateTime.utc(2026, 4, 18, 10),
        ),
      ).isTrue();
    });

    test('true when already past expiresAt', () {
      // Expired tokens still report `true` so the proactive refresh
      // path catches stale boots / paused-then-resumed apps.
      final session = _session(
        expiresAt: DateTime.utc(2026, 4, 18, 10),
      );
      check(
        session.isExpiringWithin(
          const Duration(seconds: 30),
          now: DateTime.utc(2026, 4, 18, 10, 5),
        ),
      ).isTrue();
    });

    test(
      'window <= 0 collapses to isExpiredAt semantics',
      () {
        // Defensive — a misconfigured window must not trigger
        // perpetual refresh on every request. Only frames that are
        // strictly expired qualify.
        final session = _session(
          expiresAt: DateTime.utc(2026, 4, 18, 10),
        );
        check(
          session.isExpiringWithin(
            Duration.zero,
            now: DateTime.utc(2026, 4, 18, 9, 59, 59),
          ),
        ).isFalse();
        check(
          session.isExpiringWithin(
            const Duration(seconds: -10),
            now: DateTime.utc(2026, 4, 18, 9, 59, 59),
          ),
        ).isFalse();
        check(
          session.isExpiringWithin(
            Duration.zero,
            now: DateTime.utc(2026, 4, 18, 10, 0, 1),
          ),
        ).isTrue();
      },
    );
  });
}

AuthSession _session({required DateTime expiresAt}) {
  return AuthSession(
    userId: 'user-1',
    email: EmailAddress('user@example.com'),
    accessToken: 'access',
    refreshToken: 'refresh',
    expiresAt: expiresAt,
  );
}
