import 'package:flutter/material.dart';
import 'package:podsy/screens/onboarding_screen.dart';
import 'package:podsy/screens/upload_podcast.dart';
import 'package:podsy/widgets/auth_form.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'providers/auth_provider.dart'; 
import 'screens/login_screen.dart';   
import 'screens/admin_dashboard_screen.dart';
import 'screens/create_podcast_screen.dart';
import 'screens/user_podcasts_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/users_list_page.dart';
import 'utils/supabase_config.dart';
import 'theme/app_theme.dart';
import 'services/audio_player_service.dart';
import 'widgets/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase for authentication
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Supabase for database
  await SupabaseConfig.initialize();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AudioPlayerService()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
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
        '/onboarding': (context) => OnboardingScreen(),
        '/home': (context) => AuthWrapper(child: MainNavigation()),
        '/login': (context) => LoginScreen(),
        '/adminDashboard': (context) => AuthWrapper(child: AdminDashboardScreen()),
       // '/uploadPodcast': (context) => AuthWrapper(child: UploadPodcastScreen()),
        '/createPodcast': (context) => AuthWrapper(child: CreatePodcastScreen()),
        '/myPodcasts': (context) => AuthWrapper(child: UserPodcastsScreen()),
        '/profile': (context) => AuthWrapper(child: ProfileScreen()),
      },
    );
  }
}

// class HomeScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Home'),
//         backgroundColor: Colors.black,
//         foregroundColor: Colors.white,
//         elevation: 0,
//       ),
//       backgroundColor: Colors.black,
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             ElevatedButton.icon(
//               onPressed: () {
//                 Navigator.pushNamed(context, '/myPodcasts');
//               },
//               icon: Icon(Icons.mic),
//               label: Text('My Podcasts'),
//               style: ElevatedButton.styleFrom(
//                 padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
//                 textStyle: TextStyle(fontSize: 18),
//               ),
//             ),
//             SizedBox(height: 16),
//             ElevatedButton.icon(
//               onPressed: () {
//                 Navigator.pushNamed(context, '/createPodcast');
//               },
//               icon: Icon(Icons.add),
//               label: Text('Create New Podcast'),
//               style: ElevatedButton.styleFrom(
//                 padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
//                 textStyle: TextStyle(fontSize: 18),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
