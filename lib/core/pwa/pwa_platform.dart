abstract interface class PwaPlatform {
  bool get supported;
  bool get online;
  bool get updateAvailable;
  Stream<String> get events;
  Future<bool> install();
  void update();
  void beginWork();
  void endWork();
  Future<bool> persistStorage();
  Future<({int usage, int quota})?> storageEstimate();
  Future<Map<String, dynamic>?> subscribe(String publicKey);
  Future<void> unsubscribe();
  Future<void> setPushEnabled({required bool enabled});
  Future<void> withLock(String name, Future<void> Function() action);
  void broadcastLogout();
  void dispose();
}
