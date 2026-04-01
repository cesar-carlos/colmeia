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
}
