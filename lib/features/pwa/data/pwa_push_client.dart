import 'package:colmeia/core/pwa/pwa_platform.dart';
import 'package:colmeia/features/pwa/domain/push_subscriptions.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class PwaPushClient implements PushSubscriptions {
  PwaPushClient(this._platform, this._dio, this._preferences);
  final PwaPlatform _platform;
  final Dio _dio;
  final SharedPreferences _preferences;
  String _installationKey(String user) => 'pwa.installation.$user';
  String _pendingKey(String user) => 'pwa.pushRemoval.$user';
  Future<String> _installation(String user) async {
    final old = _preferences.getString(_installationKey(user));
    if (old != null) return old;
    final id = const Uuid().v4();
    await _preferences.setString(_installationKey(user), id);
    return id;
  }

  @override
  Future<void> enable(String user) async {
    await reconcile(user);
    final response = await _dio.get<Map<String, dynamic>>(
      '/client/me/pwa/push-key',
    );
    final data = response.data!['data'] as Map;
    if (data['enabled'] != true) {
      throw StateError('Notificações ainda não configuradas no servidor.');
    }
    final subscription = await _platform.subscribe(data['publicKey'] as String);
    if (subscription == null) {
      throw StateError('Permissão de notificações não concedida.');
    }
    final id = await _installation(user);
    await _dio.put<void>(
      '/client/me/pwa/subscriptions/$id',
      data: {
        'endpoint': subscription['endpoint'],
        'keys': subscription['keys'],
      },
    );
    await _platform.setPushEnabled(enabled: true);
    await _preferences.setBool('pwa.pushEnabled.$user', true);
  }

  @override
  Future<void> disable(String user) async {
    final id = _preferences.getString(_installationKey(user));
    if (id != null) await _preferences.setString(_pendingKey(user), id);
    try {
      await _platform.setPushEnabled(enabled: false);
    } finally {
      await _preferences.setBool('pwa.pushEnabled.$user', false);
      await _platform.unsubscribe();
    }
    if (_platform.online) await reconcile(user);
  }

  @override
  Future<void> reconcile(String user) async {
    final pending = _preferences.getString(_pendingKey(user));
    if (pending == null || !_platform.online) return;
    await _dio.delete<void>('/client/me/pwa/subscriptions/$pending');
    await _preferences.remove(_pendingKey(user));
  }
}
