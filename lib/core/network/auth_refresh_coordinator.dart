import 'dart:async';

import 'package:colmeia/core/network/api_routes.dart';
import 'package:colmeia/core/network/auth_request_options.dart';
import 'package:colmeia/core/network/auth_session_accessor.dart';
import 'package:colmeia/core/network/auth_session_events.dart';
import 'package:colmeia/features/auth/data/models/client_refresh_response_dto.dart';
import 'package:dio/dio.dart';

class AuthRefreshCoordinator {
  AuthRefreshCoordinator({
    required Dio refreshDio,
    required AuthSessionAccessor sessionAccessor,
    required AuthSessionEvents sessionEvents,
  }) : _refreshDio = refreshDio,
       _sessionAccessor = sessionAccessor,
       _sessionEvents = sessionEvents;

  final Dio _refreshDio;
  final AuthSessionAccessor _sessionAccessor;
  final AuthSessionEvents _sessionEvents;

  Future<String?>? _inFlightRefresh;

  Future<String?> refreshAccessToken() {
    final inFlight = _inFlightRefresh;
    if (inFlight != null) {
      return inFlight;
    }

    final operation = _refresh().whenComplete(() {
      _inFlightRefresh = null;
    });
    _inFlightRefresh = operation;
    return operation;
  }

  Future<String?> _refresh() async {
    final currentSession = await _sessionAccessor.read();
    if (currentSession == null) {
      return null;
    }

    try {
      final response = await _refreshDio.post<Map<String, dynamic>>(
        ClientAuthApiRoutes.refresh,
        data: <String, Object?>{
          'refreshToken': currentSession.refreshToken,
        },
        options: Options(
          extra: <String, Object?>{
            AuthRequestOptions.skipAuth: true,
          },
        ),
      );
      final responseBody = response.data;
      if (responseBody == null) {
        throw const FormatException('Refresh response is null');
      }
      final refreshedSession =
          ClientRefreshResponseDto.fromJson(
            responseBody,
          ).tokens.toSessionModel(
            userId: currentSession.userId,
            email: currentSession.email,
            role: currentSession.role,
            accountStatus: currentSession.accountStatus,
          );
      await _sessionAccessor.save(refreshedSession);
      return refreshedSession.accessToken;
    } on Object {
      await _sessionAccessor.clear();
      _sessionEvents.notifyInvalidated();
      rethrow;
    }
  }
}
