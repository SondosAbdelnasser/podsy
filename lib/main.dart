import 'package:flutter/material.dart';
import 'package:podsy/screens/onboarding_screen.dart';
import 'package:podsy/screens/upload_podcast.dart';
import 'package:podsy/widgets/auth_form.dart';
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
import 'package:flutter/material.dart';
import 'screens/podcast_home.dart';
import 'screens/onboarding_screen.dart';

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
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: AuthForm(),
      routes: {
        '/onboarding': (context)=> OnboardingScreen(),
        '/home': (context) => Home(),
        '/login': (context) => LoginScreen(),
        '/adminDashboard': (context) => AdminDashboardScreen(),
        //'/uploadPodcast': (context) => UploadPodcastScreen(), // Add this line
      },
      
    );
    


  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Center(
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.pushNamed(context, '/uploadPodcast');
          },
          icon: Icon(Icons.upload),
          label: Text('Upload Podcast'),
        ),
      ),
    );
  }
}
