import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  bool get isAdmin => _currentUser?.isAdmin ?? false;

  Future<void> signUp(String email, String password) async {
    final cred = await _authService.signUp(email, password);
    _currentUser = await _userService.getUserById(cred.user!.uid);
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    final cred = await _authService.signIn(email, password);
    _currentUser = await _userService.getUserById(cred.user!.uid);
    notifyListeners();
  }
}
