import 'package:flutter/material.dart';
import 'package:flutter_application_6/widgets/auth_form.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'providers/auth_provider.dart'; 
import 'screens/home_screen.dart';    
import 'screens/login_screen.dart';   
import 'screens/admin_dashboard_screen.dart';
import 'utils/supabase_config.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase for authentication
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Supabase for database
  await SupabaseConfig.initialize();
  
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
      theme: AppTheme.darkTheme,
      home: AuthForm(),
      routes: {
        '/home': (context) => HomeScreen(),
        '/login': (context) => LoginScreen(),
        '/adminDashboard': (context) => AdminDashboardScreen(),
      },
    );
  }
}
