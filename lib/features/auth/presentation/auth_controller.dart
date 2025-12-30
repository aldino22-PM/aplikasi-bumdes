import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/auth_repository.dart';
import '../domain/auth_session.dart';

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AuthSession?>>((ref) {
  final repo = ref.read(authRepositoryProvider);
  return AuthController(repo);
});

class AuthController extends StateNotifier<AsyncValue<AuthSession?>> {
  AuthController(this._repo) : super(const AsyncValue.data(null));

  final AuthRepository _repo;

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.login(email, password));
  }

  Future<void> register(String name, String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard<AuthSession?>(() async {
      await _repo.register(name, email, password);
      return null;
    });
  }

  void logout() {
    state = const AsyncValue.data(null);
  }
}
