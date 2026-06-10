import 'package:colmeia/app/theme/app_theme.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/features/auth/application/auth_registration_preferences_service.dart';
import 'package:colmeia/features/auth/application/usecases/read_registration_status_use_case.dart';
import 'package:colmeia/features/auth/application/usecases/retry_client_registration_use_case.dart';
import 'package:colmeia/features/auth/domain/entities/client_registration_status.dart';
import 'package:colmeia/features/auth/domain/repositories/client_registration_repository.dart';
import 'package:colmeia/features/auth/presentation/controllers/registration_status_page_controller.dart';
import 'package:colmeia/features/auth/presentation/pages/registration_status_page.dart';
import 'package:colmeia/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:result_dart/result_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const validToken =
      'abcdefghijklmnopqrstuvwxyz0123456789abcdefghijklmnopqr';

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('should show unknown status card on successful lookup', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final controller = RegistrationStatusPageController(
      readRegistrationStatusUseCase: ReadRegistrationStatusUseCase(
        _UnknownStatusRepository(),
      ),
      retryClientRegistrationUseCase: RetryClientRegistrationUseCase(
        _UnknownStatusRepository(),
      ),
      preferencesService: AuthRegistrationPreferencesService(prefs),
      initialToken: validToken,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: RegistrationStatusPage(controller: controller),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(Scaffold)),
    );

    expect(find.text(l10n.authRegistrationStatusUnknownTitle), findsOneWidget);
    expect(find.text(l10n.authRegistrationStatusUnknownMessage), findsOneWidget);
  });
}

final class _UnknownStatusRepository implements ClientRegistrationRepository {
  @override
  Future<AppResult<ClientRegistrationStatus>> readRegistrationStatus({
    required String token,
  }) async {
    return const Success<ClientRegistrationStatus, AppFailure>(
      ClientRegistrationStatus.unknown,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
