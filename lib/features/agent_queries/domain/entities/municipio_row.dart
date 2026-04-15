/// One municipio row from `Municipio` joined with `Estado` (agent SQL).
class MunicipioRow {
  const MunicipioRow({
    required this.codMunicipio,
    required this.nomeMunicipio,
    required this.nomeEstado,
    required this.uf,
    this.codigoIbge,
  });

  final int codMunicipio;
  final String nomeMunicipio;
  final String nomeEstado;
  final String uf;
  final String? codigoIbge;
}
