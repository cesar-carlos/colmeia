import 'package:colmeia/features/agent_queries/domain/entities/resumo_parcelas_anual_row.dart';

class ResumoParcelasAnualRowModel {
  const ResumoParcelasAnualRowModel({
    required this.ano,
    required this.quantidade,
    required this.valorTotal,
  });

  factory ResumoParcelasAnualRowModel.fromMap(Map<String, dynamic> map) {
    return ResumoParcelasAnualRowModel(
      ano: _readRequiredIntKeys(map, _keysCodEmpresaStyle('Ano')),
      quantidade: _readRequiredIntKeys(
        map,
        _keysCodEmpresaStyle('Quantidade'),
      ),
      valorTotal: _readRequiredDoubleKeys(
        map,
        _keysCodEmpresaStyle('ValorTotal'),
      ),
    );
  }

  final int ano;
  final int quantidade;
  final double valorTotal;

  ResumoParcelasAnualRow toEntity() {
    return ResumoParcelasAnualRow(
      ano: ano,
      quantidade: quantidade,
      valorTotal: valorTotal,
    );
  }

  static List<String> _keysCodEmpresaStyle(String pascal) {
    return <String>[
      pascal,
      _pascalToCamel(pascal),
      pascal.toLowerCase(),
    ];
  }

  static String _pascalToCamel(String pascal) {
    if (pascal.isEmpty) {
      return pascal;
    }
    return pascal[0].toLowerCase() + pascal.substring(1);
  }

  static Object? _lookupFirst(Map<String, dynamic> map, List<String> keys) {
    for (final k in keys) {
      if (map.containsKey(k)) {
        return map[k];
      }
    }
    return null;
  }

  static int _readRequiredIntKeys(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    final value = _lookupFirst(map, keys);
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
    throw FormatException(
      'Invalid or missing "${keys.first}" in agent SQL row',
    );
  }

  static double _readRequiredDoubleKeys(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    final value = _lookupFirst(map, keys);
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
    throw FormatException(
      'Invalid or missing "${keys.first}" in agent SQL row',
    );
  }
}
