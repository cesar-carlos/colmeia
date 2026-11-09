import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/features/pwa/domain/offline_authorization.dart';
import 'package:colmeia/features/pwa/domain/offline_package_repository.dart';
import 'package:dio/dio.dart';

class PwaAuthorizationGateway implements OfflineAuthorizationGateway {
  PwaAuthorizationGateway(this._dio);
  final Dio _dio;
  @override
  Future<OfflineAuthorization> authorize(String agent) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/client/me/pwa/offline-authorization',
        data: {
          'agentIds': [agent],
        },
      );
      return OfflineAuthorization.fromJson(
        Map<String, dynamic>.from(response.data!['data'] as Map),
      );
    } on DioException catch (error, stack) {
      throw mapToAppFailure(error, stackTrace: stack);
    }
  }
}
