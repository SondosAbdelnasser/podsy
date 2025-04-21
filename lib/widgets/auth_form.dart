import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class AuthForm extends StatefulWidget {
  @override
  _AuthFormState createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;

  bool _isLoading = false;

 void _submit() async {
  final email = _emailController.text.trim();
  final password = _passwordController.text.trim();
  if (email.isEmpty || password.isEmpty) return;

  setState(() => _isLoading = true);

  try {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (_isLogin) {
      await authProvider.signIn(email, password);
    } else {
      await authProvider.signUp(email, password);
    }

    // 🎯 Navigate only if user was authenticated
    if (authProvider.isAdmin != null) {
      Navigator.pushReplacementNamed(
        context,
        authProvider.isAdmin ? '/admin' : '/home',
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Login failed or user role not found."),
      ));
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Error: ${e.toString()}"),
    ));
  }

  setState(() => _isLoading = false);
}

  @override
 Widget build(BuildContext context) {
  return Center(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: _isLoading
          ? CircularProgressIndicator()
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(labelText: "Email"),
                ),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: "Password"),
                  obscureText: true,
                ),
                SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _submit,
                  child: Text(_isLogin ? "Sign In" : "Sign Up"),
                ),
                TextButton(
                  onPressed: () =>
                      setState(() => _isLogin = !_isLogin),
                  child: Text(_isLogin
                      ? "Create an account"
                      : "Already have an account? Sign in"),
                ),
              ],
            ),
    ),
  );
}

}
