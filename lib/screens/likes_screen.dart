import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/podcast_card.dart' as widgets;

class LikesScreen extends StatefulWidget {
  @override
  _LikesScreenState createState() => _LikesScreenState();
}

class _LikesScreenState extends State<LikesScreen> {
  final supabase = Supabase.instance.client;
  List<dynamic> likedPodcasts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadLikedPodcasts();
  }

  Future<void> loadLikedPodcasts() async {
    setState(() => isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final currentUser = authProvider.currentUser;

      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final likes = await supabase
          .from('likes')
          .select('podcast_id')
          .eq('user_id', currentUser.id);

      if (likes.isEmpty) {
        setState(() {
          likedPodcasts = [];
          isLoading = false;
        });
        return;
      }

      final podcastIds = likes.map((like) => like['podcast_id']).toList();
      
      final podcasts = await supabase
          .from('podcasts')
          .select()
          .filter('id', 'in', podcastIds); //kant.in_

      setState(() {
        likedPodcasts = podcasts;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading liked podcasts: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Liked Podcasts',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: RefreshIndicator(
        onRefresh: loadLikedPodcasts,
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : likedPodcasts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.favorite_border,
                          size: 64,
                          color: Colors.grey[300],
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No liked podcasts yet',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Like some podcasts to see them here',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: likedPodcasts.length,
                    itemBuilder: (context, index) {
                      final podcast = likedPodcasts[index];
                      return widgets.PodcastCard(
                        podcast: podcast,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/podcast-details',
                            arguments: podcast,
                          );
                        },
                      );
                    },
                  ),
      ),
    );
  }
}