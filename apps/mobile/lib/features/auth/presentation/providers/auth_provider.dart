import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/auth_user_model.dart';
import '../../../../core/services/local_storage_service.dart';

class AuthState {
  final AuthUserModel? currentUser;
  final bool isLoggedIn;
  final bool isInitialized;
  final String? errorMessage;

  const AuthState({
    this.currentUser,
    this.isLoggedIn = false,
    this.isInitialized = false,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthUserModel? currentUser,
    bool? isLoggedIn,
    bool? isInitialized,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      currentUser: currentUser ?? this.currentUser,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      isInitialized: isInitialized ?? this.isInitialized,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  static const String _keyAccounts = 'clarafin_registered_accounts';
  static const String _keyIsLoggedIn = 'clarafin_is_logged_in';
  static const String _keyActiveUserId = 'clarafin_active_user_id';

  @override
  AuthState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    final activeUserId = prefs.getString(_keyActiveUserId);
    final accountsJson = prefs.getStringList(_keyAccounts) ?? [];

    AuthUserModel? activeUser;
    if (isLoggedIn && activeUserId != null) {
      for (final raw in accountsJson) {
        try {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          if (map['id'] == activeUserId) {
            activeUser = AuthUserModel.fromJson(map);
            break;
          }
        } catch (_) {}
      }
    }

    return AuthState(
      currentUser: activeUser,
      isLoggedIn: isLoggedIn && activeUser != null,
      isInitialized: true,
    );
  }

  bool checkSession() {
    return state.isLoggedIn;
  }

  List<AuthUserModel> _getRegisteredAccounts() {
    final prefs = ref.read(sharedPreferencesProvider);
    final list = prefs.getStringList(_keyAccounts) ?? [];
    final result = <AuthUserModel>[];
    for (final raw in list) {
      try {
        result.add(AuthUserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>));
      } catch (_) {}
    }
    return result;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final trimmedName = name.trim();
    final trimmedEmail = email.trim().toLowerCase();
    final trimmedPassword = password.trim();

    if (trimmedName.isEmpty || trimmedEmail.isEmpty || trimmedPassword.isEmpty) {
      state = state.copyWith(errorMessage: 'Semua kolom wajib diisi');
      return false;
    }

    final accounts = _getRegisteredAccounts();
    final emailExists = accounts.any((a) => a.email.toLowerCase() == trimmedEmail);
    if (emailExists) {
      state = state.copyWith(errorMessage: 'Email sudah terdaftar. Silakan login.');
      return false;
    }

    final newUser = AuthUserModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: trimmedName,
      email: trimmedEmail,
      password: trimmedPassword,
    );

    accounts.add(newUser);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setStringList(_keyAccounts, accounts.map((a) => jsonEncode(a.toJson())).toList());
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyActiveUserId, newUser.id);

    state = state.copyWith(
      currentUser: newUser,
      isLoggedIn: true,
      clearError: true,
    );

    return true;
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim().toLowerCase();
    final trimmedPassword = password.trim();

    if (trimmedEmail.isEmpty || trimmedPassword.isEmpty) {
      state = state.copyWith(errorMessage: 'Email dan kata sandi wajib diisi');
      return false;
    }

    final accounts = _getRegisteredAccounts();
    final user = accounts.where((a) => a.email.toLowerCase() == trimmedEmail).firstOrNull;

    if (user == null) {
      state = state.copyWith(errorMessage: 'Akun belum terdaftar. Silakan daftar terlebih dahulu.');
      return false;
    }

    if (user.password != trimmedPassword) {
      state = state.copyWith(errorMessage: 'Kata sandi salah. Silakan coba lagi.');
      return false;
    }

    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyActiveUserId, user.id);

    state = state.copyWith(
      currentUser: user,
      isLoggedIn: true,
      clearError: true,
    );

    return true;
  }

  Future<void> logout() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_keyIsLoggedIn, false);
    await prefs.remove(_keyActiveUserId);

    state = const AuthState(
      currentUser: null,
      isLoggedIn: false,
      isInitialized: true,
    );
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});
