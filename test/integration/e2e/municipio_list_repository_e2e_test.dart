@Tags(['e2e'])
import 'package:colmeia/core/config/app_environment.dart';
import 'package:colmeia/core/di/injector.dart';
import 'package:colmeia/core/errors/app_failure.dart' show SessionFailure;
import 'package:colmeia/features/agent_queries/domain/entities/municipio_list_filter.dart';
import 'package:colmeia/features/agent_queries/domain/repositories/municipio_list_repository.dart';
import 'package:flutter_test/flutter_test.dart' hide group;
import 'package:test_api/scaffolding.dart' show group;

import 'support/e2e_dependency_bootstrap.dart';

/// Direct repository smoke for the paged municipio catalog query.
///
/// Exercises the ROW_NUMBER pagination path and verifies that each row
/// contains a valid CodMunicipio, NomeMunicipio, and UF.
void main() {
  group(
    'MunicipioListRepository (e2e)',
    () {
      test(
        'loadPage page 1 executes the real municipio query through the repository',
        () async {
          final missingKeys = missingE2eRepositoryKeys();
          if (missingKeys.isNotEmpty) {
            // E2E skip hint; `print` is intentional for local diagnostics.
            // ignore: avoid_print
            print(
              'SKIP municipio_list_repository_e2e: missing '
              '${missingKeys.join(', ')}. '
              'Set them in assets/env/local.env, process env, or --dart-define.',
            );
            return;
          }

          await e2eSetupDependencies();
          addTearDown(e2eTeardownDependencies);

          final repository = getIt<MunicipioListRepository>();

          final result = await repository.loadPage(
            userId: 'user-1',
            agentId: AppEnvironment.e2eAgentId,
            clientToken: AppEnvironment.e2eClientToken,
            filter: const MunicipioListFilter(),
          );

          result.fold(
            (page) {
              expect(page.totalCount, greaterThanOrEqualTo(0));
              expect(
                page.items.length,
                lessThanOrEqualTo(20),
                reason: 'Page must not exceed requested pageSize',
              );
              for (final row in page.items) {
                expect(row.codMunicipio, greaterThan(0));
                expect(row.nomeMunicipio, isNotEmpty);
                expect(row.uf, isNotEmpty);
                expect(row.nomeEstado, isNotEmpty);
              }
            },
            (failure) {
              expect(
                failure,
                isNot(isA<SessionFailure>()),
                reason:
                    'Unexpected HTTP 401 after client login '
                    '— check E2E_* values.',
              );
              expect(
                isAcceptableE2eAgentSqlRepositoryFailure(failure),
                isTrue,
                reason:
                    'Repository e2e should return rows, invalid_policy / '
                    'missing_permission RPC, or transient bridge HTTP 5xx.',
              );
            },
          );
        },
      );
    },
    tags: <String>['e2e'],
  );
}
