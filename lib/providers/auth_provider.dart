import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus status = AuthStatus.unknown;
  UserModel? currentUser;
  String? token;
  String? errorMessage;
  bool isLoading = false;

  /// Called once at splash screen to decide where to route the user.
  Future<void> loadSession() async {
    final savedToken = await StorageService.instance.getToken();
    final savedUser = await StorageService.instance.getUser();
    if (savedToken != null && savedUser != null) {
      token = savedToken;
      currentUser = savedUser;
      status = AuthStatus.authenticated;
    } else {
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> signIn({required String email, required String password}) {
    return _run(() async {
      final result = await _authService.signIn(
        email: email,
        password: password,
      );
      currentUser = result['user'];
      token = result['token'];
      status = AuthStatus.authenticated;
    });
  }

  Future<bool> signUp({
    required String username,
    required String email,
    required String password,
  }) {
    return _run(() async {
      final result = await _authService.signUp(
        username: username,
        email: email,
        password: password,
      );
      currentUser = result['user'];
      token = result['token'];
      status = AuthStatus.authenticated;
    });
  }

  Future<bool> forgotPassword({required String email}) {
    return _run(() async {
      await _authService.forgotPassword(email: email);
    });
  }

  Future<bool> updateProfile({
    String? username,
    String? password,
    String? profileImageUrl,
  }) {
    return _run(() async {
      if (currentUser == null || token == null) {
        throw AuthException('You need to be signed in to do that.');
      }
      final updated = await _authService.updateProfile(
        token: token!,
        userId: currentUser!.id ?? '',
        username: username,
        password: password,
        profileImageUrl: profileImageUrl,
      );
      currentUser = updated;
    });
  }

  /// Lets the profile screen show a locally-picked image immediately,
  /// even before/without a successful server sync (offline support).
  /// Used starting Day 5.
  void setLocalProfileImage(String path) {
    if (currentUser == null) return;
    currentUser = currentUser!.copyWith(localProfileImagePath: path);
    StorageService.instance.saveUser(currentUser!);
    notifyListeners();
  }

  Future<void> signOut() async {
    await _authService.signOut();
    currentUser = null;
    token = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() action) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
      isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      isLoading = false;
      errorMessage = e is AuthException ? e.message : e.toString();
      notifyListeners();
      return false;
    }
  }
}
