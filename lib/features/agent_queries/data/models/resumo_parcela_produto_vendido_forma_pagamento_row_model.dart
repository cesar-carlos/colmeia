import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcela_produto_vendido_forma_pagamento_row.dart';

class ResumoParcelaProdutoVendidoFormaPagamentoRowModel {
  const ResumoParcelaProdutoVendidoFormaPagamentoRowModel({
    required this.codEmpresa,
    required this.codFilial,
    required this.nomeUsuario,
    required this.codFormaPagamento,
    required this.descricaoFormaPagamento,
    required this.qtdVendas,
    required this.valorParcela,
  });

  factory ResumoParcelaProdutoVendidoFormaPagamentoRowModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return ResumoParcelaProdutoVendidoFormaPagamentoRowModel(
      codEmpresa: _readRequiredInt(map, 'CodEmpresa'),
      codFilial: _readRequiredInt(map, 'CodFilial'),
      nomeUsuario: _readRequiredString(map, 'NomeUsuario'),
      codFormaPagamento: _readRequiredString(map, 'CodFormaPagamento'),
      descricaoFormaPagamento: _readRequiredString(
        map,
        'DescricaoFormaPagamento',
      ),
      qtdVendas: _readRequiredInt(map, 'QtdVendas'),
      valorParcela: _readRequiredDouble(map, 'ValorParcela'),
    );
  }

  final int codEmpresa;
  final int codFilial;
  final String nomeUsuario;
  final String codFormaPagamento;
  final String descricaoFormaPagamento;
  final int qtdVendas;
  final double valorParcela;

  ResumoParcelaProdutoVendidoFormaPagamentoRow toEntity() {
    return ResumoParcelaProdutoVendidoFormaPagamentoRow(
      codEmpresa: codEmpresa,
      codFilial: codFilial,
      nomeUsuario: nomeUsuario,
      codFormaPagamento: codFormaPagamento,
      descricaoFormaPagamento: descricaoFormaPagamento,
      qtdVendas: qtdVendas,
      valorParcela: valorParcela,
    );
  }

  static int _readRequiredInt(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) {
        return parsed;
      }
    }
    throw FormatException('Invalid or missing "$key" in agent SQL row');
  }

  static double _readRequiredDouble(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is double) {
      return value;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      final normalized = value.trim().replaceAll(',', '.');
      final parsed = double.tryParse(normalized);
      if (parsed != null) {
        return parsed;
      }
    }
    throw FormatException('Invalid or missing "$key" in agent SQL row');
  }

  static String _readRequiredString(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    throw FormatException('Invalid or missing "$key" in agent SQL row');
  }
}
