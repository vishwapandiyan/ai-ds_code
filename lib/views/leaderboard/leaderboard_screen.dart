import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/leaderboard_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../models/leaderboard.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isGlobalView = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final leaderboardController = context.read<LeaderboardController>();
      leaderboardController.loadGlobalLeaderboard();
      if (leaderboardController.availableLevels.isNotEmpty) {
        leaderboardController.loadLevelLeaderboard(
          leaderboardController.availableLevels.first,
        );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🏆 Leaderboard'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Global Ranking'),
            Tab(text: 'Level Ranking'),
          ],
          onTap: (index) {
            setState(() {
              _isGlobalView = index == 0;
            });
          },
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGlobalLeaderboard(),
          _buildLevelLeaderboard(),
        ],
      ),
    );
  }

  Widget _buildGlobalLeaderboard() {
    return Consumer<LeaderboardController>(
      builder: (context, controller, child) {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${controller.error}'),
                ElevatedButton(
                  onPressed: () => controller.loadGlobalLeaderboard(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (controller.globalLeaderboard.isEmpty) {
          return const Center(
            child: Text('No leaderboard data available yet.'),
          );
        }

        return RefreshIndicator(
          onRefresh: controller.loadGlobalLeaderboard,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: controller.globalLeaderboard.length,
            itemBuilder: (context, index) {
              final entry = controller.globalLeaderboard[index];
              final rank = index + 1;
              
              return _buildLeaderboardCard(
                entry: entry,
                rank: rank,
                showLevel: true,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildLevelLeaderboard() {
    return Consumer<LeaderboardController>(
      builder: (context, controller, child) {
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text('Select Level: ', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 16),
                  DropdownButton<int>(
                    value: controller.selectedLevelId,
                    items: controller.availableLevels.map((levelId) {
                      return DropdownMenuItem(
                        value: levelId,
                        child: Text('Level $levelId'),
                      );
                    }).toList(),
                    onChanged: (levelId) {
                      if (levelId != null) {
                        controller.setSelectedLevel(levelId);
                      }
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: Consumer<LeaderboardController>(
                builder: (context, leaderboardController, child) {
                  if (leaderboardController.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (leaderboardController.error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Error: ${leaderboardController.error}'),
                          ElevatedButton(
                            onPressed: () => leaderboardController.loadLevelLeaderboard(
                              leaderboardController.selectedLevelId,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (leaderboardController.levelLeaderboard.isEmpty) {
                    return const Center(
                      child: Text('No leaderboard data for this level yet.'),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => leaderboardController.loadLevelLeaderboard(
                      leaderboardController.selectedLevelId,
                    ),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: leaderboardController.levelLeaderboard.length,
                      itemBuilder: (context, index) {
                        final entry = leaderboardController.levelLeaderboard[index];
                        final rank = entry.rankPosition ?? index + 1;
                        
                        return _buildLeaderboardCard(
                          entry: entry,
                          rank: rank,
                          showLevel: false,
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLeaderboardCard({
    required LeaderboardEntry entry,
    required int rank,
    required bool showLevel,
  }) {
    final isCurrentUser = context.read<AuthController>().currentUser?.id == entry.studentId;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: rank <= 3 ? 4 : 1,
      color: rank <= 3 
          ? _getRankColor(rank)
          : isCurrentUser 
              ? Colors.blue.shade50
              : null,
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: _getRankColor(rank),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              rank.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                entry.studentName ?? entry.studentEmail ?? 'Unknown Student',
                style: TextStyle(
                  fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                  color: isCurrentUser ? Colors.blue.shade700 : null,
                ),
              ),
            ),
            if (isCurrentUser)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'You',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showLevel)
              Text(
                'Level ${entry.levelNumber}: ${entry.levelTitle ?? 'Unknown Level'}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.score, size: 16, color: Colors.green.shade600),
                const SizedBox(width: 4),
                Text(
                  'Score: ${entry.scorePercentage}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 16),
                Icon(Icons.timer, size: 16, color: Colors.orange.shade600),
                const SizedBox(width: 4),
                Text(
                  'Time: ${entry.formattedTime}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              entry.scorePercentage,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _getScoreColor(entry.score),
              ),
            ),
            Text(
              entry.formattedTime,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber.shade400;
      case 2:
        return Colors.grey.shade400;
      case 3:
        return Colors.orange.shade400;
      default:
        return Colors.blue.shade400;
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 90) return Colors.green.shade600;
    if (score >= 80) return Colors.blue.shade600;
    if (score >= 70) return Colors.orange.shade600;
    return Colors.red.shade600;
  }
}
