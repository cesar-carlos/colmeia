import 'package:colmeia/features/overview/domain/entities/overview.dart';
import 'package:colmeia/features/overview/presentation/overview_agent_alert_names_projection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OverviewAgentAlertNamesProjection.update', () {
    test('exposes empty lists before any overview is provided', () {
      final projection = OverviewAgentAlertNamesProjection();

      expect(projection.missingClientToken, isEmpty);
      expect(projection.partialQueryFailure, isEmpty);
      expect(projection.skippedDueToHubPresence, isEmpty);
    });

    test('exposes empty lists when the projected overview is null', () {
      final projection = OverviewAgentAlertNamesProjection()..update(null);

      expect(projection.missingClientToken, isEmpty);
      expect(projection.partialQueryFailure, isEmpty);
      expect(projection.skippedDueToHubPresence, isEmpty);
    });

    test('normalizes missing-token names (trim, dedupe, sort case-insensitive)',
        () {
      final overview = Overview.empty().copyWith(
        agentNamesMissingClientToken: const <String>[
          '  Bravo  ',
          'alpha',
          'Alpha',
          '   ',
          'Charlie',
        ],
      );

      final projection = OverviewAgentAlertNamesProjection()..update(overview);

      expect(
        projection.missingClientToken,
        <String>['alpha', 'Bravo', 'Charlie'],
      );
    });

    test(
      'merges resumo and lucratividade failure names into partialQueryFailure',
      () {
        final overview = Overview.empty().copyWith(
          agentNamesExcludedFromQueryFailure: const <String>[
            'Resumo Alpha',
            'Shared Agent',
          ],
          lucratividadePartialFailureAgentNames: const <String>[
            'Lucratividade Beta',
            'Shared Agent',
          ],
        );

        final projection =
            OverviewAgentAlertNamesProjection()..update(overview);

        expect(
          projection.partialQueryFailure,
          <String>[
            'Lucratividade Beta',
            'Resumo Alpha',
            'Shared Agent',
          ],
        );
      },
    );

    test('exposes hub-presence skipped names normalized', () {
      final overview = Overview.empty().copyWith(
        agentNamesSkippedDueToHubPresence: const <String>[
          ' offline-one ',
          'Offline-One',
          'offline-two',
        ],
      );

      final projection = OverviewAgentAlertNamesProjection()..update(overview);

      expect(
        projection.skippedDueToHubPresence,
        <String>['offline-one', 'offline-two'],
      );
    });

    test('caches the projection until update is called with a new overview',
        () {
      final overviewA = Overview.empty().copyWith(
        agentNamesMissingClientToken: const <String>['A'],
      );
      final overviewB = Overview.empty().copyWith(
        agentNamesMissingClientToken: const <String>['B'],
      );
      final projection = OverviewAgentAlertNamesProjection()
        ..update(overviewA);
      final firstRead = projection.missingClientToken;
      final secondRead = projection.missingClientToken;

      projection.update(overviewB);
      final thirdRead = projection.missingClientToken;

      expect(identical(firstRead, secondRead), isTrue);
      expect(thirdRead, <String>['B']);
    });

    test('clears cached lists when switching to a null overview', () {
      final overview = Overview.empty().copyWith(
        agentNamesMissingClientToken: const <String>['A'],
        agentNamesExcludedFromQueryFailure: const <String>['B'],
        agentNamesSkippedDueToHubPresence: const <String>['C'],
      );
      final projection = OverviewAgentAlertNamesProjection()..update(overview);

      expect(projection.missingClientToken, isNotEmpty);

      projection.update(null);

      expect(projection.missingClientToken, isEmpty);
      expect(projection.partialQueryFailure, isEmpty);
      expect(projection.skippedDueToHubPresence, isEmpty);
    });
  });
}
