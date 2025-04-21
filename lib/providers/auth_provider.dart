import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  bool get isAdmin => _currentUser?.isAdmin ?? false;

  /// Whether the user is logged in
  bool get isLoggedIn => _currentUser != null;

  Future<void> signUp(String email, String password) async {
    final cred = await _authService.signUp(email, password);
    // After signup, user has role = "user" in Firestore
    _currentUser = await _userService.getUserById(cred.user!.uid);
    notifyListeners();
  }

  Future<void> signIn(String email, String password) async {
    final cred = await _authService.signIn(email, password);
    // Fetch full user data including role
    _currentUser = await _userService.getUserById(cred.user!.uid);
    notifyListeners();
  }

  // Add resetPassword method
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print("Error resetting password: $e");
      throw e;
    }
  }

  // Add signInWithGoogle method
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);

      // Fetch full user data including role
      _currentUser = await _userService.getUserById(userCredential.user!.uid);
      notifyListeners();

      return userCredential;
    } catch (e) {
      print("Google sign-in error: $e");
      throw e;
    }
  }
}

