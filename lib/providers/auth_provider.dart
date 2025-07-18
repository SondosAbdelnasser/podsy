import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    clientId: '554265067111-m12s5d59rfoml99sfjeaub8h2d068j2u.apps.googleusercontent.com',
  );
  final UserService _userService = UserService();

  UserModel? _user;
  bool _isInitialized = false;

  UserModel? get currentUser => _user;
  bool get isLoggedIn => _user != null;
  bool get is_admin => _user?.isAdmin ?? false;
  bool get isInitialized => _isInitialized;

  AuthProvider() {
    _initializeAuthState();
  }

  Future<void> _initializeAuthState() async {
    try {
      // Check for existing session
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final fetchedUser = await _userService.getUserById(currentUser.uid);
        if (fetchedUser != null) {
          _user = fetchedUser;
          notifyListeners();
        }
      }

      // Listen to auth state changes
      _auth.authStateChanges().listen((User? firebaseUser) async {
        if (firebaseUser != null) {
          final fetchedUser = await _userService.getUserById(firebaseUser.uid);
          if (fetchedUser != null) {
            _user = fetchedUser;
            notifyListeners();
          }
        } else {
          _user = null;
          notifyListeners();
        }
      });

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error initializing auth state: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> signUp(String email, String password) async {
    try {
      // Create user in Firebase
      final userCred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCred.user == null) {
        throw Exception('Failed to create Firebase user');
      }

      // Create user in Supabase
      final newUser = UserModel(
        id: userCred.user!.uid,
        email: email,
        name: email.split('@')[0],
        isAdmin: false,
        autoAcceptFollows: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      try {
        await _userService.createUser(newUser);
        _user = newUser;
        notifyListeners();
      } catch (e) {
        // If Supabase creation fails, delete the Firebase user and throw
        await userCred.user!.delete();
        throw Exception('Failed to create user in database: ${e.toString()}');
      }
    } catch (e) {
      // Ensure we're signed out if anything fails
      await _auth.signOut();
      rethrow;
    }
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
    await _googleSignIn.signOut();
    await _auth.signOut();
    _user = null;
    notifyListeners();
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  Future<void> signInWithGoogle() async {
    try {
      // Start Google Sign In process
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return; // User cancelled the sign-in flow

      // Get Google Auth credentials
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with Google credentials
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;
      
      if (firebaseUser == null) {
        throw Exception('Failed to get Firebase user after Google sign in');
      }

      // Check if user exists in Supabase
      UserModel? existingUser = await _userService.getUserById(firebaseUser.uid);
      
      if (existingUser == null) {
        // Create new user in Supabase if doesn't exist
        final email = firebaseUser.email ?? '';
        final name = firebaseUser.displayName ?? (email.isNotEmpty ? email.split('@')[0] : 'Unknown');
        final newUser = UserModel(
          id: firebaseUser.uid,
          email: email,
          name: name,
          isAdmin: false,
          autoAcceptFollows: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        
        await _userService.createUser(newUser);
        _user = newUser;
      } else {
        _user = existingUser;
      }
      
      notifyListeners();
    } catch (e) {
      // If anything fails, ensure we clean up
      await _googleSignIn.signOut();
      await _auth.signOut();
      rethrow;
    }
  }
}
