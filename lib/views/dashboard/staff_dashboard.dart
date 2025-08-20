import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/level_controller.dart';
import '../../controllers/leaderboard_controller.dart';

import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../services/supabase_service.dart';
import '../../models/leaderboard.dart'; // Added import for SupabaseService
import '../../views/student_performance_screen.dart'; // Added import for StudentPerformanceScreen
import '../../views/messaging/send_message_screen.dart'; // Added import for SendMessageScreen

class StaffDashboard extends StatefulWidget {
  const StaffDashboard({super.key});

  @override
  State<StaffDashboard> createState() => _StaffDashboardState();
}

class _StaffDashboardState extends State<StaffDashboard> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final levelController = context.read<LevelController>();
    await levelController.loadLevels();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Dashboard'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  Navigator.pushNamed(context, '/edit-profile');
                  break;
                case 'logout':
                  context.read<AuthController>().logout();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person, size: 20),
                    SizedBox(width: 8),
                    Text('Edit Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 20),
                    SizedBox(width: 8),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
            child: const Icon(Icons.account_circle),
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar Navigation
          Container(
            width: 250,
            color: Colors.grey[100],
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  child: const Text(
                    'Staff Panel',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildNavItem(0, 'Assigned Students', Icons.people),
                _buildNavItem(1, 'Performance Overview', Icons.analytics),
                _buildNavItem(2, 'Notifications', Icons.notifications),
                _buildNavItem(3, 'Reports', Icons.assessment),
                _buildNavItem(4, 'Leaderboard', Icons.emoji_events),
              ],
            ),
          ),
          
          // Main Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, String title, IconData icon) {
    final isSelected = _selectedIndex == index;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? Colors.white : Colors.grey[600]),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[800],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        tileColor: isSelected ? Theme.of(context).primaryColor : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildAssignedStudents();
      case 1:
        return _buildPerformanceOverview();
      case 2:
        return _buildNotifications();
      case 3:
        return _buildReports();
      case 4:
        return _buildLeaderboard();
      default:
        return const Center(child: Text('Select a section'));
    }
  }

  Widget _buildAssignedStudents() {
    return Consumer<AuthController>(
      builder: (context, authController, child) {
        final user = authController.currentUser;
        if (user == null) return const SizedBox.shrink();

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _getAssignedStudents(user.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return const Center(
                child: Text('Failed to load assigned students'),
              );
            }

            final students = snapshot.data!;
            
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assigned Students',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Summary Statistics
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        _buildStatCard('Total Students', students.length.toString(), Icons.people, Colors.blue),
                        const SizedBox(width: 16),
                        _buildStatCard('Active', students.where((s) => s['status'] == 'active').length.toString(), Icons.check_circle, Colors.green),
                        const SizedBox(width: 16),
                        _buildStatCard('Pending', students.where((s) => s['status'] == 'pending').length.toString(), Icons.pending, Colors.orange),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  if (students.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'No students assigned to you yet.',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final student = students[index];
                          return _buildStudentCard(student);
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final status = student['status'] ?? 'unknown';
    final statusColor = _getStatusColor(status);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Primary identification - Username or Email
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              student['username'] ?? student['email'] ?? 'Unknown',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: statusColor),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Student identification details
                      Row(
                        children: [
                          if (student['enrollment_no'] != null) ...[
                            _buildInfoChip('EN: ${student['enrollment_no']}', Icons.badge, Colors.purple),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Class and Year information
                      Row(
                        children: [
                          if (student['class'] != null) ...[
                            _buildInfoChip('Class: ${student['class']}', Icons.class_, Colors.blue),
                            const SizedBox(width: 8),
                          ],
                          if (student['year'] != null) ...[
                            _buildInfoChip('Year ${student['year']}', Icons.calendar_today, Colors.teal),
                            const SizedBox(width: 8),
                          ],
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Contact information
                      Row(
                        children: [
                          Icon(Icons.email, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              student['email'] ?? 'No email',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            student['phone'] ?? 'No phone',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
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
                Expanded(
                  child: CustomButton(
                    text: 'View Performance',
                    onPressed: () => _viewStudentPerformance(student),
                    backgroundColor: Colors.blue,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomButton(
                    text: 'Send Message',
                    onPressed: () => _sendNotification(student),
                    backgroundColor: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceOverview() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Performance Overview',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('Performance analytics will be implemented here'),
                  SizedBox(height: 16),
                  Text('• Average Scores'),
                  Text('• Progress Tracking'),
                  Text('• Level Completion Rates'),
                  Text('• Time Analysis'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotifications() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notifications',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Send Notifications',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        CustomButton(
                          text: 'Send to All',
                          onPressed: () => _sendNotificationToAll(),
                          width: 120,
                          backgroundColor: Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Notification Form
                    CustomTextField(
                      controller: TextEditingController(),
                      labelText: 'Message',
                      prefixIcon: Icons.message,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: TextEditingController(),
                            labelText: 'Student Email (optional)',
                            prefixIcon: Icons.person,
                          ),
                        ),
                        const SizedBox(width: 16),
                        CustomButton(
                          text: 'Send',
                          onPressed: () => _sendNotification(null),
                          width: 100,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReports() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Reports',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  Text('Report generation will be implemented here'),
                  SizedBox(height: 16),
                  Text('• Student Progress Reports'),
                  Text('• Performance Analytics'),
                  Text('• Level Completion Reports'),
                  Text('• Time Analysis Reports'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper Methods
  Future<List<Map<String, dynamic>>> _getAssignedStudents(String staffId) async {
    try {
      print('🔍 Fetching assigned students for staff: $staffId');
      
      final students = await SupabaseService.getStudentsByStaff(staffId);
      
      print('📊 Found ${students.length} assigned students');
      
      // Convert User objects to Map for the UI
      return students.map((student) => student.toMap()).toList();
    } catch (e) {
      print('❌ Error fetching assigned students: $e');
      return [];
    }
  }

  void _viewStudentPerformance(Map<String, dynamic> student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StudentPerformanceScreen(student: student),
      ),
    );
  }

  void _sendNotification(Map<String, dynamic>? student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SendMessageScreen(student: student),
      ),
    );
  }

  void _sendNotificationToAll() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sending notification to all assigned students'),
      ),
    );
  }

  Widget _buildLeaderboard() {
    return Consumer<LeaderboardController>(
      builder: (context, leaderboardController, child) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '🏆 Leaderboard',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => leaderboardController.loadGlobalLeaderboard(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Level Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Level',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text('Level: '),
                          const SizedBox(width: 16),
                          DropdownButton<int>(
                            value: leaderboardController.selectedLevelId,
                            items: leaderboardController.availableLevels.map((levelId) {
                              return DropdownMenuItem(
                                value: levelId,
                                child: Text('Level $levelId'),
                              );
                            }).toList(),
                            onChanged: (levelId) {
                              if (levelId != null) {
                                leaderboardController.setSelectedLevel(levelId);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Level Leaderboard
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Level ${leaderboardController.selectedLevelId} Rankings',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      if (leaderboardController.isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (leaderboardController.levelLeaderboard.isEmpty)
                        const Center(
                          child: Text('No leaderboard data for this level yet.'),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: leaderboardController.levelLeaderboard.length,
                          itemBuilder: (context, index) {
                            final entry = leaderboardController.levelLeaderboard[index];
                            final rank = entry.rankPosition ?? index + 1;
                            
                            return _buildLeaderboardRow(entry, rank);
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeaderboardRow(LeaderboardEntry entry, int rank) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: rank <= 3 ? _getRankColor(rank).withOpacity(0.1) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: rank <= 3 ? _getRankColor(rank) : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
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
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.studentName ?? entry.studentEmail ?? 'Unknown Student',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Score: ${entry.scorePercentage}',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                entry.scorePercentage,
                style: TextStyle(
                  fontSize: 18,
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
        ],
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