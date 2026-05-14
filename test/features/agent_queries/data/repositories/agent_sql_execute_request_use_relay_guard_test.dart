import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:checks/checks.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('SQL execute requests declare an explicit relay route', () {
    final missing = <String>[];
    final forbiddenFalse = <String>[];

    for (final file in _sourceFiles()) {
      final source = file.readAsStringSync();
      final parsed = parseString(
        content: source,
        path: file.path,
        throwIfDiagnostics: false,
      );
      parsed.unit.accept(
        _SqlRequestRelayVisitor(
          filePath: file.path,
          lineInfo: parsed.lineInfo,
          missing: missing,
          forbiddenFalse: forbiddenFalse,
        ),
      );
    }

    check(missing).isEmpty();
    check(forbiddenFalse).isEmpty();
  });
}

Iterable<File> _sourceFiles() sync* {
  final roots = <Directory>[
    Directory('lib/features/agent_queries/data/repositories'),
    Directory('lib/features/overview/data'),
  ];
  for (final root in roots) {
    for (final entity in root.listSync(recursive: true)) {
      if (entity is File && entity.path.endsWith('.dart')) {
        yield entity;
      }
    }
  }
}

final class _SqlRequestRelayVisitor extends RecursiveAstVisitor<void> {
  _SqlRequestRelayVisitor({
    required this.filePath,
    required this.lineInfo,
    required this.missing,
    required this.forbiddenFalse,
  });

  static const _requestTypes = <String>{
    'AgentSqlExecuteRequest',
    'AgentSqlExecuteBatchRequest',
  };

  static const _falseRelayAllowlist = <String>{};

  final String filePath;
  final LineInfo lineInfo;
  final List<String> missing;
  final List<String> forbiddenFalse;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    super.visitInstanceCreationExpression(node);

    final typeName = node.constructorName.type.name.lexeme;
    if (!_requestTypes.contains(typeName)) {
      return;
    }

    NamedExpression? useRelayArgument;
    for (final argument
        in node.argumentList.arguments.whereType<NamedExpression>()) {
      if (argument.name.label.name == 'useRelay') {
        useRelayArgument = argument;
        break;
      }
    }
    final location = _location(node);

    if (useRelayArgument == null) {
      missing.add(location);
      return;
    }

    final expression = useRelayArgument.expression;
    if (expression is BooleanLiteral &&
        !expression.value &&
        !_falseRelayAllowlist.contains(location)) {
      forbiddenFalse.add(location);
    }
  }

  String _location(AstNode node) {
    final line = lineInfo.getLocation(node.offset).lineNumber;
    return '$filePath:$line';
  }
}
