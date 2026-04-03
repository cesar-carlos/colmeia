class ClientRegisterRequestDto {
  const ClientRegisterRequestDto({
    required this.ownerEmail,
    required this.email,
    required this.password,
    required this.name,
    required this.lastName,
    this.mobile,
  });

  final String ownerEmail;
  final String email;
  final String password;
  final String name;
  final String lastName;
  final String? mobile;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'ownerEmail': ownerEmail,
      'email': email,
      'password': password,
      'name': name,
      'lastName': lastName,
      if (mobile case final String value when value.trim().isNotEmpty)
        'mobile': value.trim(),
    };
  }
}
