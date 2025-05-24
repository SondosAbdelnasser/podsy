import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();

  UserModel? _user;

  UserModel? get currentUser => _user;
  bool get isLoggedIn => _user != null;
  bool get is_admin => _user?.is_admin ?? false;

  Future<void> signUp(String email, String password) async {
    final userCred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final newUser = UserModel(
      id: userCred.user!.uid,
      email: email,
      name: email.split('@')[0],
      is_admin: false,
    );

    await _userService.createUser(newUser);
    _user = newUser;
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    final userCred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final fetchedUser = await _userService.getUserById(userCred.user!.uid);
    _user = fetchedUser;
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      final fetchedUser = await _userService.getUserById(firebaseUser.uid);
      if (fetchedUser != null) {
        _user = fetchedUser;
        notifyListeners();
      }
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signInWithGoogle() async {
    // Implement Google Sign-In if needed later
  }
}
