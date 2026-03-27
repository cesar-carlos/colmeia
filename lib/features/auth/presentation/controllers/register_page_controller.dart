import 'package:colmeia/features/auth/presentation/models/register_access_profile.dart';
import 'package:flutter/foundation.dart';

class RegisterPageController extends ChangeNotifier {
  RegisterAccessProfile _selectedProfile = RegisterAccessProfile.vendedor;
  final Set<String> _selectedStoreIds = <String>{};
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _storeSelectionError = false;

  RegisterAccessProfile get selectedProfile => _selectedProfile;
  Set<String> get selectedStoreIds =>
      Set<String>.unmodifiable(_selectedStoreIds);
  bool get obscurePassword => _obscurePassword;
  bool get obscureConfirmPassword => _obscureConfirmPassword;
  bool get storeSelectionErrorVisible => _storeSelectionError;

  void setProfile(RegisterAccessProfile? value) {
    if (value == null) {
      return;
    }
    _selectedProfile = value;
    notifyListeners();
  }

  void toggleStoreSelection(String storeId) {
    if (_selectedStoreIds.contains(storeId)) {
      _selectedStoreIds.remove(storeId);
    } else {
      _selectedStoreIds.add(storeId);
    }
    _storeSelectionError = false;
    notifyListeners();
  }

  bool validateStoreSelection() {
    if (_selectedStoreIds.isEmpty) {
      _storeSelectionError = true;
      notifyListeners();
      return false;
    }
    return true;
  }

  void toggleObscurePassword() {
    _obscurePassword = !_obscurePassword;
    notifyListeners();
  }

  void toggleObscureConfirmPassword() {
    _obscureConfirmPassword = !_obscureConfirmPassword;
    notifyListeners();
  }
}
