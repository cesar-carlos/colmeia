class ClientPasswordRecoveryResetRequestDto {
  const ClientPasswordRecoveryResetRequestDto({
    required this.token,
    required this.newPassword,
  });

  final String token;
  final String newPassword;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'token': token,
      'newPassword': newPassword,
    };
  }
}
