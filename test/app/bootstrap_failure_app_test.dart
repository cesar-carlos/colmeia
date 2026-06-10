import 'package:colmeia/app/bootstrap_failure_app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows clear-cache action only when recovery callback is set', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BootstrapFailureApp(
          onRetry: () async {},
          onClearCacheAndRetry: () async {},
        ),
      ),
    );

    expect(find.text('Limpar cache local e tentar'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
  });

  testWidgets('hides clear-cache action when recovery callback is absent', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BootstrapFailureApp(
          onRetry: () async {},
        ),
      ),
    );

    expect(find.text('Limpar cache local e tentar'), findsNothing);
    expect(find.text('Tentar novamente'), findsOneWidget);
  });
}
