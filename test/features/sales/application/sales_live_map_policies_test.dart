import 'package:checks/checks.dart';
import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/features/sales/application/sales_live_map_policies.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'bridgeTimeoutMs uses sales live map env with medium timeout fallback',
    () {
      check(SalesLiveMapPolicies.bridgeTimeoutMs)
          .equals(AppEnvironment.salesLiveMapBridgeTimeoutMs);
      check(AppEnvironment.salesLiveMapBridgeTimeoutMs)
          .equals(AppEnvironment.agentSqlBridgeMediumTimeoutMs);
    },
  );

  test('primary branch codes and geolocation concurrency use AppEnvironment', () {
    check(SalesLiveMapPolicies.primaryCompanyCode)
        .equals(AppEnvironment.salesLiveMapPrimaryCompanyCode);
    check(SalesLiveMapPolicies.primaryBranchCode)
        .equals(AppEnvironment.salesLiveMapPrimaryBranchCode);
    check(SalesLiveMapPolicies.geolocationMaxConcurrency)
        .equals(AppEnvironment.salesLiveMapGeolocationMaxConcurrency);
  });

  test('merge sql batches per target defaults to true', () {
    check(AppEnvironment.agentSqlSalesLiveMapMergeSqlBatchesPerTarget).isTrue();
  });
}
