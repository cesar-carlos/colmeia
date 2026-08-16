import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/logging/app_logger.dart';
import 'package:colmeia/core/logging/log_redaction.dart';
import 'package:colmeia/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:colmeia/features/auth/domain/entities/client_registration_status.dart';
import 'package:colmeia/features/auth/domain/entities/client_registration_submission.dart';
import 'package:colmeia/features/auth/domain/repositories/client_registration_repository.dart';
import 'package:dio/dio.dart';
import 'package:result_dart/result_dart.dart';

class ClientRegistrationRepositoryImpl implements ClientRegistrationRepository {
  ClientRegistrationRepositoryImpl({
    required this._remoteDataSource,
  });

  final AuthRemoteDataSource _remoteDataSource;

  @override
  Future<AppResult<ClientRegistrationSubmission>> register({
    required String ownerEmail,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    String? mobile,
  }) async {
    final redactedOwnerEmail = LogRedaction.redactEmail(ownerEmail);
    final redactedEmail = LogRedaction.redactEmail(email);
    try {
      final submission = await _remoteDataSource.register(
        ownerEmail: ownerEmail,
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        mobile: mobile,
      );

      AppLogger.info(
        'register_submitted',
        context: <String, Object?>{
          'operation': 'register',
          'ownerEmail': redactedOwnerEmail,
          'email': redactedEmail,
          'status': submission.status.wireValue,
          'duplicate': submission.duplicate,
          'canPollStatus': submission.canPollStatus,
        },
      );
      return Success<ClientRegistrationSubmission, AppFailure>(submission);
    } on DioException catch (error, stackTrace) {
      final statusCode = error.response?.statusCode;
      final failure = statusCode == 400
          ? ValidationFailure(
              message: 'Owner e-mail is not eligible for client registration',
              cause: error,
              stackTrace: stackTrace,
              context: <String, Object?>{
                'operation': 'register',
                'ownerEmail': redactedOwnerEmail,
                'email': redactedEmail,
                'statusCode': statusCode,
              },
            )
          : mapToAppFailure(
              error,
              stackTrace: stackTrace,
              fallbackMessage: 'Unable to submit client register request',
              context: <String, Object?>{
                'operation': 'register',
                'ownerEmail': redactedOwnerEmail,
                'email': redactedEmail,
                'statusCode': statusCode,
              },
            );
      AppLogger.warning(
        'Client registration request failed',
        context: <String, Object?>{
          'operation': 'register',
          'ownerEmail': redactedOwnerEmail,
          'email': redactedEmail,
          'statusCode': statusCode,
        },
        error: error,
        stackTrace: stackTrace,
      );
      return Failure<ClientRegistrationSubmission, AppFailure>(failure);
    } on Object catch (error, stackTrace) {
      AppLogger.error(
        'Unexpected client registration failure',
        context: <String, Object?>{
          'operation': 'register',
          'ownerEmail': redactedOwnerEmail,
          'email': redactedEmail,
        },
        error: error,
        stackTrace: stackTrace,
      );
      return Failure<ClientRegistrationSubmission, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to submit client register request',
          context: <String, Object?>{
            'operation': 'register',
            'ownerEmail': redactedOwnerEmail,
            'email': redactedEmail,
          },
        ),
      );
    }
  }

  @override
  Future<AppResult<String>> retryClientRegistration({
    required String ownerEmail,
    required String email,
    required String password,
  }) async {
    final redactedOwnerEmail = LogRedaction.redactEmail(ownerEmail);
    final redactedEmail = LogRedaction.redactEmail(email);
    try {
      final message = await _remoteDataSource.retryClientRegistration(
        ownerEmail: ownerEmail,
        email: email,
        password: password,
      );
      AppLogger.info(
        'retry_submitted',
        context: <String, Object?>{
          'operation': 'retryClientRegistration',
          'ownerEmail': redactedOwnerEmail,
          'email': redactedEmail,
        },
      );
      return Success<String, AppFailure>(message);
    } on DioException catch (error, stackTrace) {
      final statusCode = error.response?.statusCode;
      final failure = mapToAppFailure(
        error,
        stackTrace: stackTrace,
        fallbackMessage: 'Unable to retry client registration',
        context: <String, Object?>{
          'operation': 'retryClientRegistration',
          'ownerEmail': redactedOwnerEmail,
          'email': redactedEmail,
          'statusCode': statusCode,
        },
      );
      AppLogger.warning(
        'Client registration retry failed',
        context: <String, Object?>{
          'operation': 'retryClientRegistration',
          'ownerEmail': redactedOwnerEmail,
          'email': redactedEmail,
          'statusCode': statusCode,
        },
        error: error,
        stackTrace: stackTrace,
      );
      return Failure<String, AppFailure>(failure);
    } on Object catch (error, stackTrace) {
      AppLogger.error(
        'Unexpected client registration retry failure',
        context: <String, Object?>{
          'operation': 'retryClientRegistration',
          'ownerEmail': redactedOwnerEmail,
          'email': redactedEmail,
        },
        error: error,
        stackTrace: stackTrace,
      );
      return Failure<String, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to retry client registration',
          context: <String, Object?>{
            'operation': 'retryClientRegistration',
            'ownerEmail': redactedOwnerEmail,
            'email': redactedEmail,
          },
        ),
      );
    }
  }

  @override
  Future<AppResult<ClientRegistrationStatus>> readRegistrationStatus({
    required String token,
  }) async {
    try {
      final status = await _remoteDataSource.readRegistrationStatus(
        token: token,
      );
      AppLogger.info(
        'poll_status_resolved',
        context: <String, Object?>{
          'operation': 'readRegistrationStatus',
          'status': status.wireValue,
          'tokenLength': token.length,
        },
      );
      return Success<ClientRegistrationStatus, AppFailure>(status);
    } on DioException catch (error, stackTrace) {
      final statusCode = error.response?.statusCode;
      final failure = switch (statusCode) {
        400 || 404 => ValidationFailure(
          message: 'Client registration token not found',
          cause: error,
          stackTrace: stackTrace,
          context: <String, Object?>{
            'operation': 'readRegistrationStatus',
            'statusCode': statusCode,
          },
        ),
        410 => ValidationFailure(
          message: 'Client registration token expired',
          cause: error,
          stackTrace: stackTrace,
          context: <String, Object?>{
            'operation': 'readRegistrationStatus',
            'statusCode': statusCode,
          },
        ),
        _ => mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to read registration status',
          context: <String, Object?>{
            'operation': 'readRegistrationStatus',
            'statusCode': statusCode,
          },
        ),
      };
      return Failure<ClientRegistrationStatus, AppFailure>(failure);
    } on Object catch (error, stackTrace) {
      AppLogger.error(
        'Unable to read client registration status',
        context: const <String, Object?>{
          'operation': 'readRegistrationStatus',
        },
        error: error,
        stackTrace: stackTrace,
      );
      return Failure<ClientRegistrationStatus, AppFailure>(
        mapToAppFailure(
          error,
          stackTrace: stackTrace,
          fallbackMessage: 'Unable to read registration status',
          context: const <String, Object?>{
            'operation': 'readRegistrationStatus',
          },
        ),
      );
    }
  }
}
