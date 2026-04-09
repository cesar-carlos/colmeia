/// Named SQL templates for JSON-RPC `sql.execute` via the plug_server bridge.
///
/// Split domain-heavy query groups into separate files under `data/queries/`
/// (for example `sales_agent_sql.dart`) as the catalog grows.
abstract final class ExampleAgentSql {
  /// Sanity check against the connected agent; safe for smoke tests.
  static const String selectOne = 'SELECT 1 AS value';

  /// Example with named parameters (`:id` style — see plug_agente / hub docs).
  static const String selectByIdTemplate =
      'SELECT * FROM example_table WHERE id = :id LIMIT 1';

  /// Example for offset pagination (requires stable `ORDER BY` in the SQL).
  static const String orderedExampleTemplate =
      'SELECT id, name FROM example_table ORDER BY id';
}
