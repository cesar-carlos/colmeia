import 'package:checks/checks.dart';
import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/client_agents/presentation/localization/client_agents_failure_l10n.dart';
import 'package:colmeia/l10n/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'maps AGENT_DOCUMENT_CONFLICT validation failure to localized message',
    () {
      const failure = ValidationFailure(
        message: 'Agent document conflict',
        context: <String, Object?>{
          ApiErrorContext.apiErrorCode:
              ApiConflictErrorCode.agentDocumentConflict,
        },
      );

      final text = clientAgentsFailureUserMessage(
        failure,
        AppLocalizationsEn(),
      );

      check(text).contains('CNPJ/CPF');
      check(text).contains('catalog');
    },
  );
}
