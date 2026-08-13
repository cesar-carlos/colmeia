import 'dart:async';

import 'package:colmeia/core/errors/app_failure.dart';
import 'package:colmeia/core/errors/app_result.dart';
import 'package:colmeia/core/socket/socket_dispatch_exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:result_dart/result_dart.dart';

import 'e2e_across_agents_report.dart';
import 'e2e_dependency_bootstrap.dart';

void main() {
  group('runE2eAcrossAgentsResult', () {
    test('returns the inner success', () async {
      final result = await runE2eAcrossAgentsResult(
        () async => const Success<String, AppFailure>('ok'),
        clientTimeout: const Duration(seconds: 1),
      );

      expect(result.getOrNull(), 'ok');
    });

    test('maps a hung action to an acceptable NetworkFailure', () async {
      final pending = Completer<AppResult<String>>();
      final result = await runE2eAcrossAgentsResult(
        () => pending.future,
        clientTimeout: const Duration(milliseconds: 40),
      );

      result.fold((_) => fail('expected timeout failure'), (failure) {
        expect(failure, isA<NetworkFailure>());
        expect(failure.cause, isA<SocketDispatchTimeout>());
        expect(isAcceptableE2eAgentSqlRepositoryFailure(failure), isTrue);
      });
    });
  });
}
