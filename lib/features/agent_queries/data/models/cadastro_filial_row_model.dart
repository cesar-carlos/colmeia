import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_row.dart';

class CadastroFilialRowModel {
  const CadastroFilialRowModel({
    required this.codEmpresa,
    required this.codFilial,
    required this.nomeFilial,
    this.nomeFantasia,
    this.cnpj,
    this.endereco,
    this.numeroEndereco,
    this.bairro,
    this.cep,
    this.codMunicipio,
    this.nomeMunicipio,
    this.codigoIbge,
    this.ufMunicipio,
  });

  factory CadastroFilialRowModel.fromMap(Map<String, dynamic> map) {
    return CadastroFilialRowModel(
      codEmpresa: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodEmpresa'),
      ),
      codFilial: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodFilial'),
      ),
      nomeFilial: AgentQueriesSqlRowMapReader.readRequiredNonEmptyString(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('NomeFilial'),
      ),
      nomeFantasia: AgentQueriesSqlRowMapReader.readOptionalTrimmedString(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('NomeFantasia'),
      ),
      cnpj: AgentQueriesSqlRowMapReader.readOptionalTrimmedString(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CNPJ'),
      ),
      endereco: AgentQueriesSqlRowMapReader.readOptionalTrimmedString(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('Endereco'),
      ),
      numeroEndereco: AgentQueriesSqlRowMapReader.readOptionalTrimmedString(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('NumeroEndereco'),
      ),
      bairro: AgentQueriesSqlRowMapReader.readOptionalTrimmedString(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('Bairro'),
      ),
      cep: _digitsOnly(
        AgentQueriesSqlRowMapReader.readOptionalTrimmedString(
          map,
          AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CEP'),
        ),
      ),
      codMunicipio: AgentQueriesSqlRowMapReader.readOptionalIntStrict(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodMunicipio'),
      ),
      nomeMunicipio: AgentQueriesSqlRowMapReader.readOptionalTrimmedString(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('NomeMunicipio'),
      ),
      codigoIbge: AgentQueriesSqlRowMapReader.readOptionalTrimmedString(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodigoIBGE'),
      ),
      ufMunicipio: AgentQueriesSqlRowMapReader.readOptionalTrimmedString(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('UFMunicipio'),
      ),
    );
  }

  final int codEmpresa;
  final int codFilial;
  final String nomeFilial;
  final String? nomeFantasia;
  final String? cnpj;
  final String? endereco;
  final String? numeroEndereco;
  final String? bairro;
  final String? cep;
  final int? codMunicipio;
  final String? nomeMunicipio;
  final String? codigoIbge;
  final String? ufMunicipio;

  CadastroFilialRow toEntity() {
    return CadastroFilialRow(
      codEmpresa: codEmpresa,
      codFilial: codFilial,
      nomeFilial: nomeFilial,
      nomeFantasia: nomeFantasia,
      cnpj: cnpj,
      endereco: endereco,
      numeroEndereco: numeroEndereco,
      bairro: bairro,
      cep: cep,
      codMunicipio: codMunicipio,
      nomeMunicipio: nomeMunicipio,
      codigoIbge: codigoIbge,
      ufMunicipio: ufMunicipio,
    );
  }

  static String? _digitsOnly(String? value) {
    if (value == null) {
      return null;
    }
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.isEmpty ? null : digits;
  }
}
