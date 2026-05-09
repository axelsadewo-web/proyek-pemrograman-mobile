import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_services.dart';

/// Public API habits (untuk HomeScreen)
final apiHabitsProvider = FutureProvider<List<dynamic>>((ref) async {
  return ApiService.fetchHabits();
});
