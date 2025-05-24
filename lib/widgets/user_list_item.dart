import 'package:flutter/material.dart';

class UserListItem extends StatelessWidget {
  final String email;
  final bool is_admin;
  final VoidCallback? onPromote;

  const UserListItem({
    required this.email,
    required this.is_admin,
    this.onPromote,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(email),
      subtitle: Text("Role: ${is_admin ? 'Admin' : 'User'}"),
      trailing: !is_admin
          ? ElevatedButton(
              onPressed: onPromote,
              child: Text("Promote to Admin"),
            )
          : null,
    );
  }
}
