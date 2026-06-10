class ClientRegistrationRetryRequestDto {
  const ClientRegistrationRetryRequestDto({
    required this.ownerEmail,
    required this.email,
    required this.password,
  });

  final String ownerEmail;
  final String email;
  final String password;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'ownerEmail': ownerEmail,
      'email': email,
      'password': password,
    };
  }
}
