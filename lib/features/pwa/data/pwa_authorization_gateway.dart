import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/pwa/domain/offline_authorization.dart';
import 'package:colmeia/features/pwa/domain/offline_package_repository.dart';
import 'package:dio/dio.dart';

class PwaAuthorizationGateway implements OfflineAuthorizationGateway {
  PwaAuthorizationGateway(
    this._dio, {
    DateTime Function()? clock,
    Future<void> Function(Duration)? delay,
  }) : _clock = clock ?? DateTime.now,
       _delay = delay ?? Future<void>.delayed;
  final Dio _dio;
  final DateTime Function() _clock;
  final Future<void> Function(Duration) _delay;
  static const _maximumIssuanceWait = Duration(seconds: 5);
  @override
  Future<OfflineAuthorization> authorize(String agent) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/client/me/pwa/offline-authorization',
        data: {
          'agentIds': [agent],
        },
      );
      final authorization = OfflineAuthorization.fromJson(
        Map<String, dynamic>.from(response.data!['data'] as Map),
      );
      final untilIssued = authorization.issuedAt.difference(_clock().toUtc());
      // Wait for small clock differences without relaxing validity or expiry.
      if (untilIssued > Duration.zero && untilIssued <= _maximumIssuanceWait) {
        await _delay(untilIssued);
      }
      return authorization;
    } on DioException catch (error, stack) {
      throw mapToAppFailure(error, stackTrace: stack);
    }
  }
}
