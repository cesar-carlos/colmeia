import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('injector registers agent-queries before overview', () {
    final file = File('lib/core/di/injector.dart');
    expect(file.existsSync(), isTrue);
    final text = file.readAsStringSync();
    final agentIdx = text.indexOf('registerInjectorAgentQueries');
    final overviewIdx = text.indexOf('registerInjectorOverview');
    expect(
      agentIdx,
      greaterThan(-1),
      reason: 'registerInjectorAgentQueries missing',
    );
    expect(
      overviewIdx,
      greaterThan(-1),
      reason: 'registerInjectorOverview missing',
    );
    expect(
      agentIdx,
      lessThan(overviewIdx),
      reason: 'OverviewRepositoryImpl depends on agent-queries registrations',
    );
  });
}
