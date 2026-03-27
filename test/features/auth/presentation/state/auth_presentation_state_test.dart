import 'package:colmeia/features/auth/presentation/state/auth_presentation_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthPresentationState', () {
    test('should clear error and success when requested', () {
      const state = AuthPresentationState(
        errorMessage: 'err',
        successMessage: 'ok',
      );

      final cleared = state.copyWith(
        clearErrorMessage: true,
        clearSuccessMessage: true,
      );

      expect(cleared.errorMessage, isNull);
      expect(cleared.successMessage, isNull);
    });

    test('should clear session when requested', () {
      const state = AuthPresentationState();

      final cleared = state.copyWith(clearSession: true);

      expect(cleared.session, isNull);
    });
  });
}
