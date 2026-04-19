/// Helpers for masking sensitive values **before** they reach the logger
/// or any error reporter (Sentry, third-party log aggregators).
///
/// PII minimisation policy: emails identify natural persons under
/// LGPD/GDPR. The app frequently routes operations through breadcrumbs
/// like `{ operation: 'signIn', email: <typed value> }` — useful for
/// debugging duplicated logins, but unnecessary in plain text. Masking
/// keeps the local-part disambiguator (first character + domain) so
/// developers can still correlate a single user's events without
/// shipping the raw identifier off-device.
abstract final class LogRedaction {
  /// Returns a masked representation of [email] safe to log:
  ///
  /// * `joao@example.com` → `j***@example.com`
  /// * `a@b.c`            → `a***@b.c`
  /// * `'   '` / `null`   → `null` (caller decides whether to log
  ///   anything at all)
  /// * `'not-an-email'`   → `'***'` (no `@`, opaque mask — we don't
  ///   guess at structure)
  ///
  /// The first character of the local-part survives so multi-event
  /// debugging can still cluster around one user; the rest is
  /// replaced by exactly three `*` regardless of length so the
  /// original length is not leaked either.
  static String? redactEmail(String? email) {
    if (email == null) {
      return null;
    }
    final trimmed = email.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final atIndex = trimmed.indexOf('@');
    if (atIndex < 0) {
      // Not an email-shaped string. Don't expose the raw value.
      return _opaqueMask;
    }
    final local = trimmed.substring(0, atIndex);
    final domain = trimmed.substring(atIndex);
    if (local.isEmpty) {
      // `@example.com` — defensive, no useful disambiguator to keep.
      return '$_opaqueMask$domain';
    }
    return '${local.substring(0, 1)}$_redactionStars$domain';
  }

  static const String _opaqueMask = '***';
  static const String _redactionStars = '***';
}
