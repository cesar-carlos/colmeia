import 'package:checks/checks.dart';
import 'package:colmeia/core/logging/log_redaction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LogRedaction.redactEmail', () {
    test('keeps the first character of the local-part and the domain', () {
      check(LogRedaction.redactEmail('joao@example.com'))
          .equals('j***@example.com');
      check(LogRedaction.redactEmail('pedro@gmail.com'))
          .equals('p***@gmail.com');
    });

    test(
      'masks single-character local-part the same way (always exactly 3 stars)',
      () {
        // Length of the original local-part must NOT leak via the
        // number of `*` — a single-char local-part still gets 3 stars
        // appended so a observer cannot infer "this user has a 1-char
        // address".
        check(LogRedaction.redactEmail('a@b.c')).equals('a***@b.c');
      },
    );

    test('returns null on null input', () {
      check(LogRedaction.redactEmail(null)).isNull();
    });

    test('returns null on whitespace-only input', () {
      // Empty / whitespace strings carry no info — surface `null` so
      // the caller can decide whether to log anything at all instead
      // of emitting an empty `email` field.
      check(LogRedaction.redactEmail('')).isNull();
      check(LogRedaction.redactEmail('   ')).isNull();
    });

    test('returns opaque mask when the input has no @ sign', () {
      // We do not guess the structure: anything that is not email-shaped
      // gets a fully opaque `***` so a typo / wrong-field never leaks
      // a real value.
      check(LogRedaction.redactEmail('not-an-email')).equals('***');
      check(LogRedaction.redactEmail('still missing')).equals('***');
    });

    test('handles `@example.com` (empty local-part) defensively', () {
      // No useful disambiguator survives — emit the opaque mask but
      // keep the domain so log readers know it was email-shaped.
      check(LogRedaction.redactEmail('@example.com'))
          .equals('***@example.com');
    });

    test('trims surrounding whitespace before redacting', () {
      check(LogRedaction.redactEmail('  user@host.com  '))
          .equals('u***@host.com');
    });
  });
}
