import 'dart:convert';
import 'dart:typed_data';

import 'package:checks/checks.dart';
import 'package:colmeia/core/network/app_dio_client.dart';
import 'package:colmeia/features/user_context/data/datasources/user_context_remote_datasource.dart';
import 'package:colmeia/features/user_context/domain/entities/user_permission.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestHttpClientAdapter implements HttpClientAdapter {
  _TestHttpClientAdapter(this._handler);

  final Future<ResponseBody> Function(RequestOptions options) _handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return _handler(options);
  }
}

void main() {
  group('ApiUserContextRemoteDataSource', () {
    test('should grant dashboard access for client account context', () async {
      final dio = AppDioClient.create()
        ..httpClientAdapter = _TestHttpClientAdapter((_) async {
          return ResponseBody.fromString(
            jsonEncode(<String, Object?>{
              'data': <String, Object?>{
                'id': 'client-1',
                'email': 'client@corp.com',
                'status': 'active',
                'name': 'Ana',
                'lastName': 'Silva',
              },
            }),
            200,
            headers: <String, List<String>>{
              Headers.contentTypeHeader: <String>[Headers.jsonContentType],
            },
          );
        });

      final dataSource = ApiUserContextRemoteDataSource(dio);

      final context = await dataSource.loadUserContext(userId: 'client-1');

      check(context.activeStoreId).equals('client-account');
      check(
        context.access.permissions.contains(UserPermission.viewDashboard),
      ).isTrue();
    });
  });
}
