import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'lib/services/supabase_service.dart';

void main() async {
  // Initialize Supabase
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_SUPABASE_ANON_KEY',
  );
  
  print('🧪 Testing Leaderboard System...');
  
  try {
    // Test 1: Debug current state
    print('\n📊 Test 1: Debug Leaderboard State');
    await SupabaseService.debugLeaderboard();
    
    // Test 2: Try to fetch global leaderboard
    print('\n🏆 Test 2: Fetch Global Leaderboard');
    final globalLeaderboard = await SupabaseService.getGlobalLeaderboard();
    print('✅ Global leaderboard entries: ${globalLeaderboard.length}');
    
    // Test 3: Try to fetch level-specific leaderboard (if levels exist)
    print('\n📚 Test 3: Fetch Level Leaderboard');
    if (globalLeaderboard.isNotEmpty) {
      final firstLevelId = globalLeaderboard.first.levelId;
      final levelLeaderboard = await SupabaseService.getLeaderboardForLevel(firstLevelId);
      print('✅ Level $firstLevelId leaderboard entries: ${levelLeaderboard.length}');
    } else {
      print('ℹ️ No levels with data to test');
    }
    
    print('\n✅ All tests completed successfully!');
    
  } catch (e) {
    print('❌ Test failed: $e');
  }
}
