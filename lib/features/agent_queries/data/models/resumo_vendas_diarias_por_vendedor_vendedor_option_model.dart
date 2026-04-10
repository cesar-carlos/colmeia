import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_vendedor_option.dart';

class ResumoVendasDiariasPorVendedorVendedorOptionModel {
  const ResumoVendasDiariasPorVendedorVendedorOptionModel({
    required this.codVendedor,
    required this.nomeVendedor,
  });

  factory ResumoVendasDiariasPorVendedorVendedorOptionModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return ResumoVendasDiariasPorVendedorVendedorOptionModel(
      codVendedor: _readRequiredIntKeys(map, _keys('CodVendedor')),
      nomeVendedor: _readRequiredStringKeys(map, _keys('NomeVendedor')),
    );
  }

  final int codVendedor;
  final String nomeVendedor;

  ResumoVendasDiariasPorVendedorVendedorOption toEntity() {
    return ResumoVendasDiariasPorVendedorVendedorOption(
      codVendedor: codVendedor,
      nomeVendedor: nomeVendedor,
    );
  }

  static List<String> _keys(String pascal) {
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

  static int _readRequiredIntKeys(Map<String, dynamic> map, List<String> keys) {
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

  static String _readRequiredStringKeys(
    Map<String, dynamic> map,
    List<String> keys,
  ) {
    final value = _lookupFirst(map, keys);
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    throw FormatException(
      'Invalid or missing "${keys.first}" in agent SQL row',
    );
  }
}
