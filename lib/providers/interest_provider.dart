import 'package:flutter/foundation.dart';
import '../services/interest_service.dart';
import '../models/interest.dart';
import '../utils/supabase_config.dart';

class InterestProvider extends ChangeNotifier {
  final InterestService _interestService;
  List<Interest> _interests = [];
  bool _isLoading = false;
  String? _error;

  InterestProvider() : _interestService = InterestService(SupabaseConfig.client);

  List<Interest> get interests => _interests;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadInterests() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _interests = await _interestService.getInterests();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateInterestScore(String categoryId, double score) async {
    try {
      await _interestService.updateInterestScores(
        SupabaseConfig.client.auth.currentUser?.id ?? '',
        categoryId,
        score,
      );
      await loadInterests(); // Refresh interests after update
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<List<Interest>> getTopInterests({int limit = 5}) async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      return await _interestService.getUserTopInterests(userId, limit: limit);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }

  Future<List<Interest>> getRecommendedCategories() async {
    try {
      final userId = SupabaseConfig.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }
      return await _interestService.getRecommendedCategories(userId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return [];
    }
  }
}
