// Contract test: CI runs `flutter test ... test/integration/dart_test_config_contract_test.dart`
// (see [.github/workflows/flutter_ci.yml]) so `dart_test.yaml` keeps the `e2e` tag used by
// `--exclude-tags e2e`. This file must remain a non-e2e integration test entrypoint.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dart_test.yaml declares e2e tag (CI excludes e2e from PR runs)', () {
    final raw = File('dart_test.yaml').readAsStringSync();
    expect(raw, contains('tags:'));
    expect(raw, contains('e2e:'));
  });
}
