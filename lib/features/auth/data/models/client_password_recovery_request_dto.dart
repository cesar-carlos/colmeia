class ClientPasswordRecoveryRequestDto {
  const ClientPasswordRecoveryRequestDto({
    required this.email,
  });

  final String email;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'email': email,
    };
  }
}
