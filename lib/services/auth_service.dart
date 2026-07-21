import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

/// Thin exception type so the UI can show a friendly message instead of a
/// raw stack trace.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

/// Talks to the Node/Express (or similar) REST API that sits in front of
/// MongoDB. Every call falls back gracefully when there's no connectivity,
/// so the caller (AuthProvider) can decide whether to use cached data.
class AuthService {
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.loginEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(ApiConfig.requestTimeout);

      final body = _decode(response.body);

      if (response.statusCode == 200) {
        final user = UserModel.fromJson(body['user'] ?? body);
        final token = body['token'] ?? '';
        await StorageService.instance.saveToken(token);
        await StorageService.instance.saveUser(user);
        return {'user': user, 'token': token};
      }
      throw AuthException(body['message'] ?? 'Invalid email or password.');
    } on SocketException {
      throw AuthException(
        'No internet connection. Please check your network and try again.',
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Something went wrong. Please try again.');
    }
  }

  Future<Map<String, dynamic>> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.signupEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username,
              'email': email,
              'password': password,
            }),
          )
          .timeout(ApiConfig.requestTimeout);

      final body = _decode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final user = UserModel.fromJson(body['user'] ?? body);
        final token = body['token'] ?? '';
        await StorageService.instance.saveToken(token);
        await StorageService.instance.saveUser(user);
        return {'user': user, 'token': token};
      }
      throw AuthException(body['message'] ?? 'Could not create your account.');
    } on SocketException {
      throw AuthException(
        'No internet connection. Please check your network and try again.',
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Something went wrong. Please try again.');
    }
  }

  Future<void> forgotPassword({required String email}) async {
    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.forgotPasswordEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(ApiConfig.requestTimeout);

      if (response.statusCode == 200) return;

      final body = _decode(response.body);
      throw AuthException(
        body['message'] ?? 'Could not send a reset link for that email.',
      );
    } on SocketException {
      throw AuthException(
        'No internet connection. Please try again once you\'re back online.',
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Something went wrong. Please try again.');
    }
  }

  Future<UserModel> updateProfile({
    required String token,
    required String userId,
    String? username,
    String? password,
    String? profileImageUrl,
  }) async {
    try {
      final response = await http
          .patch(
            Uri.parse('${ApiConfig.updateProfileEndpoint}/$userId'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({
              if (username != null) 'username': username,
              if (password != null) 'password': password,
              if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
            }),
          )
          .timeout(ApiConfig.requestTimeout);

      final body = _decode(response.body);
      if (response.statusCode == 200) {
        final user = UserModel.fromJson(body['user'] ?? body);
        await StorageService.instance.saveUser(user);
        return user;
      }
      throw AuthException(body['message'] ?? 'Could not update your profile.');
    } on SocketException {
      throw AuthException(
        'You\'re offline. Your profile will update once you\'re back online.',
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Something went wrong. Please try again.');
    }
  }

  Future<void> signOut() async {
    await StorageService.instance.clearAll();
  }

  Map<String, dynamic> _decode(String body) {
    if (body.isEmpty) return {};
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
