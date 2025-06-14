import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart';
import '../models/podcast_collection.dart';
import '../models/episode.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/podcast.dart' as podcast_model;
import '../screens/podcast_details_screen.dart';
import '../services/follow_service.dart';
import '../models/follow.dart'; // Import Follow model for FollowStatus

class UserProfilePage extends StatefulWidget {
  final String userId;

  const UserProfilePage({Key? key, required this.userId}) : super(key: key);

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _supabase = Supabase.instance.client;
  UserModel? _user;
  List<PodcastCollection> _collections = [];
  Map<String, List<Episode>> _episodesByCollection = {};
  int _followersCount = 0;
  int _followingCount = 0;
  final FollowService _followService = FollowService();
  bool _isFollowing = false;
  bool _hasPendingRequest = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Load user data
      final userResponse = await _supabase
          .from('users')
          .select()
          .eq('id', widget.userId)
          .single();
      _user = UserModel.fromMap(userResponse, userResponse['id']);

      // Load collections
      final collectionsResponse = await _supabase
          .from('podcast_collections')
          .select()
          .eq('user_id', widget.userId)
          .order('created_at', ascending: false);
      _collections = collectionsResponse
          .map((data) => PodcastCollection.fromMap(data, data['id']))
          .toList();

      // Load episodes for each collection
      for (var collection in _collections) {
        final episodesResponse = await _supabase
            .from('episodes')
            .select()
            .eq('collection_id', collection.id)
            .order('created_at', ascending: false);
        _episodesByCollection[collection.id] = episodesResponse
            .map((data) => Episode.fromMap(data, data['id']))
            .toList();
      }

      // Load followers and following counts
      final followersResponse = await _supabase
          .from('follows')
          .select()
          .eq('followed_id', widget.userId)
          .eq('status', 'accepted');
      _followersCount = followersResponse.length;

      final followingResponse = await _supabase
          .from('follows')
          .select()
          .eq('follower_id', widget.userId)
          .eq('status', 'accepted');
      _followingCount = followingResponse.length;

      // Check if current user is following or has pending request
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        _isFollowing = await _followService.isFollowing(currentUser.uid, widget.userId);
        _hasPendingRequest = await _followService.hasPendingRequest(currentUser.uid, widget.userId);
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user data: $e')),
      );
    }
  }

  Future<void> _toggleFollow() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to follow users')),
        );
        return;
      }

      // Don't allow following yourself
      if (currentUser.uid == widget.userId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You cannot follow yourself')),
        );
        return;
      }

      if (_isFollowing) {
        // Unfollow
        final followEntry = await _supabase
            .from('follows')
            .select('id')
            .eq('follower_id', currentUser.uid)
            .eq('followed_id', widget.userId)
            .eq('status', FollowStatus.accepted.toString().split('.').last)
            .maybeSingle();

        if (followEntry != null) {
          await _followService.rejectFollowRequest(followEntry['id']);
          setState(() {
            _followersCount--;
            _isFollowing = false;
          });
        }
      } else if (_hasPendingRequest) {
        // Cancel pending request
        final followEntry = await _supabase
            .from('follows')
            .select('id')
            .eq('follower_id', currentUser.uid)
            .eq('followed_id', widget.userId)
            .eq('status', FollowStatus.pending.toString().split('.').last)
            .maybeSingle();

        if (followEntry != null) {
          await _followService.rejectFollowRequest(followEntry['id']);
          setState(() {
            _hasPendingRequest = false;
          });
        }
      } else {
        // Send follow request
        await _followService.sendFollowRequest(currentUser.uid, widget.userId);
        setState(() {
          _hasPendingRequest = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Follow request sent')),
        );
      }
    } catch (e) {
      String errorMessage = 'Failed to send follow request.';
      if (e.toString().contains('A follow request already exists')) {
        errorMessage = 'You have already sent a follow request to this user.';
      } else {
        errorMessage = 'Error: ${e.toString()}';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }

  void _showFollowersList() {
    // TODO: Implement followers list page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Followers list coming soon')),
    );
  }

  void _showFollowingList() {
    // TODO: Implement following list page
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Following list coming soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return const Scaffold(
        body: Center(child: Text('User not found')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        title: Text(
          _user!.name,
          style: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                        child: Text(
                          _user!.name[0].toUpperCase(),
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _user!.name,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            if (_user!.username != null)
                              Text(
                                '@${_user!.username}',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: _showFollowersList,
                        child: Column(
                          children: [
                            Text(
                              _followersCount.toString(),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              'Followers',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: _showFollowingList,
                        child: Column(
                          children: [
                            Text(
                              _followingCount.toString(),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            Text(
                              'Following',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _toggleFollow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        _isFollowing ? 'Unfollow' : (_hasPendingRequest ? 'Cancel Request' : 'Follow'),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Collections and Episodes
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Collections',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_collections.isEmpty)
                    Center(
                      child: Text(
                        'No collections yet',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _collections.length,
                      itemBuilder: (context, index) {
                        final collection = _collections[index];
                        final episodes = _episodesByCollection[collection.id] ?? [];
                        return Card(
                          elevation: 2,
                          margin: EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                title: Text(
                                  collection.title,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Text(
                                  collection.description ?? '',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                                onTap: () {
                                  final podcast = podcast_model.Podcast(
                                    id: collection.id,
                                    title: collection.title,
                                    author: _user!.name,
                                    description: collection.description ?? '',
                                    imageUrl: '',
                                    feedUrl: '',
                                    episodes: episodes.map((e) => podcast_model.Episode(
                                      id: e.id!,
                                      title: e.title,
                                      description: e.description ?? '',
                                      audioUrl: e.audioUrl,
                                      publishDate: e.publishedAt ?? DateTime.now(),
                                      duration: e.duration.inMilliseconds,
                                      imageUrl: '',
                                    )).toList(),
                                    category: 'Personal',
                                    rating: 0.0,
                                    episodeCount: episodes.length,
                                  );
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PodcastDetailsScreen(podcast: podcast),
                                    ),
                                  );
                                },
                              ),
                              if (episodes.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: Text(
                                    '${episodes.length} ${episodes.length == 1 ? 'episode' : 'episodes'}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 