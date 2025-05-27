import 'package:flutter/material.dart';
import '../models/interest.dart';
import '../services/interest_service.dart';

class InterestProvider with ChangeNotifier {
  final InterestService _interestService = InterestService();
  List<Interest> _interests = [];

  List<Interest> get interests => _interests;

  Future<void> fetchInterests() async {
    _interests = await _interestService.getInterests();
    notifyListeners();
  }
}
