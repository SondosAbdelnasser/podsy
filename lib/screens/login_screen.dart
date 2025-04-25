import 'package:flutter/material.dart';
import '../widgets/auth_form.dart';

class LoginScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login ")),
      body: AuthForm(),
    );
  }
}
