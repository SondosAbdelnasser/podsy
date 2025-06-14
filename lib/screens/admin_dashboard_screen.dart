import 'package:flutter/material.dart';
import 'package:podsy/models/podcast.dart';
import '../services/user_service.dart';
import '../models/user.dart';
import '../widgets/user_list_item.dart';
import '../services/podcast_service.dart';
import '../widgets/podcast_card.dart';
import '../screens/podcast_details_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final UserService _userService = UserService();
  final PodcastService _podcastService = PodcastService();
  List<UserModel> _users = [];
  List<Podcast> _allPodcasts = [];
  bool _isLoadingUsers = true;
  bool _isLoadingPodcasts = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadUsers(),
      _loadAllPodcastsForAdmin(),
    ]);
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final users = await _userService.fetchAllUsers();
      setState(() {
        _users = users;
        _isLoadingUsers = false;
      });
    } catch (e) {
      print('Error loading users: $e');
      setState(() => _isLoadingUsers = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading users: ${e.toString()}')),
      );
    }
  }

  Future<void> _loadAllPodcastsForAdmin() async {
    setState(() => _isLoadingPodcasts = true);
    try {
      final podcasts = await _podcastService.getAllPodcastsForAdmin();
      setState(() {
        _allPodcasts = podcasts;
        _isLoadingPodcasts = false;
      });
    } catch (e) {
      print('Error loading all podcasts: $e');
      setState(() => _isLoadingPodcasts = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading all podcasts: ${e.toString()}')),
      );
    }
  }

  Future<void> _promoteToAdmin(String uid, bool isAdmin) async {
    try {
      await _userService.updateUserRole(uid, isAdmin);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isAdmin ? 'User promoted to admin!' : 'User demoted from admin!')),
      );
      _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update user role: ${e.toString()}')),
      );
    }
  }

  Future<void> _softDeleteUser(String uid, String email) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(' Delete User'),
          content: Text('Are you sure you want to remove user "${email}"? This will hide them from views.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await _userService.softDeleteUser(uid);
                  await _loadUsers();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('User deleted successfully!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to soft delete user: ${e.toString()}')),
                  );
                }
                Navigator.of(context).pop();
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _softDeletePodcastByAdmin(String podcastId, String podcastTitle) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(' Delete Podcast'),
          content: Text('Are you sure you want to remove podcast "${podcastTitle}"? This will hide it from all views.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await _podcastService.softDeletePodcast(podcastId);
                  await _loadAllPodcastsForAdmin();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Podcast deleted successfully!')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to soft delete podcast: ${e.toString()}')),
                  );
                }
                Navigator.of(context).pop();
              },
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< Updated upstream
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Admin Dashboard"),
          bottom: TabBar(
            tabs: [
              Tab(text: "Users"),
              Tab(text: "Podcasts"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _isLoadingUsers
                ? Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? Center(child: Text('No users found.'))
                    : RefreshIndicator(
                        onRefresh: _loadUsers,
                        child: ListView.builder(
                          itemCount: _users.length,
                          itemBuilder: (ctx, i) {
                            final user = _users[i];
                            return UserListItem(
                              email: user.email,
                              is_admin: user.isAdmin,
                              onPromote: () => _promoteToAdmin(user.id, !user.isAdmin),
                              onDelete: () => _softDeleteUser(user.id, user.email),
                            );
                          },
                        ),
                      ),
            _isLoadingPodcasts
                ? Center(child: CircularProgressIndicator())
                : _allPodcasts.isEmpty
                    ? Center(child: Text('No podcasts found.'))
                    : RefreshIndicator(
                        onRefresh: _loadAllPodcastsForAdmin,
                        child: GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: _allPodcasts.length,
                          itemBuilder: (context, index) {
                            final podcast = _allPodcasts[index];
                            return PodcastCard(
                              podcast: podcast,
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => PodcastDetailsScreen(podcast: podcast)));
                              },
                              trailing: IconButton(
                                icon: Icon(
                                  podcast.isDeleted ? Icons.restore_from_trash : Icons.delete_outline,
                                  color: podcast.isDeleted ? Colors.green : Colors.red,
                                ),
                                onPressed: () => _softDeletePodcastByAdmin(podcast.id, podcast.title),
                              ),
                            );
                          },
                        ),
                      ),
          ],
        ),
=======
    return Scaffold(
      appBar: AppBar(title: const Text("Admin Dashboard")),
      body: ListView.builder(
        itemCount: _users.length,
        itemBuilder: (ctx, i) {
          final user = _users[i];
          return UserListItem(
            email: user.email,
            is_admin: user.isAdmin,
            onPromote: () => _promoteToAdmin(user.id),
          );
        },
>>>>>>> Stashed changes
      ),
    );
  }
}
