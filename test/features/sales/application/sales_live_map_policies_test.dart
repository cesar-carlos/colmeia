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
}
