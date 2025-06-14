import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'package:lottie/lottie.dart';
import '../widgets/auth_form.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Wait for auth provider to initialize
    while (!authProvider.isInitialized) {
      await Future.delayed(Duration(milliseconds: 100));
    }

    if (authProvider.isLoggedIn) {
      if (authProvider.is_admin) {
        Navigator.pushReplacementNamed(context, '/adminDashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Lottie.asset('assets/animations/Animation - 1745259806692.json', width: 150)
      ),
    );
  }
}
