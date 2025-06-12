import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recommendation_provider.dart';
import '../widgets/usable/episode_card.dart';
import '../models/user_activity.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({super.key});

  @override
  _RecommendationsScreenState createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = Provider.of<RecommendationProvider>(context, listen: false);
    await Future.wait([
      provider.loadRecommendations(),
      provider.loadTrendingEpisodes(),
    ]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Discover'),
        backgroundColor: Colors.deepPurple,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: [
            Tab(text: 'For You'),
            Tab(text: 'Trending'),
          ],
        ),
      ),
      body: Consumer<RecommendationProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error loading recommendations',
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                    ),
                    child: Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              // For You Tab
              _buildEpisodeList(
                provider.recommendations,
                onRefresh: () => provider.loadRecommendations(),
              ),
              // Trending Tab
              _buildEpisodeList(
                provider.trendingEpisodes,
                onRefresh: () => provider.loadTrendingEpisodes(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEpisodeList(List episodes, {required Future<void> Function() onRefresh}) {
    if (episodes.isEmpty) {
      return Center(
        child: Text(
          'No episodes found',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: episodes.length,
        itemBuilder: (context, index) {
          final episode = episodes[index];
          return EpisodeCard(
            episode: episode,
            onTap: () {
              // Track listen activity
              final provider = Provider.of<RecommendationProvider>(context, listen: false);
              provider.trackActivity(UserActivity(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                userId: 'current_user_id', // Replace with actual user ID
                episodeId: episode.id,
                type: ActivityType.listen,
                timestamp: DateTime.now(),
              ));
              // Navigate to episode details or start playback
            },
            onLike: () {
              // Track like activity
              final provider = Provider.of<RecommendationProvider>(context, listen: false);
              provider.trackActivity(UserActivity(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                userId: 'current_user_id', // Replace with actual user ID
                episodeId: episode.id,
                type: ActivityType.like,
                timestamp: DateTime.now(),
              ));
            },
          );
        },
      ),
    );
  }
} 