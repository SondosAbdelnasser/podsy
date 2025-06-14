import 'package:flutter/material.dart';
import '../models/follow.dart';
import '../services/follow_service.dart';
import '../services/user_service.dart';
import '../models/user.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class FollowRequestsScreen extends StatefulWidget {
  @override
  _FollowRequestsScreenState createState() => _FollowRequestsScreenState();
}

class _FollowRequestsScreenState extends State<FollowRequestsScreen> {
  final FollowService _followService = FollowService();
  final UserService _userService = UserService();
  List<Follow> _pendingRequests = [];
  Map<String, UserModel> _userCache = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPendingRequests();
  }

  Future<void> _loadPendingRequests() async {
    try {
      setState(() => _isLoading = true);
      final currentUser = Provider.of<AuthProvider>(context, listen: false).currentUser;
      final requests = await _followService.getPendingFollowRequests(currentUser?.id ?? '');
      setState(() {
        _pendingRequests = requests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading follow requests: ${e.toString()}')),
      );
    }
  }

  Future<UserModel?> _getUserDetails(String userId) async {
    if (_userCache.containsKey(userId)) {
      return _userCache[userId];
    }

    try {
      final user = await _userService.getUserById(userId);
      if (user != null) {
        _userCache[userId] = user;
      }
      return user;
    } catch (e) {
      print('Error getting user details: $e');
      return null;
    }
  }

  Future<void> _handleFollowRequest(String followId, bool accept) async {
    try {
      if (accept) {
        await _followService.acceptFollowRequest(followId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Follow request accepted')),
        );
      } else {
        await _followService.rejectFollowRequest(followId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Follow request rejected')),
        );
      }
      _loadPendingRequests(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error handling follow request: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Follow Requests'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _pendingRequests.isEmpty
              ? Center(
                  child: Text(
                    'No pending follow requests',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: _pendingRequests.length,
                  itemBuilder: (context, index) {
                    final request = _pendingRequests[index];
                    return FutureBuilder<UserModel?>(
                      future: _getUserDetails(request.followerId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return ListTile(
                            leading: CircleAvatar(
                              child: CircularProgressIndicator(),
                            ),
                            title: Text('Loading...'),
                          );
                        }

                        final user = snapshot.data;
                        if (user == null) {
                          return ListTile(
                            leading: CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                            title: Text('Unknown User'),
                          );
                        }

                        return Card(
                          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(user.name[0].toUpperCase()),
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            title: Text(user.name),
                            subtitle: Text(user.email),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.check, color: Colors.green),
                                  onPressed: () => _handleFollowRequest(request.id, true),
                                ),
                                IconButton(
                                  icon: Icon(Icons.close, color: Colors.red),
                                  onPressed: () => _handleFollowRequest(request.id, false),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
    );
  }
} 