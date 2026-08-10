import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  @override
  Future<User?> login(String email, String password) async {
    // Simulate network delay to make it feel real
    await Future.delayed(const Duration(seconds: 1));
    
    // Save a fake token to local storage so they stay logged in!
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('user_email', email);

    return User(id: '123', email: email);
  }

  @override
  Future<User?> register(String email, String password) async {
    // Simulate network delay to make it feel real
    await Future.delayed(const Duration(seconds: 1));
    
    // Save a fake token to local storage so they stay logged in!
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    await prefs.setString('user_email', email);

    return User(id: '123', email: email);
  }

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  @override
  Future<User?> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    
    if (isLoggedIn) {
      final email = prefs.getString('user_email') ?? 'user@example.com';
      return User(id: '123', email: email);
    }
    return null; // Not logged in
  }
}
