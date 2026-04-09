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

    test(
      'should preserve explicit nested access without forcing dashboard access',
      () async {
        final dio = AppDioClient.create()
          ..httpClientAdapter = _TestHttpClientAdapter((_) async {
            return ResponseBody.fromString(
              jsonEncode(<String, Object?>{
                'data': <String, Object?>{
                  'id': 'client-2',
                  'email': 'client2@corp.com',
                  'status': 'active',
                  'name': 'Bia',
                  'lastName': 'Souza',
                  'access': <String, Object?>{
                    'scope': <String, Object?>{
                      'userContext': <String, Object?>{
                        'viewClientAgents': true,
                        'allowedStores': <Map<String, String>>[
                          <String, String>{'id': 'store-9', 'name': 'Loja 9'},
                        ],
                        'activeStoreId': 'store-9',
                      },
                    },
                  },
                },
              }),
              200,
              headers: <String, List<String>>{
                Headers.contentTypeHeader: <String>[Headers.jsonContentType],
              },
            );
          });

        final dataSource = ApiUserContextRemoteDataSource(dio);

        final context = await dataSource.loadUserContext(userId: 'client-2');

        check(
          context.access.permissions.contains(UserPermission.manageAgents),
        ).isTrue();
        check(
          context.access.permissions.contains(UserPermission.viewDashboard),
        ).isFalse();
        check(context.activeStoreId).equals('store-9');
      },
    );

    test('should read explicit dashboard grants from nested access scope', () async {
      final dio = AppDioClient.create()
        ..httpClientAdapter = _TestHttpClientAdapter((_) async {
          return ResponseBody.fromString(
            jsonEncode(<String, Object?>{
              'data': <String, Object?>{
                'id': 'client-3',
                'email': 'client3@corp.com',
                'status': 'active',
                'name': 'Caio',
                'lastName': 'Lima',
                'access': <String, Object?>{
                  'scope': <String, Object?>{
                    'dashboardGrants': <Map<String, Object?>>[
                      <String, Object?>{
                        'dashboardId': 'dashboard_main',
                        'allowedFilterKeys': <String>['store', 'referenceDate'],
                      },
                    ],
                    'allowedStores': <Map<String, String>>[
                      <String, String>{'id': 'store-1', 'name': 'Loja 1'},
                    ],
                    'activeStoreId': 'store-1',
                  },
                },
              },
            }),
            200,
            headers: <String, List<String>>{
              Headers.contentTypeHeader: <String>[Headers.jsonContentType],
            },
          );
        });

      final dataSource = ApiUserContextRemoteDataSource(dio);

      final context = await dataSource.loadUserContext(userId: 'client-3');

      check(
        context.access.permissions.contains(UserPermission.viewDashboard),
      ).isTrue();
      check(context.access.dashboardGrants).length.equals(1);
      check(context.access.dashboardGrants.single.dashboardId).equals(
        'dashboard_main',
      );
      check(context.activeStoreId).equals('store-1');
    });
  });
}
