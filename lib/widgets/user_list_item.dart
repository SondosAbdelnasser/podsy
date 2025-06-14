import 'package:flutter/material.dart';

class UserListItem extends StatelessWidget {
  final String email;
  final bool is_admin;
  final VoidCallback? onPromote;
  final VoidCallback? onDelete;

  const UserListItem({
    required this.email,
    required this.is_admin,
    this.onPromote,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(email),
      subtitle: Text("Role: ${is_admin ? 'Admin' : 'User'}"),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!is_admin && onPromote != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: ElevatedButton(
                onPressed: onPromote,
                child: Text("Promote"),
              ),
            ),
          if (onDelete != null)
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
