import 'package:colmeia/features/pwa/domain/offline_authorization.dart';
import 'package:colmeia/features/pwa/domain/offline_package.dart';

abstract interface class OfflinePackageRepository {
  Future<void> publish(OfflinePackage package);
  Future<OfflinePackage?> read(String user, String agent, DateTime now);
  Future<void> remove(String user, String agent);
  Future<void> clearUser(String user);
}

// This port isolates the authenticated server grant from offline orchestration.
// ignore: one_member_abstracts
abstract interface class OfflineAuthorizationGateway {
  Future<OfflineAuthorization> authorize(String agent);
}
