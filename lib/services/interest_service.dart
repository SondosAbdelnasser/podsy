import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/interest.dart';

class InterestService {
  final supabase = Supabase.instance.client;

  Future<List<Interest>> getInterests() async {
    final response = await supabase.from('categories').select();
    return (response as List)
        .map((item) => Interest.fromMap(item))
        .toList();
  }
}
