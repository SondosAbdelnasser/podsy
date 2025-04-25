import 'package:flutter/material.dart';
import 'package:flutter_application_6/widgets/auth_form.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'providers/auth_provider.dart'; 
import 'screens/home_screen.dart';    
import 'screens/login_screen.dart';   
import 'screens/admin_dashboard_screen.dart';
void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Podsy',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: AuthForm(),  // Make sure this is not null and correctly initialized
      routes: {
        '/home': (context) => HomeScreen(),
        '/login': (context) => LoginScreen(),
        '/adminDashboard': (context) => AdminDashboardScreen(),
      },
    );
  }
}
