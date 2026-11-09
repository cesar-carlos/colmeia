import 'package:colmeia/core/pwa/pwa_platform.dart';
import 'package:dio/dio.dart';

class PwaNetworkInterceptor extends Interceptor {
  PwaNetworkInterceptor(this._platform);
  final PwaPlatform _platform;
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!_platform.online) {
      handler.reject(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          message: 'Requer conexão. Use os dados disponíveis offline.',
        ),
      );
      return;
    }
    handler.next(options);
  }
}
