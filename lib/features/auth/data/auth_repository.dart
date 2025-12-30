import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/auth_session.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.read(apiClientProvider);
  return AuthRepository(client);
});

class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;
  static const _offlineAdminEmail = 'admin@example.com';
  static const _offlineUserEmail = 'user@example.com';
  static const _offlinePassword = 'password123';
  static const _offlineAdminToken = 'offline-admin-token';
  static const _offlineUserToken = 'offline-user-token';

  Future<AuthSession> login(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    final offlineRole = _detectOfflineRole(normalizedEmail, password);

    // Offline login shortcut: bekerja tanpa MySQL/PHP.
    if (offlineRole != null) {
      return _buildOfflineSession(offlineRole);
    }

    try {
      final response = await _api.client.post('/login.php', data: {
        'email': email,
        'password': password,
      });
      if (response.data is Map) {
        final token = response.data['token'] as String?;
        final user = response.data['user'];
        final name = user is Map ? (user['name'] ?? '') : '';
        final email = user is Map ? (user['email'] ?? '') : '';
        final userId = user is Map ? '${user['id'] ?? ''}' : '';
        if (token != null) {
          final role = _parseRole(response.data['role'] ?? (user is Map ? user['role'] : null));
          return AuthSession(
            token: token,
            role: role,
            userId: userId,
            name: name,
            email: email,
          );
        }
      }
      throw const FormatException('Respon login tidak valid');
    } on DioException catch (e) {
      // Fallback offline jika server gagal dijangkau tetapi kredensial cocok.
      final fallbackRole = _detectOfflineRole(normalizedEmail, password);
      if (fallbackRole != null) {
        return _buildOfflineSession(fallbackRole);
      }
      throw Exception(e.response?.data?['message'] ?? 'Gagal login');
    }
  }

  Future<void> register(String name, String email, String password) async {
    try {
      final response = await _api.client.post('/register.php', data: {
        'name': name,
        'email': email,
        'password': password,
      });
      if (response.statusCode != 200) {
        throw Exception('Gagal daftar');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Gagal daftar');
    }
  }

  UserRole _parseRole(dynamic role) {
    final value = role?.toString().toLowerCase().trim();
    if (value == 'admin') return UserRole.admin;
    return UserRole.user;
  }

  UserRole? _detectOfflineRole(String email, String password) {
    if (password != _offlinePassword) return null;
    if (email == _offlineAdminEmail) return UserRole.admin;
    if (email == _offlineUserEmail) return UserRole.user;
    return null;
  }

  AuthSession _buildOfflineSession(UserRole role) {
    final token =
        role == UserRole.admin ? _offlineAdminToken : _offlineUserToken;
    return AuthSession(
      token: token,
      role: role,
      userId: role == UserRole.admin ? 'admin-offline' : 'user-offline',
      name: role == UserRole.admin ? 'Admin Offline' : 'User Offline',
      email: role == UserRole.admin ? _offlineAdminEmail : _offlineUserEmail,
    );
  }
}
