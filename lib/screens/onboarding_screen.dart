import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/interest_provider.dart';

class OnboardingScreen extends StatefulWidget {
  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    // Fetch interests from the provider when the screen is loaded
    Provider.of<InterestProvider>(context, listen: false).fetchInterests();
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final interests = Provider.of<InterestProvider>(context).interests;

    // Display a loading spinner while interests are being fetched
    if (interests.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text("Choose Your Interests"),
          backgroundColor: Colors.deepPurple,
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Choose Your Interests"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Interests as cards (chipss
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: interests.map((interest) {
                return GestureDetector(
                  onTap: () => _toggleSelection(interest.id),
                  child: Card(
                    elevation: 5,
                    color: _selectedIds.contains(interest.id) ? Colors.deepPurple : Colors.grey[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star, // Just an example icon, replace with your own
                            color: _selectedIds.contains(interest.id) ? Colors.white : Colors.grey,
                          ),
                          SizedBox(height: 8),
                          Text(
                            interest.name,
                            style: TextStyle(
                              color: _selectedIds.contains(interest.id) ? Colors.white : Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const Spacer(),
            // Continue Button
            ElevatedButton(
              onPressed: _selectedIds.isEmpty
                  ? null
                  : () {
                      Navigator.pushReplacementNamed(context, '/home');
                    },
              child: const Text("Continue"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
