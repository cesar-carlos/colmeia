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

  test('report SQL execute requests opt into streaming relay', () {
    final missing = <String>[];

    for (final file in _streamingReportFiles()) {
      final source = file.readAsStringSync();
      final parsed = parseString(
        content: source,
        path: file.path,
        throwIfDiagnostics: false,
      );
      parsed.unit.accept(
        _StreamingRelayVisitor(
          filePath: file.path,
          lineInfo: parsed.lineInfo,
          missing: missing,
        ),
      );
    }

    check(missing).isEmpty();
  });

  test('small lookup repositories remain unary relay', () {
    for (final file in _smallLookupFiles()) {
      final source = file.readAsStringSync();
      check(
        source.contains('relayMode: AgentSqlRelayMode.streaming'),
      ).isFalse();
      check(source.contains('preferDbStreaming: true')).isFalse();
    }
  });

  test('known unary report exceptions stay on relay unary', () {
    final missing = <String>[];

    for (final file in _unaryReportExceptionFiles()) {
      final source = file.readAsStringSync();
      final parsed = parseString(
        content: source,
        path: file.path,
        throwIfDiagnostics: false,
      );
      parsed.unit.accept(
        _UnaryReportExceptionVisitor(
          filePath: file.path,
          lineInfo: parsed.lineInfo,
          missing: missing,
        ),
      );
    }

    check(missing).isEmpty();
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

Iterable<File> _streamingReportFiles() sync* {
  const fileNames = <String>{
    'resumo_parcela_forma_pagamento_diario_repository_impl.dart',
    'resumo_parcela_forma_pagamento_repository_impl.dart',
    'resumo_parcelas_anual_repository_impl.dart',
    'resumo_parcelas_dia_semana_repository_impl.dart',
    'resumo_parcelas_dia_semana_usuario_repository_impl.dart',
    'resumo_parcelas_forma_pagamento_por_mes_repository_impl.dart',
    'resumo_parcelas_mensal_repository_impl.dart',
    'resumo_total_vendas_municipio_filial_diario_repository_impl.dart',
    'resumo_vendas_diarias_por_vendedor_repository_impl.dart',
  };
  for (final fileName in fileNames) {
    yield File(_repositoryPath(fileName));
  }
}

Iterable<File> _smallLookupFiles() sync* {
  const fileNames = <String>{
    'cadastro_filial_repository_impl.dart',
    'grupo_produto_options_repository_impl.dart',
    'marca_produto_options_repository_impl.dart',
    'municipio_list_repository_impl.dart',
    'resumo_vendas_diarias_por_vendedor_filter_options_repository_impl.dart',
  };
  for (final fileName in fileNames) {
    yield File(_repositoryPath(fileName));
  }
}

/// Report repositories that must stay relay unary (not streaming) until an
/// agent/hub defect is fixed. Keep in sync with
/// `docs/bridge_agent_sql_api_options.md`.
Iterable<File> _unaryReportExceptionFiles() sync* {
  const fileNames = <String>{
    'ranking_produtos_faturamento_repository_impl.dart',
    'produto_vendido_produto_rank_lucro_repository_impl.dart',
    'resumo_produto_venda_lucratividade_mensal_repository_impl.dart',
    'resumo_produto_venda_lucratividade_repository_impl.dart',
    'resumo_produto_venda_repository_impl.dart',
    'produto_vendido_tendencia_de_venda_repository_impl.dart',
    'produto_vendido_tendencia_de_venda_media_movel_repository_impl.dart',
    'resumo_total_diario_vendas_repository_impl.dart',
    'resumo_total_vendas_municipio_filial_periodo_repository_impl.dart',
  };
  for (final fileName in fileNames) {
    yield File(_repositoryPath(fileName));
  }
}

String _repositoryPath(String fileName) =>
    'lib/features/agent_queries/data/repositories/$fileName';

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

final class _StreamingRelayVisitor extends RecursiveAstVisitor<void> {
  _StreamingRelayVisitor({
    required this.filePath,
    required this.lineInfo,
    required this.missing,
  });

  final String filePath;
  final LineInfo lineInfo;
  final List<String> missing;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    super.visitInstanceCreationExpression(node);

    if (node.constructorName.type.name.lexeme != 'AgentSqlExecuteRequest') {
      return;
    }
    if (!_isUseRelayTrue(node)) {
      return;
    }

    final relayMode = _namedExpression(node, 'relayMode')?.expression;
    if (relayMode?.toSource() != 'AgentSqlRelayMode.streaming') {
      missing.add('${_location(node)} missing relayMode.streaming');
    }

    final executeOptions = _namedExpression(node, 'executeOptions')?.expression;
    if (executeOptions is! InstanceCreationExpression ||
        !_hasBooleanArgument(executeOptions, 'preferDbStreaming', true)) {
      missing.add('${_location(node)} missing preferDbStreaming true');
    }
  }

  bool _isUseRelayTrue(InstanceCreationExpression node) {
    final useRelay = _namedExpression(node, 'useRelay')?.expression;
    return useRelay is BooleanLiteral && useRelay.value;
  }

  NamedExpression? _namedExpression(
    InstanceCreationExpression node,
    String name,
  ) {
    for (final argument
        in node.argumentList.arguments.whereType<NamedExpression>()) {
      if (argument.name.label.name == name) {
        return argument;
      }
    }
    return null;
  }

  bool _hasBooleanArgument(
    InstanceCreationExpression node,
    String name,
    bool value,
  ) {
    final expression = _namedExpression(node, name)?.expression;
    return expression is BooleanLiteral && expression.value == value;
  }

  String _location(AstNode node) {
    final line = lineInfo.getLocation(node.offset).lineNumber;
    return '$filePath:$line';
  }
}

final class _UnaryReportExceptionVisitor extends RecursiveAstVisitor<void> {
  _UnaryReportExceptionVisitor({
    required this.filePath,
    required this.lineInfo,
    required this.missing,
  });

  final String filePath;
  final LineInfo lineInfo;
  final List<String> missing;

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    super.visitInstanceCreationExpression(node);

    if (node.constructorName.type.name.lexeme != 'AgentSqlExecuteRequest') {
      return;
    }
    if (!_isUseRelayTrue(node)) {
      return;
    }

    final relayMode = _namedExpression(node, 'relayMode')?.expression;
    if (relayMode?.toSource() != 'AgentSqlRelayMode.unary') {
      missing.add('${_location(node)} missing relayMode.unary');
    }

    final executeOptions = _namedExpression(node, 'executeOptions')?.expression;
    if (executeOptions is! InstanceCreationExpression ||
        !_hasBooleanArgument(executeOptions, 'preferDbStreaming', false)) {
      missing.add('${_location(node)} missing preferDbStreaming false');
    }
  }

  bool _isUseRelayTrue(InstanceCreationExpression node) {
    final useRelay = _namedExpression(node, 'useRelay')?.expression;
    return useRelay is BooleanLiteral && useRelay.value;
  }

  NamedExpression? _namedExpression(
    InstanceCreationExpression node,
    String name,
  ) {
    for (final argument
        in node.argumentList.arguments.whereType<NamedExpression>()) {
      if (argument.name.label.name == name) {
        return argument;
      }
    }
    return null;
  }

  bool _hasBooleanArgument(
    InstanceCreationExpression node,
    String name,
    bool value,
  ) {
    final expression = _namedExpression(node, name)?.expression;
    return expression is BooleanLiteral && expression.value == value;
  }

  String _location(AstNode node) {
    final line = lineInfo.getLocation(node.offset).lineNumber;
    return '$filePath:$line';
  }
}
