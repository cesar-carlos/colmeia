import 'package:colmeia/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:colmeia/features/auth/data/models/auth_session_model.dart';

class AuthSessionAccessor {
  AuthSessionAccessor(this._authLocalDataSource);

  final AuthLocalDataSource _authLocalDataSource;

  Future<AuthSessionModel?> read() => _authLocalDataSource.readSession();

  Future<void> save(AuthSessionModel session) {
    return _authLocalDataSource.saveSession(session);
  }

  Future<void> clear() => _authLocalDataSource.clearSession();
}
