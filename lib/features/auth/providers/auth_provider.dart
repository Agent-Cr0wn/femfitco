import 'package:flutter/material.dart'; // Import material or widgets for WidgetsBinding
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../models/user_model.dart';
import '../../../services/api_service.dart';
import '../../../common/constants/api_constants.dart';

class AuthProvider with ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    // aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  final ApiService _apiService = ApiService();

  UserModel? _user;
  String? _token;
  bool _isLoggedIn = false;
  bool _isLoading = true;

  UserModel? get user => _user;
  String? get token => _token;
  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;

  static const String _tokenKey = 'femfit_auth_token';
  static const String _userIdKey = 'femfit_user_id';

  AuthProvider() {
    tryAutoLogin();
  }

  Future<bool> login(Map<String, dynamic> loginData) async {
    _setLoading(true);
    if (loginData['user_id'] == null || loginData['token'] == null) {
       debugPrint("Login Error: Missing user_id or token in login data.");
        _handleAuthError('Invalid login response from server.');
       return false;
    }
    try {
      _user = UserModel.fromJson(loginData);
      _token = loginData['token'];
      _isLoggedIn = true;
      await _storage.write(key: _tokenKey, value: _token!);
      await _storage.write(key: _userIdKey, value: _user!.id.toString());
      debugPrint("Login successful for user ID: ${_user?.id}");
      _setLoading(false);
      return true;
    } catch (e) {
      debugPrint("Error processing login data: $e");
       _handleAuthError('Failed to process login information.');
      return false;
    }
  }

  Future<void> logout() async {
    _setLoading(true);
    _user = null;
    _token = null;
    _isLoggedIn = false;
    await Future.wait([
       _storage.delete(key: _tokenKey),
       _storage.delete(key: _userIdKey),
    ]);
    debugPrint("User logged out and token cleared.");
     _setLoading(false);
  }

  Future<bool> tryAutoLogin() async {
     // Don't call _setLoading(true) here directly if it calls notifyListeners,
     // as constructor might run before widget tree is fully built.
     // The initial state isLoading = true handles the initial loading phase.
     if (!_isLoading) { // Only set loading if not already loading
       _isLoading = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
           if (hasListeners) notifyListeners();
        });
     }


    final storedToken = await _storage.read(key: _tokenKey);
    final storedUserId = await _storage.read(key: _userIdKey);

    if (storedToken == null || storedUserId == null) {
      debugPrint("AutoLogin: No token/userId found in storage.");
      await logout(); // Ensures clean state
      return false;
    }

    debugPrint("AutoLogin: Found token for user $storedUserId. Validating...");
    final profileResult = await _apiService.get(
      '${ApiConstants.getUserProfileEndpoint}?user_id=$storedUserId',
      token: storedToken,
    );

    if (profileResult['success'] == true && profileResult['data'] != null) {
      try {
         _user = UserModel.fromJson(profileResult['data']);
         _token = storedToken;
         _isLoggedIn = true;
         debugPrint("AutoLogin: Token validation successful. User ${_user?.id} logged in.");
         _setLoading(false);
         return true;
      } catch(e) {
         debugPrint("AutoLogin Error: Failed to parse profile data after validation: $e");
         _handleAuthError('Failed to process user data.');
         return false;
      }
    } else {
      debugPrint("AutoLogin: Token validation failed. Reason: ${profileResult['message']} (Code: ${profileResult['statusCode']})");
      await logout();
      return false;
    }
  }

  void updateSubscriptionStatus(String status, String? endDate) {
    if (_user != null) {
      _user!.subscriptionStatus = status;
      _user!.subscriptionEndDate = endDate;
      debugPrint("Subscription status updated locally for user ${_user!.id}: $status");
      notifyListeners();
    }
  }

  void _setLoading(bool loading) {
     if (_isLoading != loading) {
        _isLoading = loading;
        // Use WidgetsBinding to safely call notifyListeners after build phase
        WidgetsBinding.instance.addPostFrameCallback((_) {
           // Check if listeners are still present (widget might have been disposed)
           // 'hasListeners' is protected, common workaround is try-catch or checking mounted status before calling.
           // Safer approach for providers is just calling notifyListeners directly.
           // If called during build, Provider handles it. If called elsewhere, it's usually fine.
           // Let's simplify and rely on Provider's handling.
           notifyListeners();
        });
     }
  }

   void _handleAuthError(String message) {
     debugPrint("AuthProvider Error: $message");
     logout(); // This sets loading false and notifies
   }
}