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
import 'screens/transcription_screen.dart';
import 'utils/supabase_config.dart';
import 'theme/app_theme.dart';
import 'services/audio_player_service.dart';
import 'services/like_service.dart';
import 'services/deep_link_service.dart';
import 'services/transcription_service.dart';
import 'services/embedding_service.dart';
import 'services/supabase_service.dart';
import 'providers/transcription_provider.dart';
import 'widgets/auth_wrapper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/podcast_service.dart';
import 'config/api_keys.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase for authentication
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Supabase for database
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
  
  // Create services
  final transcriptionService = TranscriptionService('7a2e53c8702a4786a0b461a491c46d72');
  final embeddingService = EmbeddingService(
    apiKey: ApiKeys.huggingFaceApiKey,
    provider: EmbeddingProvider.huggingFace,
  );
  final supabaseService = SupabaseService(Supabase.instance.client);
  
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
        ChangeNotifierProvider(
          create: (_) => TranscriptionProvider(
            transcriptionService: transcriptionService,
            embeddingService: embeddingService,
            supabaseService: supabaseService,
          ),
        ),
        Provider<PodcastService>(
          create: (_) => PodcastService(
            client: Supabase.instance.client,
            embeddingService: embeddingService,
          ),
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  
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
        '/transcription': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return AuthWrapper(
            child: TranscriptionScreen(
              audioUrl: args['audioUrl'],
              episodeId: args['episodeId'],
            ),
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
