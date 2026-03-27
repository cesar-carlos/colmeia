import 'package:colmeia/core/storage/session_storage.dart';
import 'package:colmeia/features/auth/data/models/auth_session_model.dart';

class AuthLocalDataSource {
  AuthLocalDataSource({
    required SessionStorage sessionStorage,
  }) : _sessionStorage = sessionStorage;

  static const String _sessionKey = 'auth_session';

  final SessionStorage _sessionStorage;

  Future<void> saveSession(AuthSessionModel session) {
    return _sessionStorage.write(
      key: _sessionKey,
      value: session.encode(),
    );
  }

  Future<AuthSessionModel?> readSession() async {
    final encodedSession = await _sessionStorage.read(_sessionKey);

    if (encodedSession == null || encodedSession.isEmpty) {
      return null;
    }

    return AuthSessionModel.decode(encodedSession);
  }

  Future<void> clearSession() => _sessionStorage.delete(_sessionKey);
}
