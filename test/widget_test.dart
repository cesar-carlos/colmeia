import 'package:colmeia/app/bootstrap.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('should render login screen on bootstrap', (
    tester,
  ) async {
    await setupDependencies();
    await tester.pumpWidget(const ColmeiaBootstrap());
    await tester.pump();

    expect(find.text('COLMEIA BI'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });
}
