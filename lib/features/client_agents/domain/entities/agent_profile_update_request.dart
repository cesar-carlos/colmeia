import 'package:colmeia/features/client_agents/domain/entities/agent_profile_address.dart';

/// Fields for `PATCH /api/v1/agents/:id/profile`.
///
/// Wire JSON sends only [cnpjCpf] for the tax id (digits as returned by the
/// server). [address] is omitted when null or when every part is empty.
///
/// [expectedProfileVersion] is the **monotonic integer** counter served by
/// the hub on `ClientAccessibleAgent.profileVersion`. The server uses it as
/// a CAS token: when present, the PATCH only succeeds if the stored
/// `profileVersion` matches; otherwise the hub responds `409` and the
/// caller should reload the agent and retry.
///
/// [idempotencyKey] is the body fallback for safe retries when the caller
/// cannot send a header. The HTTP layer prefers the `Idempotency-Key`
/// header (set by the datasource); this field is forwarded only when the
/// caller explicitly provides it.
class AgentProfileUpdateRequest {
  const AgentProfileUpdateRequest({
    required this.name,
    this.tradeName,
    this.cnpjCpf,
    this.documentType,
    this.phone,
    this.mobile,
    this.email,
    this.address,
    this.notes,
    this.observation,
    this.expectedProfileVersion,
    this.idempotencyKey,
  });

  final String name;
  final String? tradeName;
  final String? cnpjCpf;
  final String? documentType;
  final String? phone;
  final String? mobile;
  final String? email;
  final AgentProfileAddress? address;
  final String? notes;
  final String? observation;
  final int? expectedProfileVersion;
  final String? idempotencyKey;

  Map<String, Object?> toWireJson() {
    final addressWire = _compactAddressWire(address);
    final trimmedIdempotencyKey = idempotencyKey?.trim();
    return <String, Object?>{
      'name': name,
      if (tradeName != null) 'tradeName': tradeName,
      if (cnpjCpf != null) 'cnpjCpf': cnpjCpf,
      if (documentType != null) 'documentType': documentType,
      if (phone != null) 'phone': phone,
      if (mobile != null) 'mobile': mobile,
      if (email != null) 'email': email,
      'address':? addressWire,
      if (notes != null) 'notes': notes,
      if (observation != null) 'observation': observation,
      if (expectedProfileVersion != null)
        'expectedProfileVersion': expectedProfileVersion,
      if (trimmedIdempotencyKey != null && trimmedIdempotencyKey.isNotEmpty)
        'idempotencyKey': trimmedIdempotencyKey,
    };
  }
}

/// Only non-empty trimmed parts; empty map means omit `address` on the wire.
Map<String, Object?>? _compactAddressWire(AgentProfileAddress? address) {
  if (address == null) {
    return null;
  }
  String? nz(String? s) {
    if (s == null) {
      return null;
    }
    final t = s.trim();
    return t.isEmpty ? null : t;
  }

    final out = <String, Object?>{
    if (nz(address.street) != null) 'street': nz(address.street),
    if (nz(address.number) != null) 'number': nz(address.number),
    if (nz(address.district) != null) 'district': nz(address.district),
    if (nz(address.postalCode) != null) 'postalCode': nz(address.postalCode),
    if (nz(address.city) != null) 'city': nz(address.city),
    if (nz(address.state) != null) 'state': nz(address.state),
  };
  if (out.isEmpty) {
    return null;
  }
  return out;
}
