import 'package:colmeia/features/agent_queries/domain/entities/resumo_vendas_diarias_por_vendedor_text_option.dart';

class ResumoVendasDiariasPorVendedorTextOptionModel {
  const ResumoVendasDiariasPorVendedorTextOptionModel({required this.value});

  factory ResumoVendasDiariasPorVendedorTextOptionModel.fromBairroMap(
    Map<String, dynamic> map,
  ) {
    return ResumoVendasDiariasPorVendedorTextOptionModel(
      value: _readRequiredStringKeys(map, _keys('Bairro')),
    );
  }

  factory ResumoVendasDiariasPorVendedorTextOptionModel.fromMunicipioMap(
    Map<String, dynamic> map,
  ) {
    return ResumoVendasDiariasPorVendedorTextOptionModel(
      value: _readRequiredStringKeys(map, _keys('NomeMunicipio')),
    );
  }

  final String value;

  ResumoVendasDiariasPorVendedorTextOption toEntity() {
    return ResumoVendasDiariasPorVendedorTextOption(value: value);
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
