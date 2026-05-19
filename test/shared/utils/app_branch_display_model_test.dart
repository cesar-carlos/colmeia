import 'package:colmeia/shared/utils/app_branch_display_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('prioritizes registration name and exposes fantasy as secondary', () {
    final display = resolveAppBranchDisplayModel(
      registrationName: 'Filial Centro',
      fantasyName: 'Casa do Mel Centro',
      fallbackName: 'Fallback',
      extraSearchTerms: const <String>['Cuiaba', 'MT'],
    );

    expect(display.primaryName, 'Filial Centro');
    expect(display.secondaryName, 'Casa do Mel Centro');
    expect(display.searchTokens, contains('Filial Centro'));
    expect(display.searchTokens, contains('Casa do Mel Centro'));
    expect(display.searchTokens, contains('Cuiaba'));
  });

  test('does not duplicate fantasy when it matches the primary name', () {
    final display = resolveAppBranchDisplayModel(
      registrationName: 'Filial Centro',
      fantasyName: 'Filial Centro',
    );

    expect(display.primaryName, 'Filial Centro');
    expect(display.secondaryName, isNull);
  });
}
