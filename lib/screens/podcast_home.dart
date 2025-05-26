import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/podcast_card.dart';
import '../widgets/episode_tile.dart';
import 'profile_screen.dart'; 

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<Home> {
  final supabase = Supabase.instance.client;

  List<dynamic> trendingPodcasts = [];
  List<dynamic> newEpisodes = [];
  bool isLoading = true;

  Future<void> fetchData() async {
    setState(() => isLoading = true);

    try {
      final podcastResponse = await supabase
          .from('podcasts')
          .select()
          .order('likes', ascending: false)
          .limit(5);

      final episodeResponse = await supabase
          .from('episodes')
          .select()
          .order('created_at', ascending: false)
          .limit(10);

      setState(() {
        trendingPodcasts = podcastResponse;
        newEpisodes = episodeResponse;
      });
    } catch (e) {
      print("Error fetching data: $e");
    }

    setState(() => isLoading = false);
  }

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Discover',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Colors.black,
        child: ListView(
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.black,
              ),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.account_circle, color: Colors.white),
              title: const Text('Profile', style: TextStyle(color: Colors.white)),
              onTap: () {
                // Navigate to Profile Screen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfileScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchData,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  const Text(
                    'Trending Podcasts',
                    style: TextStyle(fontSize: 20, color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 240,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: trendingPodcasts.length,
                      itemBuilder: (context, index) {
                        final podcast = trendingPodcasts[index];
                        return PodcastCard(podcast: podcast);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'New Episodes',
                    style: TextStyle(fontSize: 20, color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: newEpisodes.length,
                    itemBuilder: (context, index) {
                      final episode = newEpisodes[index];
                      return EpisodeTile(episode: episode);
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
