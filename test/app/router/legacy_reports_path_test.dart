import 'package:checks/checks.dart';
import 'package:colmeia/app/router/app_legacy_route_redirect.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldRedirectLegacyReportsPath', () {
    test('should match /reports and nested paths only', () {
      check(shouldRedirectLegacyReportsPath('/reports')).isTrue();
      check(shouldRedirectLegacyReportsPath('/reports/sales')).isTrue();
      check(shouldRedirectLegacyReportsPath('/report')).isFalse();
      check(shouldRedirectLegacyReportsPath('/dashboard')).isFalse();
      check(shouldRedirectLegacyReportsPath('/settings')).isFalse();
    });
  });

  group('external auth review redirects', () {
    test('should match external client registration review paths', () {
      check(
        isExternalClientRegistrationReviewPath(
          '/client-auth/registration/review',
        ),
      ).isTrue();
      check(
        isExternalClientRegistrationReviewPath(
          '/api/v1/client-auth/registration/review',
        ),
      ).isTrue();
      check(
        isExternalClientRegistrationReviewPath('/client-auth/register'),
      ).isFalse();
    });

    test('should match external client password recovery review paths', () {
      check(
        isExternalClientPasswordRecoveryReviewPath(
          '/client-auth/password-recovery/review',
        ),
      ).isTrue();
      check(
        isExternalClientPasswordRecoveryReviewPath(
          '/api/v1/client-auth/password-recovery/review',
        ),
      ).isTrue();
      check(
        isExternalClientPasswordRecoveryReviewPath(
          '/client-auth/password-recovery/status',
        ),
      ).isFalse();
    });
  });
}
