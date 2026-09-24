import 'package:flutter/foundation.dart';

import 'api_service.dart';

class AuthState extends ChangeNotifier {
  AuthState(this.api);
  final ApiService api;
  bool loading = true;
  bool signedIn = false;
  String role = 'user';
  bool get canModerate => role == 'moderator' || role == 'admin';

  Future<void> restore() async {
    signedIn = await api.isSignedIn;
    role = await api.savedRole;
    loading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    role = await api.login(email, password);
    signedIn = true;
    notifyListeners();
  }

  Future<String?> requestRegistration(
    String email,
    String password,
    String confirmation,
  ) => api.requestRegistration(email, password, confirmation);

  Future<void> verifyRegistration(String email, String otp) async {
    role = await api.verifyRegistration(email, otp);
    signedIn = true;
    notifyListeners();
  }

  Future<String?> resendRegistrationOTP(String email) =>
      api.resendRegistrationOTP(email);

  Future<void> logout() async {
    await api.logout();
    signedIn = false;
    role = 'user';
    notifyListeners();
  }
}
