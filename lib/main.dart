import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'services/podcast_service.dart';
import 'services/embedding_service.dart';
import 'config/api_keys.dart';
import 'utils/supabase_config.dart';
import 'widgets/auth_form.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/upload_podcast_screen.dart';
import 'screens/user_podcasts_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/main_navigation.dart';
import 'screens/play_screen.dart';
import 'screens/transcription_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Supabase using the config from supabase_config.dart
  await SupabaseConfig.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        Provider<EmbeddingService>(
          create: (_) => EmbeddingService(
            apiKey: ApiKeys.huggingFaceApiKey,
            provider: EmbeddingProvider.huggingFace,
          ),
        ),
        Provider<PodcastService>(
          create: (context) => PodcastService(
            client: SupabaseConfig.client,
            embeddingService: context.read<EmbeddingService>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Podsy',
        debugShowCheckedModeBanner: false,
        home: const AuthForm(),
        routes: {
          '/onboarding': (context) => const OnboardingScreen(),
          '/home': (context) => const MainNavigation(),
          '/login': (context) => const LoginScreen(),
          '/adminDashboard': (context) => const AdminDashboardScreen(),
          '/createPodcast': (context) => const CreatePodcastScreen(),
          '/myPodcasts': (context) => const UserPodcastsScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/episode': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
            return PlayScreen(episode: args['episode']);
          },
          '/transcription': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
            return TranscriptionScreen(
              audioUrl: args['audioUrl'],
              episodeId: args['episodeId'],
            );
          },
        },
      ),
    );
  }
}
