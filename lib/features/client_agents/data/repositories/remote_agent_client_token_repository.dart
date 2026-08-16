import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/features/client_agents/data/datasources/client_agents_remote_datasource.dart';
import 'package:colmeia/features/client_agents/data/models/client_agent_token_request_dto.dart';
import 'package:colmeia/features/client_agents/data/storage/local_agent_client_token_store.dart';
import 'package:colmeia/features/client_agents/domain/client_agents_failure_ui_key.dart';
import 'package:colmeia/features/client_agents/domain/entities/client_agent_token_snapshot.dart';
import 'package:colmeia/features/client_agents/domain/repositories/agent_client_token_repository.dart';
import 'package:dio/dio.dart';
import 'package:result_dart/result_dart.dart';

/// Server-primary implementation of [AgentClientTokenRepository] with a local
/// secure-storage cache as offline fallback for reads.
///
/// Writes always go to the server first; the local cache is only updated
/// after a successful PUT, so on conflicts the device never carries a token
/// the server is unaware of. The bulk [readMany] used by the agent_queries
/// SQL pipeline still serves from the local cache to avoid N round trips per
/// dashboard refresh — `saveToken` keeps the cache hot for that path.
class RemoteAgentClientTokenRepository implements AgentClientTokenRepository {
  RemoteAgentClientTokenRepository({
    required this._remoteDataSource,
    required this._localStore,
  });

  static const int _readManyHydrationConcurrency = 6;
  static const Duration _readManyFreshCacheTtl = Duration(minutes: 1);

  final ClientAgentTokenRemoteDataSource _remoteDataSource;
  final LocalAgentClientTokenStore _localStore;

