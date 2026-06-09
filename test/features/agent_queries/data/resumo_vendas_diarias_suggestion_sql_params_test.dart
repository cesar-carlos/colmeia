import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/resumo_vendas_diarias_suggestion_sql_params.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('clampLimit', () {
    test('enforces minimum 1', () {
      check(
        ResumoVendasDiariasSuggestionSqlParams.clampLimit(0),
      ).equals(1);
    });

    test('caps at maxSuggestionFetchLimit', () {
      check(
        ResumoVendasDiariasSuggestionSqlParams.clampLimit(500),
      ).equals(ResumoVendasDiariasSuggestionSqlParams.maxSuggestionFetchLimit);
    });

    test('passes through in range', () {
      check(ResumoVendasDiariasSuggestionSqlParams.clampLimit(42)).equals(42);
    });
  });

  group('perAgentSuggestionFetchLimit', () {
    test('scales by planned target count', () {
      check(
        ResumoVendasDiariasSuggestionSqlParams.perAgentSuggestionFetchLimit(
          mergeResultLimit: 20,
          plannedTargetCount: 2,
        ),
      ).equals(40);
    });

    test('single target matches merge limit', () {
      check(
        ResumoVendasDiariasSuggestionSqlParams.perAgentSuggestionFetchLimit(
          mergeResultLimit: 15,
          plannedTargetCount: 1,
        ),
      ).equals(15);
    });

    test('caps product at maxSuggestionFetchLimit', () {
      check(
        ResumoVendasDiariasSuggestionSqlParams.perAgentSuggestionFetchLimit(
          mergeResultLimit: 50,
          plannedTargetCount: 5,
        ),
      ).equals(ResumoVendasDiariasSuggestionSqlParams.maxSuggestionFetchLimit);
    });

    test('treats zero planned targets as one for multiplier', () {
      check(
        ResumoVendasDiariasSuggestionSqlParams.perAgentSuggestionFetchLimit(
          mergeResultLimit: 20,
          plannedTargetCount: 0,
        ),
      ).equals(20);
    });
  });

  group('buildSearchPattern', () {
    test('returns null for null or blank', () {
      check(
        ResumoVendasDiariasSuggestionSqlParams.buildSearchPattern(null),
      ).isNull();
      check(
        ResumoVendasDiariasSuggestionSqlParams.buildSearchPattern('  '),
      ).isNull();
    });

    test('wraps trimmed term with percent wildcards', () {
      check(
        ResumoVendasDiariasSuggestionSqlParams.buildSearchPattern('  ab '),
      ).equals('%ab%');
    });

    test('escapes LIKE metacharacters', () {
      check(
        ResumoVendasDiariasSuggestionSqlParams.buildSearchPattern('a%b_c[d'),
      ).equals('%a[%]b[_]c[[]d%');
    });
  });

  group('buildDigitsOnlySearchPattern', () {
    test('returns null when term is not digits-only', () {
      check(
        ResumoVendasDiariasSuggestionSqlParams.buildDigitsOnlySearchPattern(
          '35503a',
        ),
      ).isNull();
      check(
        ResumoVendasDiariasSuggestionSqlParams.buildDigitsOnlySearchPattern(
          null,
        ),
      ).isNull();
    });

    test('wraps digits-only term with percent wildcards', () {
      check(
        ResumoVendasDiariasSuggestionSqlParams.buildDigitsOnlySearchPattern(
          ' 3550308 ',
        ),
      ).equals('%3550308%');
    });
  });

  group('buildPrefixSearchPattern', () {
    test('returns null for null or blank', () {
      check(
        ResumoVendasDiariasSuggestionSqlParams.buildPrefixSearchPattern(null),
      ).isNull();
      check(
        ResumoVendasDiariasSuggestionSqlParams.buildPrefixSearchPattern('  '),
      ).isNull();
    });

    test('uses trailing percent only', () {
      check(
        ResumoVendasDiariasSuggestionSqlParams.buildPrefixSearchPattern(
          ' Cur ',
        ),
      ).equals('Cur%');
    });

    test('escapes LIKE metacharacters', () {
      check(
        ResumoVendasDiariasSuggestionSqlParams.buildPrefixSearchPattern(
          'a%b_c[d',
        ),
      ).equals('a[%]b[_]c[[]d%');
    });
  });
}
