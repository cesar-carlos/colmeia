/// One cliente row from the agent SQL catalog used by autocomplete UIs.
class ClienteOption {
  const ClienteOption({
    required this.codCliente,
    required this.nomeCliente,
    required this.nomeMunicipio,
    required this.ufMunicipio,
    this.nomeFantasia,
    this.cnpjCpf,
    this.codigoIbge,
  });

  final int codCliente;
  final String nomeCliente;
  final String? nomeFantasia;
  final String? cnpjCpf;
  final String nomeMunicipio;
  final String ufMunicipio;
  final String? codigoIbge;

  String get municipioDisplay => '$nomeMunicipio - $ufMunicipio';

  /// Primary label for dropdowns and async search fields.
  String get displayLabel {
    final fantasy = nomeFantasia?.trim();
    if (fantasy != null &&
        fantasy.isNotEmpty &&
        fantasy.toUpperCase() != nomeCliente.toUpperCase()) {
      return '$nomeCliente ($fantasy)';
    }
    return nomeCliente;
  }
}
