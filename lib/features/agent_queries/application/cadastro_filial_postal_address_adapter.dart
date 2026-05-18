import 'package:colmeia/features/agent_queries/domain/entities/cadastro_filial_row.dart';
import 'package:colmeia/shared/maps/app_location_models.dart';

extension CadastroFilialPostalAddressAdapter on CadastroFilialRow {
  AppPostalAddress toPostalAddress() {
    return AppPostalAddress(
      street: endereco,
      number: numeroEndereco,
      district: bairro,
      city: nomeMunicipio,
      uf: ufMunicipio,
      cep: cep,
    );
  }
}
