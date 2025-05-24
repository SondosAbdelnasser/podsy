import 'package:flutter/material.dart';
import '../services/user_service.dart';
import '../models/user.dart';
import '../widgets/user_list_item.dart';

class AdminDashboardScreen extends StatefulWidget {
  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final UserService _userService = UserService();
  List<UserModel> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  void _loadUsers() async {
    final users = await _userService.fetchAllUsers();
    setState(() {
      _users = users;
    });
  }

  void _promoteToAdmin(String uid) async {
    await _userService.updateUserRole(uid, true);
    _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Admin Dashboard")),
      body: ListView.builder(
        itemCount: _users.length,
        itemBuilder: (ctx, i) {
          final user = _users[i];
          return UserListItem(
            email: user.email,
            is_admin: user.is_admin,
            onPromote: () => _promoteToAdmin(user.id),
          );
        },
      ),
    );
  }
}
