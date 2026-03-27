import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/features/auth/presentation/controllers/auth_controller.dart';
import 'package:colmeia/features/reports/presentation/pages/reports_page.dart';
import 'package:colmeia/features/user_context/presentation/controllers/current_user_context_controller.dart';
import 'package:colmeia/shared/widgets/charts/app_comparison_bar_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('should render shared seller revenue chart section', (
    tester,
  ) async {
    await setupDependencies();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthController>.value(
              value: getIt<AuthController>(),
            ),
            ChangeNotifierProvider<CurrentUserContextController>(
              create: (_) => CurrentUserContextController.seeded(),
            ),
          ],
          child: const ReportsPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    await tester.dragUntilVisible(
      find.byType(AppComparisonBarChart),
      find.byType(ListView),
      const Offset(0, -300),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.text('Comparativo de faturamento por vendedor'),
      findsOneWidget,
    );
    expect(find.byType(AppComparisonBarChart), findsOneWidget);
  });
}
