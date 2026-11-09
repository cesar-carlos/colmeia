import 'package:colmeia/core/pwa/pwa_platform.dart';
import 'package:colmeia/features/pwa/domain/push_subscription_exception.dart';
import 'package:colmeia/features/pwa/domain/push_subscriptions.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class PwaPushClient implements PushSubscriptions {
  PwaPushClient(this._platform, this._dio, this._preferences);
  final PwaPlatform _platform;
  final Dio _dio;
  final SharedPreferences _preferences;
  final _removalGenerations = <String, int>{};
  final _reconciliations = <String, Future<void>>{};
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
    final data = response.data?['data'];
    if (data is! Map || data['enabled'] is! bool) {
      throw const PushSubscriptionException(
        PushSubscriptionIssue.invalidResponse,
      );
    }
    if (data['enabled'] == false) {
      throw const PushSubscriptionException(
        PushSubscriptionIssue.serverDisabled,
      );
    }
    final key = data['publicKey'];
    if (key is! String || key.trim().isEmpty) {
      throw const PushSubscriptionException(
        PushSubscriptionIssue.invalidResponse,
      );
    }
    final subscription = await _platform.subscribe(key);
    if (subscription == null) {
      throw const PushSubscriptionException(
        PushSubscriptionIssue.permissionDenied,
      );
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
    _removalGenerations[user] = (_removalGenerations[user] ?? 0) + 1;
    try {
      final id = _preferences.getString(_installationKey(user));
      if (id != null && !await _preferences.setString(_pendingKey(user), id)) {
        throw StateError('Could not persist pending Push removal');
      }
    } finally {
      try {
        await _platform.setPushEnabled(enabled: false);
      } finally {
        try {
          if (!await _preferences.setBool('pwa.pushEnabled.$user', false)) {
            throw StateError('Could not persist disabled Push preference');
          }
        } finally {
          await _platform.unsubscribe();
        }
      }
    }
    if (_platform.online) await reconcile(user);
  }

  @override
  Future<void> reconcile(String user) async {
    final active = _reconciliations[user];
    if (active != null) return active;
    final operation = _reconcile(user).whenComplete(() {
      // ignore: discarded_futures -- Remove tracking; awaiting would await this callback.
      _reconciliations.remove(user);
    });
    _reconciliations[user] = operation;
    return operation;
  }

  Future<void> _reconcile(String user) async {
    final generation = _removalGenerations[user] ?? 0;
    final pending = _preferences.getString(_pendingKey(user));
    if (pending == null || !_platform.online) return;
    await _dio.delete<void>('/client/me/pwa/subscriptions/$pending');
    if (generation == (_removalGenerations[user] ?? 0) &&
        _preferences.getString(_pendingKey(user)) == pending) {
      if (!await _preferences.remove(_pendingKey(user))) {
        throw StateError('Could not persist completed Push removal');
      }
    }
  }
}
