import 'package:colmeia/features/agent_queries/data/agent_queries_sql_row_map_reader.dart';
import 'package:colmeia/features/agent_queries/domain/entities/municipio_row.dart';

class MunicipioRowModel {
  const MunicipioRowModel({
    required this.codMunicipio,
    required this.nomeMunicipio,
    required this.nomeEstado,
    required this.uf,
    this.codigoIbge,
  });

  factory MunicipioRowModel.fromMap(Map<String, dynamic> map) {
    return MunicipioRowModel(
      codMunicipio: AgentQueriesSqlRowMapReader.readRequiredInt(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodMunicipio'),
      ),
      nomeMunicipio: AgentQueriesSqlRowMapReader.readRequiredNonEmptyString(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('NomeMunicipio'),
      ),
      nomeEstado: AgentQueriesSqlRowMapReader.readRequiredNonEmptyString(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('NomeEstado'),
      ),
      uf: AgentQueriesSqlRowMapReader.readRequiredNonEmptyString(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('UF'),
      ),
      codigoIbge: AgentQueriesSqlRowMapReader.readOptionalTrimmedString(
        map,
        AgentQueriesSqlRowMapReader.keysCodEmpresaStyle('CodigoIBGE'),
      ),
    );
  }

  final int codMunicipio;
  final String nomeMunicipio;
  final String nomeEstado;
  final String uf;
  final String? codigoIbge;

  MunicipioRow toEntity() {
    return MunicipioRow(
      codMunicipio: codMunicipio,
      nomeMunicipio: nomeMunicipio,
      nomeEstado: nomeEstado,
      uf: uf,
      codigoIbge: codigoIbge,
    );
  }
}
