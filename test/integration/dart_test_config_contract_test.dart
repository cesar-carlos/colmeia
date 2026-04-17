// Contract test: `flutter test test/integration --exclude-tags e2e` is wired
// in [.github/workflows/flutter_ci.yml]. If this file is removed, CI may exit
// 79 when every file under test/integration is tagged `e2e`.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dart_test.yaml declares e2e tag (CI excludes e2e from PR runs)', () {
    final raw = File('dart_test.yaml').readAsStringSync();
    expect(raw, contains('tags:'));
    expect(raw, contains('e2e:'));
  });
}
