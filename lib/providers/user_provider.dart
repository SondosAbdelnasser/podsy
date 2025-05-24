import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class UserProvider with ChangeNotifier {
  final UserService _userService = UserService();
  List<UserModel> _users = [];

  List<UserModel> get users => _users;

  Future<void> fetchUsers() async {
    _users = await _userService.fetchAllUsers();
    notifyListeners();
  }

  Future<void> promoteToAdmin(String uid) async {
    await _userService.updateUserRole(uid, true); // Set is_admin to true
    await fetchUsers(); // Refresh after update
  }

  Future<void> demoteFromAdmin(String uid) async {
    await _userService.updateUserRole(uid, false); // Set is_admin to false
    await fetchUsers(); // Refresh after update
  }
}
