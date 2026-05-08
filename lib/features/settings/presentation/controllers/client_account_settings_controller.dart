import 'package:colmeia/features/auth/application/usecases/change_password_use_case.dart';
import 'package:colmeia/features/auth/application/usecases/update_current_user_profile_use_case.dart';
import 'package:colmeia/features/auth/application/usecases/upload_client_thumbnail_use_case.dart';
import 'package:colmeia/features/user_context/domain/entities/user_profile.dart';
import 'package:flutter/foundation.dart';

class ClientAccountSettingsController extends ChangeNotifier {
  ClientAccountSettingsController({
    required UpdateCurrentUserProfileUseCase updateCurrentUserProfileUseCase,
    required UploadClientThumbnailUseCase uploadClientThumbnailUseCase,
    required ChangePasswordUseCase changePasswordUseCase,
  }) : _updateCurrentUserProfileUseCase = updateCurrentUserProfileUseCase,
       _uploadClientThumbnailUseCase = uploadClientThumbnailUseCase,
       _changePasswordUseCase = changePasswordUseCase;

  final UpdateCurrentUserProfileUseCase _updateCurrentUserProfileUseCase;
  final UploadClientThumbnailUseCase _uploadClientThumbnailUseCase;
  final ChangePasswordUseCase _changePasswordUseCase;

  bool _isSavingProfile = false;
  bool _isUploadingThumbnail = false;
  bool _isChangingPassword = false;
  String? _errorMessage;
  String? _successMessage;

  bool get isSavingProfile => _isSavingProfile;
  bool get isUploadingThumbnail => _isUploadingThumbnail;
  bool get isChangingPassword => _isChangingPassword;
  bool get isBusy =>
      _isSavingProfile || _isUploadingThumbnail || _isChangingPassword;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  void clearFeedback() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<UserProfile?> updateProfile({
    required String firstName,
    required String lastName,
    String? mobile,
    bool removeThumbnail = false,
  }) async {
    _isSavingProfile = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final result = await _updateCurrentUserProfileUseCase(
      firstName: firstName,
      lastName: lastName,
      mobile: mobile,
      removeThumbnail: removeThumbnail,
    );
    final profile = result.fold(
      (updated) {
        _successMessage = removeThumbnail
            ? 'Foto removida com sucesso.'
            : 'Dados da conta atualizados com sucesso.';
        return updated;
      },
      (failure) {
        _errorMessage = failure.displayMessage;
        return null;
      },
    );

    _isSavingProfile = false;
    notifyListeners();
    return profile;
  }

  Future<UserProfile?> uploadThumbnail({
    required String filePath,
  }) async {
    _isUploadingThumbnail = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final result = await _uploadClientThumbnailUseCase(filePath: filePath);
    final profile = result.fold(
      (updated) {
        _successMessage = 'Foto da conta atualizada com sucesso.';
        return updated;
      },
      (failure) {
        _errorMessage = failure.displayMessage;
        return null;
      },
    );

    _isUploadingThumbnail = false;
    notifyListeners();
    return profile;
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isChangingPassword = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    final result = await _changePasswordUseCase(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    final success = result.fold(
      (_) {
        _successMessage = 'Senha alterada com sucesso.';
        return true;
      },
      (failure) {
        _errorMessage = failure.displayMessage;
        return false;
      },
    );

    _isChangingPassword = false;
    notifyListeners();
    return success;
  }
}
