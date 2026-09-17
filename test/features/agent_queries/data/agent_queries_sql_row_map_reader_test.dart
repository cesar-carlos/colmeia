import 'package:checks/checks.dart';
import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AgentQueriesSqlRowMapReader.readOptionalDoubleStrict', () {
    const keys = <String>['CustoReposicao', 'custoReposicao'];

    test('returns null for missing, null, or blank values', () {
      check(
        AgentQueriesSqlRowMapReader.readOptionalDoubleStrict(
          const <String, dynamic>{},
          keys,
        ),
      ).isNull();
      check(
        AgentQueriesSqlRowMapReader.readOptionalDoubleStrict(
          const <String, dynamic>{'CustoReposicao': null},
          keys,
        ),
      ).isNull();
      check(
        AgentQueriesSqlRowMapReader.readOptionalDoubleStrict(
          const <String, dynamic>{'CustoReposicao': '  '},
          keys,
        ),
      ).isNull();
    });

    test('parses num and localized numeric strings', () {
      check(
        AgentQueriesSqlRowMapReader.readOptionalDoubleStrict(
          const <String, dynamic>{'CustoReposicao': 10},
          keys,
        ),
      ).equals(10);
      check(
        AgentQueriesSqlRowMapReader.readOptionalDoubleStrict(
          const <String, dynamic>{'custoReposicao': '12,5'},
          keys,
        ),
      ).equals(12.5);
    });

    test('throws when a present value is not numeric', () {
      check(
        () => AgentQueriesSqlRowMapReader.readOptionalDoubleStrict(
          const <String, dynamic>{'CustoReposicao': 'abc'},
          keys,
        ),
      ).throws<FormatException>();
      check(
        () => AgentQueriesSqlRowMapReader.readOptionalDoubleStrict(
          const <String, dynamic>{'CustoReposicao': true},
          keys,
        ),
      ).throws<FormatException>();
    });
  });
}
