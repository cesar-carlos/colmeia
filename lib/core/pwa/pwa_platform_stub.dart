import 'package:colmeia/core/pwa/pwa_platform.dart';

PwaPlatform createPwaPlatform() => _NativePwaPlatform();

class _NativePwaPlatform implements PwaPlatform {
  @override
  bool get supported => false;
  @override
  bool get online => true;
  @override
  bool get updateAvailable => false;
  @override
  Stream<String> get events => const Stream.empty();
  @override
  Future<bool> install() async => false;
  @override
  void update() {}
  @override
  void beginWork() {}
  @override
  void endWork() {}
  @override
  Future<bool> persistStorage() async => false;
  @override
  Future<({int usage, int quota})?> storageEstimate() async => null;
  @override
  Future<Map<String, dynamic>?> subscribe(String publicKey) async => null;
  @override
  Future<void> unsubscribe() async {}
  @override
  Future<void> setPushEnabled({required bool enabled}) async {}
  @override
  Future<void> withLock(String name, Future<void> Function() action) =>
      action();
  @override
  void broadcastLogout() {}
  @override
  void dispose() {}
}
