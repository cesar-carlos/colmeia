import 'package:colmeia/features/auth/data/models/client_auth_user_dto.dart';
import 'package:colmeia/features/user_context/domain/entities/user_profile.dart';

UserProfile userProfileFromClientAuthUserDto(ClientAuthUserDto dto) {
  return UserProfile(
    id: dto.id,
    name: dto.displayName,
    roleLabel: dto.resolvedRoleLabel,
    corporateEmail: dto.email,
    phone: dto.mobile ?? '',
    firstName: dto.firstName ?? '',
    lastName: dto.lastName ?? '',
    thumbnailUrl: dto.thumbnailUrl,
  );
}
