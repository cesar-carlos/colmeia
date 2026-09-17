import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:colmeia/features/agent_queries/domain/entities/nota_entrada_row.dart';

class NotaEntradaRowModel {
  const NotaEntradaRowModel({
    required this.compraId,
    required this.codEmpresa,
    required this.codFilial,
    required this.nomeFilial,
    required this.codTipoOperacaoCompra,
    required this.descricaoTipoOperacaoCompra,
    required this.numeroDocumento,
    required this.dataLancamento,
    required this.codFornecedor,
    required this.nomeFornecedor,
    required this.valorTotalCompra,
    this.nomeFantasiaFilial,
    this.dataEmissao,
    this.dataEntrada,
    this.nomeFantasiaFornecedor,
    this.cnpjCpfFornecedor,
    this.chaveAcesso,
  });

  factory NotaEntradaRowModel.fromMap(Map<String, dynamic> map) {
    return NotaEntradaRowModel(
      compraId: _requiredInt(map, 'CompraId'),
      codEmpresa: _requiredInt(map, 'CodEmpresa'),
      codFilial: _requiredInt(map, 'CodFilial'),
      nomeFilial: _requiredString(map, 'NomeFilial'),
      nomeFantasiaFilial: _optionalString(map, 'NomeFantasiaFilial'),
      codTipoOperacaoCompra: _requiredInt(map, 'CodTipoOperacaoCompra'),
      descricaoTipoOperacaoCompra: _requiredString(
        map,
        'DescricaoTipoOperacaoCompra',
      ),
      numeroDocumento: _requiredString(map, 'NumeroDocumento'),
      dataEmissao: _optionalDateTime(map, 'DataEmissao'),
      dataEntrada: _optionalDateTime(map, 'DataEntrada'),
      dataLancamento: _requiredDateTime(map, 'DataLancamento'),
      codFornecedor: _requiredInt(map, 'CodFornecedor'),
      nomeFornecedor: _requiredString(map, 'NomeFornecedor'),
      nomeFantasiaFornecedor: _optionalString(map, 'NomeFantasiaFornecedor'),
      cnpjCpfFornecedor: _optionalString(map, 'CnpjCpfFornecedor'),
      chaveAcesso: _optionalString(map, 'ChaveAcesso'),
      valorTotalCompra: AgentQueriesSqlRowMapReader.readRequiredDouble(
        map,
        _keys('ValorTotalCompra'),
      ),
    );
  }

  final int compraId;
  final int codEmpresa;
  final int codFilial;
  final String nomeFilial;
  final String? nomeFantasiaFilial;
  final int codTipoOperacaoCompra;
  final String descricaoTipoOperacaoCompra;
  final String numeroDocumento;
  final DateTime? dataEmissao;
  final DateTime? dataEntrada;
  final DateTime dataLancamento;
  final int codFornecedor;
  final String nomeFornecedor;
  final String? nomeFantasiaFornecedor;
  final String? cnpjCpfFornecedor;
  final String? chaveAcesso;
  final double valorTotalCompra;

  NotaEntradaRow toEntity() {
    return NotaEntradaRow(
      compraId: compraId,
      codEmpresa: codEmpresa,
      codFilial: codFilial,
      nomeFilial: nomeFilial,
      nomeFantasiaFilial: nomeFantasiaFilial,
      codTipoOperacaoCompra: codTipoOperacaoCompra,
      descricaoTipoOperacaoCompra: descricaoTipoOperacaoCompra,
      numeroDocumento: numeroDocumento,
      dataEmissao: dataEmissao,
      dataEntrada: dataEntrada,
      dataLancamento: dataLancamento,
      codFornecedor: codFornecedor,
      nomeFornecedor: nomeFornecedor,
      nomeFantasiaFornecedor: nomeFantasiaFornecedor,
      cnpjCpfFornecedor: cnpjCpfFornecedor,
      chaveAcesso: chaveAcesso,
      valorTotalCompra: valorTotalCompra,
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

  static DateTime _requiredDateTime(Map<String, dynamic> map, String field) {
    final value = _optionalDateTime(map, field);
    if (value != null) {
      return value;
    }
    throw FormatException('Invalid or missing "$field" in agent SQL row');
  }

  static DateTime? _optionalDateTime(Map<String, dynamic> map, String field) {
    final value = AgentQueriesSqlRowMapReader.lookupFirst(map, _keys(field));
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      final parsed = DateTime.tryParse(value.trim());
      if (parsed != null) {
        return parsed;
      }
    }
    throw FormatException('Invalid "$field" in agent SQL row');
  }

  static List<String> _keys(String field) {
    return AgentQueriesSqlRowMapReader.keysCodEmpresaStyle(field);
  }
}
