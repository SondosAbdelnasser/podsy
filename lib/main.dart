import 'package:flutter/material.dart';
import 'package:podsy/screens/onboarding_screen.dart';
import 'package:podsy/screens/upload_podcast.dart';
import 'package:podsy/widgets/auth_form.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'providers/auth_provider.dart' as local_auth; 
import 'screens/login_screen.dart';   
import 'screens/admin_dashboard_screen.dart';
import 'screens/create_podcast_screen.dart';
import 'screens/user_podcasts_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/users_list_page.dart';
import 'screens/play_screen.dart';
import 'utils/supabase_config.dart';
import 'theme/app_theme.dart';
import 'services/audio_player_service.dart';
import 'services/like_service.dart';
import 'services/deep_link_service.dart';
import 'widgets/auth_wrapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
        ChangeNotifierProvider(create: (context) => local_auth.AuthProvider()),
        ChangeNotifierProvider(create: (context) => AudioPlayerService()),
        ChangeNotifierProvider(
          create: (context) {
            final authProvider = Provider.of<local_auth.AuthProvider>(context, listen: false);
            if (!authProvider.isLoggedIn) {
              throw Exception("User not logged in");
            }
            return LikeService(userId: authProvider.currentUser!.id);
          },
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);
  
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final DeepLinkService _deepLinkService = DeepLinkService();

  @override
  void initState() {
    super.initState();
    // Initialize deep link service after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _deepLinkService.init(context);
    });
  }

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
        '/createPodcast': (context) => AuthWrapper(child: CreatePodcastScreen()),
        '/myPodcasts': (context) => AuthWrapper(child: UserPodcastsScreen()),
        '/profile': (context) => AuthWrapper(child: ProfileScreen()),
        '/episode': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return AuthWrapper(
            child: PlayScreen(episode: args['episode']),
          );
        },
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
