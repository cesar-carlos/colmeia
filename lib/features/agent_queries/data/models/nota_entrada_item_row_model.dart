import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:colmeia/features/agent_queries/domain/entities/nota_entrada_item_row.dart';

class NotaEntradaItemRowModel {
  const NotaEntradaItemRowModel({
    required this.codEmpresa,
    required this.codFilial,
    required this.compraId,
    required this.compraCancelada,
    required this.codProduto,
    required this.nomeProduto,
    required this.quantidade,
    required this.valorUnitario,
    required this.subTotal,
    required this.valorDescontoItem,
    required this.valorTotalDesconto,
    required this.valorDescontoProporcional,
    required this.valorTotal,
    this.codUnidadeMedida,
    this.descricaoUnidadeMedida,
    this.codGrupoProduto,
    this.nomeGrupoProduto,
  });

  factory NotaEntradaItemRowModel.fromMap(Map<String, dynamic> map) {
    return NotaEntradaItemRowModel(
      codEmpresa: _requiredInt(map, 'CodEmpresa'),
      codFilial: _requiredInt(map, 'CodFilial'),
      compraId: _requiredInt(map, 'CompraId'),
      compraCancelada: _requiredString(map, 'CompraCancelada'),
      codProduto: _requiredInt(map, 'CodProduto'),
      nomeProduto: _optionalString(map, 'NomeProduto') ?? '',
      codUnidadeMedida: AgentQueriesSqlRowMapReader.readOptionalTrimmedString(
        map,
        _keys('CodUnidadeMedida'),
      ),
      descricaoUnidadeMedida: _optionalString(map, 'DescricaoUnidadeMedida'),
      codGrupoProduto: AgentQueriesSqlRowMapReader.readOptionalIntStrict(
        map,
        _keys('CodGrupoProduto'),
      ),
      nomeGrupoProduto: _optionalString(map, 'NomeGrupoProduto'),
      quantidade: _requiredDouble(map, 'Quantidade'),
      valorUnitario: _requiredDouble(map, 'ValorUnitario'),
      subTotal: _requiredDouble(map, 'SubTotal'),
      valorDescontoItem: _requiredDouble(map, 'ValorDescontoItem'),
      valorTotalDesconto: _requiredDouble(map, 'ValorTotalDesconto'),
      valorDescontoProporcional: _requiredDouble(
        map,
        'ValorDescontoProporcional',
      ),
      valorTotal: _requiredDouble(map, 'ValorTotal'),
    );
  }

  final int codEmpresa;
  final int codFilial;
  final int compraId;
  final String compraCancelada;
  final int codProduto;
  final String nomeProduto;
  final String? codUnidadeMedida;
  final String? descricaoUnidadeMedida;
  final int? codGrupoProduto;
  final String? nomeGrupoProduto;
  final double quantidade;
  final double valorUnitario;
  final double subTotal;
  final double valorDescontoItem;
  final double valorTotalDesconto;
  final double valorDescontoProporcional;
  final double valorTotal;

  NotaEntradaItemRow toEntity() {
    return NotaEntradaItemRow(
      codEmpresa: codEmpresa,
      codFilial: codFilial,
      compraId: compraId,
      compraCancelada: compraCancelada,
      codProduto: codProduto,
      nomeProduto: nomeProduto,
      codUnidadeMedida: codUnidadeMedida,
      descricaoUnidadeMedida: descricaoUnidadeMedida,
      codGrupoProduto: codGrupoProduto,
      nomeGrupoProduto: nomeGrupoProduto,
      quantidade: quantidade,
      valorUnitario: valorUnitario,
      subTotal: subTotal,
      valorDescontoItem: valorDescontoItem,
      valorTotalDesconto: valorTotalDesconto,
      valorDescontoProporcional: valorDescontoProporcional,
      valorTotal: valorTotal,
    );
  }

  static int _requiredInt(Map<String, dynamic> map, String field) {
    return AgentQueriesSqlRowMapReader.readRequiredInt(map, _keys(field));
  }

  static String _requiredString(Map<String, dynamic> map, String field) {
    return AgentQueriesSqlRowMapReader.readRequiredNonEmptyString(
      map,
      _keys(field),
    );
  }

  static String? _optionalString(Map<String, dynamic> map, String field) {
    return AgentQueriesSqlRowMapReader.readOptionalTrimmedStringStrict(
      map,
      _keys(field),
    );
  }

  static double _requiredDouble(Map<String, dynamic> map, String field) {
    return AgentQueriesSqlRowMapReader.readRequiredDouble(map, _keys(field));
  }

  static List<String> _keys(String field) {
    return AgentQueriesSqlRowMapReader.keysCodEmpresaStyle(field);
  }
}
