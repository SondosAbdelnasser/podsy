import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<UserCredential> signUp(String email, String password) async {
    final userCred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    await _firestore.collection("users").doc(userCred.user!.uid).set({
       "email": email,
       "name": email.split('@')[0],
       "is_admin": false,
     });
    return userCred;
  }

  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }
}
