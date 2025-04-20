import 'package:flutter/material.dart';

class UserListItem extends StatelessWidget {
  final String email;
  final bool isAdmin;
  final VoidCallback? onPromote;

  const UserListItem({
    required this.email,
    required this.isAdmin,
    this.onPromote,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(email),
      subtitle: Text("Role: ${isAdmin ? 'Admin' : 'User'}"),
      trailing: !isAdmin
          ? ElevatedButton(
              onPressed: onPromote,
              child: Text("Promote to Admin"),
            )
          : null,
    );
  }
}
