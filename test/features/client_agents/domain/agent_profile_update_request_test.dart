import 'package:checks/checks.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_profile_address.dart';
import 'package:colmeia/features/client_agents/domain/entities/agent_profile_update_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toWireJson omits address when all address parts are empty', () {
    const request = AgentProfileUpdateRequest(
      name: 'Co',
      address: AgentProfileAddress(
        street: null,
        number: null,
        district: null,
        postalCode: null,
        city: null,
        state: null,
      ),
    );
    final json = request.toWireJson();
    check(json.containsKey('address')).isFalse();
  });

  test('toWireJson includes compact address and only cnpjCpf for tax id', () {
    const request = AgentProfileUpdateRequest(
      name: 'Co',
      cnpjCpf: '59261947000107',
      address: AgentProfileAddress(
        street: ' Rua A ',
        number: '1',
        district: null,
        postalCode: '',
        city: 'X',
        state: null,
      ),
    );
    final json = request.toWireJson();
    check(json['cnpjCpf']).equals('59261947000107');
    check(json.containsKey('document')).isFalse();
    final addr = json['address']! as Map<String, Object?>;
    check(addr.length).equals(3);
    check(addr['street']).equals('Rua A');
    check(addr['number']).equals('1');
    check(addr['city']).equals('X');
  });
}
