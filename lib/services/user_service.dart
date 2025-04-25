import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class UserService {
  final CollectionReference users = FirebaseFirestore.instance.collection('users');

  Future<UserModel?> getUserById(String uid) async {
    final doc = await users.doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Future<List<UserModel>> fetchAllUsers() async {
    final snapshot = await users.get();
    return snapshot.docs.map((doc) {
      return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }).toList();
  }
  Future<void> createUser(UserModel user) async {
  await users.doc(user.id).set(user.toMap());
  }
  Future<void> updateUserRole(String uid, bool isAdmin) async {
    await users.doc(uid).update({'isAdmin': isAdmin});
  }
}