  @override
  Future<AppResult<ClientAgentTokenSnapshot>> getToken({
    required String userId,
    required String agentId,
  }) async {
    final trimmedAgentId = agentId.trim();
    if (trimmedAgentId.isEmpty) {
      return const Failure<ClientAgentTokenSnapshot, AppFailure>(
        ValidationFailure(
          message: 'Agent id is empty',
          userMessage: 'Invalid agent identifier.',
        ),
      );
    }

    try {
      final response = await _remoteDataSource.fetchClientAgentToken(
        agentId: trimmedAgentId,
      );
      final normalized = _normalize(response.clientToken);
      await _syncLocalCache(
        userId: userId,
        agentId: trimmedAgentId,
        token: normalized,
      );
      return Success<ClientAgentTokenSnapshot, AppFailure>(
        ClientAgentTokenSnapshot(token: normalized),
      );
    } on DioException catch (error, stackTrace) {
      if (isDioUnauthorizedOrForbidden(error)) {
        return Failure<ClientAgentTokenSnapshot, AppFailure>(
          mapToAppFailure(
            error,
            stackTrace: stackTrace,
            fallbackMessage: 'Unable to read client agent token',
            fallbackUserMessage:
                'Nao foi possivel ler o token do agente no servidor.',
            context: <String, Object?>{
              'operation': 'getClientAgentToken',
              'userId': userId,
              'agentId': trimmedAgentId,
              ClientAgentsFailureUiKey.field:
                  ClientAgentsFailureUiKey.getClientAgentToken,
            },
          ),
        );
      }
      // Network-level failure: try the local cache so offline screens keep
      // working with the last known token. Logged for observability.
      final cached = await _readLocal(
        userId: userId,
        agentId: trimmedAgentId,
      );
      AppLogger.warning(
        'Client agent token GET failed; serving from local cache',
        context: <String, Object?>{
          'operation': 'getClientAgentToken',
          'userId': userId,
          'agentId': trimmedAgentId,
          'fellBackToCache': cached != null,
        },
        error: error,
        stackTrace: stackTrace,
      );
      if (cached != null) {
        return Success<ClientAgentTokenSnapshot, AppFailure>(
          ClientAgentTokenSnapshot(token: cached),
        );
      }
      return Failure<ClientAgentTokenSnapshot, AppFailure>(
        NetworkFailure(
          message: 'Client agent token GET failed with no local cache',
          userMessage: 'Nao foi possivel ler o token do agente no servidor.',
          cause: error,
          stackTrace: stackTrace,
          context: <String, Object?>{
            'operation': 'getClientAgentToken',
            'userId': userId,
            'agentId': trimmedAgentId,
            ClientAgentsFailureUiKey.field:
                ClientAgentsFailureUiKey.getClientAgentToken,
          },
        ),
      );
    } on Object catch (error, stackTrace) {
      return Failure<ClientAgentTokenSnapshot, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to read client agent token',
          fallbackUserMessage:
              'Nao foi possivel ler o token do agente no servidor.',
          context: <String, Object?>{
            'operation': 'getClientAgentToken',
            'userId': userId,
            'agentId': trimmedAgentId,
            ClientAgentsFailureUiKey.field:
                ClientAgentsFailureUiKey.getClientAgentToken,
          },
        ),
      );
    }
  }

  @override
  Future<AppResult<ClientAgentTokenSnapshot>> saveToken({
    required String userId,
    required String agentId,
    required String clientToken,
  }) async {
    final trimmedAgentId = agentId.trim();
    if (trimmedAgentId.isEmpty) {
      return const Failure<ClientAgentTokenSnapshot, AppFailure>(
        ValidationFailure(
          message: 'Agent id is empty',
          userMessage: 'Invalid agent identifier.',
        ),
      );
    }

    final request = ClientAgentTokenRequestDto(clientToken: clientToken);
    final validationError = request.validationError();
    if (validationError != null) {
      return Failure<ClientAgentTokenSnapshot, AppFailure>(
        ValidationFailure(
          message: validationError,
          userMessage: 'O token excede o limite permitido pelo servidor (512 caracteres).',
          context: <String, Object?>{
            'operation': 'saveClientAgentToken',
            'agentId': trimmedAgentId,
            ClientAgentsFailureUiKey.field:
                ClientAgentsFailureUiKey.saveClientAgentToken,
          },
        ),
      );
    }

    try {
      final response = await _remoteDataSource.putClientAgentToken(
        agentId: trimmedAgentId,
        request: request,
      );
      final normalized = _normalize(response.clientToken);
      await _syncLocalCache(
        userId: userId,
        agentId: trimmedAgentId,
        token: normalized,
      );
      return Success<ClientAgentTokenSnapshot, AppFailure>(
        ClientAgentTokenSnapshot(token: normalized),
      );
    } on DioException catch (error, stackTrace) {
      return Failure<ClientAgentTokenSnapshot, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to save client agent token',
          fallbackUserMessage:
              'Nao foi possivel salvar o token do agente no servidor.',
          context: <String, Object?>{
            'operation': 'saveClientAgentToken',
            'userId': userId,
            'agentId': trimmedAgentId,
            ClientAgentsFailureUiKey.field:
                ClientAgentsFailureUiKey.saveClientAgentToken,
          },
        ),
      );
    } on Object catch (error, stackTrace) {
      return Failure<ClientAgentTokenSnapshot, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to save client agent token',
          fallbackUserMessage:
              'Nao foi possivel salvar o token do agente no servidor.',
          context: <String, Object?>{
            'operation': 'saveClientAgentToken',
            'userId': userId,
            'agentId': trimmedAgentId,
            ClientAgentsFailureUiKey.field:
                ClientAgentsFailureUiKey.saveClientAgentToken,
          },
        ),
      );
    }
  }

  @override
  Future<AppResult<Unit>> removeToken({
    required String userId,
    required String agentId,
  }) async {
    final trimmedAgentId = agentId.trim();
    if (trimmedAgentId.isEmpty) {
      return const Failure<Unit, AppFailure>(
        ValidationFailure(
          message: 'Agent id is empty',
          userMessage: 'Invalid agent identifier.',
        ),
      );
    }

    try {
      await _remoteDataSource.putClientAgentToken(
        agentId: trimmedAgentId,
        request: const ClientAgentTokenRequestDto(clientToken: null),
      );
      await _syncLocalCache(
        userId: userId,
        agentId: trimmedAgentId,
        token: null,
      );
      return const Success<Unit, AppFailure>(unit);
    } on DioException catch (error, stackTrace) {
      return Failure<Unit, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to remove client agent token',
          fallbackUserMessage:
              'Nao foi possivel remover o token do agente no servidor.',
          context: <String, Object?>{
            'operation': 'removeClientAgentToken',
            'userId': userId,
            'agentId': trimmedAgentId,
            ClientAgentsFailureUiKey.field:
                ClientAgentsFailureUiKey.removeClientAgentToken,
          },
        ),
      );
    } on Object catch (error, stackTrace) {
      return Failure<Unit, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to remove client agent token',
          fallbackUserMessage:
              'Nao foi possivel remover o token do agente no servidor.',
          context: <String, Object?>{
            'operation': 'removeClientAgentToken',
            'userId': userId,
            'agentId': trimmedAgentId,
            ClientAgentsFailureUiKey.field:
                ClientAgentsFailureUiKey.removeClientAgentToken,
          },
        ),
      );
    }
  }

  @override
  Future<Map<String, String>> readMany({
    required String userId,
    required Iterable<String> agentIds,
  }) async {
    final normalizedAgentIds = <String>{
      for (final raw in agentIds)
        if (raw.trim().isNotEmpty) raw.trim(),
    };
    if (normalizedAgentIds.isEmpty) {
      return <String, String>{};
    }

    final localRecords = await _localStore.readManyRecords(
      userId: userId,
      agentIds: normalizedAgentIds,
    );
    final now = DateTime.now().toUtc();
    final freshTokens = <String, String>{};
    final staleTokens = <String, String>{};
    for (final entry in localRecords.entries) {
      if (entry.value.isFresh(maxAge: _readManyFreshCacheTtl, now: now)) {
        freshTokens[entry.key] = entry.value.token;
      } else {
        staleTokens[entry.key] = entry.value.token;
      }
    }
    final idsToHydrate = normalizedAgentIds
        .where((agentId) => !freshTokens.containsKey(agentId))
        .toList(growable: false);
    if (idsToHydrate.isEmpty) {
      return freshTokens;
    }

    final merged = <String, String>{...freshTokens};
    for (
      var i = 0;
      i < idsToHydrate.length;
      i += _readManyHydrationConcurrency
    ) {
      final end = i + _readManyHydrationConcurrency > idsToHydrate.length
          ? idsToHydrate.length
          : i + _readManyHydrationConcurrency;
      final chunk = idsToHydrate.sublist(i, end);
      final hydratedEntries = await Future.wait(
        chunk.map(
          (agentId) => _fetchTokenForReadManyHydration(
            userId: userId,
            agentId: agentId,
            staleToken: staleTokens[agentId],
          ),
        ),
      );
      for (final entry in hydratedEntries) {
        switch (entry.kind) {
          case _ReadManyHydrationKind.token:
          case _ReadManyHydrationKind.preserveStale:
            if (entry.token != null) {
              merged[entry.agentId] = entry.token!;
            }
          case _ReadManyHydrationKind.missing:
            merged.remove(entry.agentId);
        }
      }
    }

    return merged;
  }

  Future<_ReadManyHydrationResult> _fetchTokenForReadManyHydration({
    required String userId,
    required String agentId,
    required String? staleToken,
  }) async {
    try {
      final response = await _remoteDataSource.fetchClientAgentToken(
        agentId: agentId,
      );
      final normalized = _normalize(response.clientToken);
      try {
        await _syncLocalCache(
          userId: userId,
          agentId: agentId,
          token: normalized,
        );
      } on Object catch (error, stackTrace) {
        AppLogger.warning(
          'Client token readMany hydration cache sync failed',
          context: <String, Object?>{
            'operation': 'readManyClientAgentTokens',
            'userId': userId,
            'agentId': agentId,
          },
          error: error,
          stackTrace: stackTrace,
        );
      }
      if (normalized == null) {
        return _ReadManyHydrationResult.missing(agentId);
      }
      return _ReadManyHydrationResult.token(agentId, normalized);
    } on DioException catch (error, stackTrace) {
      if (_isAuthoritativeMissingOnReadMany(error)) {
        try {
          await _syncLocalCache(
            userId: userId,
            agentId: agentId,
            token: null,
          );
        } on Object catch (cacheError, cacheStackTrace) {
          AppLogger.warning(
            'Client token readMany authoritative-miss cache clear failed',
            context: <String, Object?>{
              'operation': 'readManyClientAgentTokens',
              'userId': userId,
              'agentId': agentId,
            },
            error: cacheError,
            stackTrace: cacheStackTrace,
          );
        }
        return _ReadManyHydrationResult.missing(agentId);
      }
      AppLogger.warning(
        'Client token readMany hydration failed',
        context: <String, Object?>{
          'operation': 'readManyClientAgentTokens',
          'userId': userId,
          'agentId': agentId,
        },
        error: error,
        stackTrace: stackTrace,
      );
      if (staleToken != null) {
        return _ReadManyHydrationResult.preserveStale(agentId, staleToken);
      }
      return _ReadManyHydrationResult.missing(agentId);
    } on Object catch (error, stackTrace) {
      AppLogger.warning(
        'Client token readMany hydration failed',
        context: <String, Object?>{
          'operation': 'readManyClientAgentTokens',
          'userId': userId,
          'agentId': agentId,
        },
        error: error,
        stackTrace: stackTrace,
      );
      if (staleToken != null) {
        return _ReadManyHydrationResult.preserveStale(agentId, staleToken);
      }
      return _ReadManyHydrationResult.missing(agentId);
    }
  }

  bool _isAuthoritativeMissingOnReadMany(DioException error) {
    final statusCode = error.response?.statusCode;
    return statusCode == 403 || statusCode == 404;
  }

  Future<String?> _readLocal({
    required String userId,
    required String agentId,
  }) {
    return _localStore.read(userId: userId, agentId: agentId);
  }

  Future<void> _syncLocalCache({
    required String userId,
    required String agentId,
    required String? token,
  }) async {
    if (token == null) {
      await _localStore.delete(userId: userId, agentId: agentId);
      return;
    }
    await _localStore.write(
      userId: userId,
      agentId: agentId,
      clientToken: token,
    );
  }

  String? _normalize(String? raw) {
    if (raw == null) {
      return null;
    }
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

enum _ReadManyHydrationKind { token, missing, preserveStale }

class _ReadManyHydrationResult {
  const _ReadManyHydrationResult._({
    required this.agentId,
    required this.kind,
    required this.token,
  });

  const _ReadManyHydrationResult.token(String agentId, String token)
    : this._(
        agentId: agentId,
        kind: _ReadManyHydrationKind.token,
        token: token,
      );

  const _ReadManyHydrationResult.missing(String agentId)
    : this._(
        agentId: agentId,
        kind: _ReadManyHydrationKind.missing,
        token: null,
      );

  const _ReadManyHydrationResult.preserveStale(String agentId, String token)
    : this._(
        agentId: agentId,
        kind: _ReadManyHydrationKind.preserveStale,
        token: token,
      );

  final String agentId;
  final _ReadManyHydrationKind kind;
  final String? token;
}
