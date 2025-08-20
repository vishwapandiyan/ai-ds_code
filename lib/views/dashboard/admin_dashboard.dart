import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/admin_controller.dart';
import '../../controllers/level_controller.dart';
import '../../controllers/leaderboard_controller.dart';
import '../../models/user.dart';
import '../../models/leaderboard.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../services/supabase_service.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;
  final TextEditingController _staffSearchController = TextEditingController();
  final TextEditingController _studentSearchController = TextEditingController();
  String _staffSearchQuery = '';
  String _studentSearchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adminController = context.read<AdminController>();
      final levelController = context.read<LevelController>();
      
      // Load data only once
      adminController.loadPendingStudents();
      adminController.loadAllStaff();
      levelController.loadLevels();
    });
  }

  @override
  void dispose() {
    _staffSearchController.dispose();
    _studentSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: Colors.grey[800],
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
          // Sidebar
          Container(
            width: 250,
            color: Colors.grey[100],
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: const Text(
                    'Admin Panel',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      _buildNavItem(
                        icon: Icons.person_add,
                        title: 'Student Approvals',
                        isSelected: _selectedIndex == 0,
                        onTap: () => setState(() => _selectedIndex = 0),
                      ),
                      _buildNavItem(
                        icon: Icons.people,
                        title: 'Staff Management',
                        isSelected: _selectedIndex == 1,
                        onTap: () => setState(() => _selectedIndex = 1),
                      ),
                      _buildNavItem(
                        icon: Icons.school,
                        title: 'Student Management',
                        isSelected: _selectedIndex == 2,
                        onTap: () => setState(() => _selectedIndex = 2),
                      ),
                      _buildNavItem(
                        icon: Icons.quiz,
                        title: 'Level Management',
                        isSelected: _selectedIndex == 3,
                        onTap: () => setState(() => _selectedIndex = 3),
                      ),
                      _buildNavItem(
                        icon: Icons.bar_chart,
                        title: 'Statistics',
                        isSelected: _selectedIndex == 4,
                        onTap: () => setState(() => _selectedIndex = 4),
                      ),
                      _buildNavItem(
                        icon: Icons.emoji_events,
                        title: 'Leaderboard',
                        isSelected: _selectedIndex == 5,
                        onTap: () => setState(() => _selectedIndex = 5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  _buildStudentApprovals(),
                  _buildStaffManagement(),
                  _buildStudentManagement(),
                  _buildLevelManagement(),
                  _buildStatistics(),
                  _buildLeaderboard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String title,
    bool isSelected = false,
    required VoidCallback onTap,
  }) {
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
        onTap: onTap,
      ),
    );
  }

  Widget _buildContent() {
    return Container(
      constraints: const BoxConstraints.expand(),
      child: switch (_selectedIndex) {
        0 => _buildStudentApprovals(),
        1 => _buildStaffManagement(),
        2 => _buildLevelManagement(),
        3 => _buildStatistics(),
        _ => const Center(child: Text('Select a section')),
      },
    );
  }

  Widget _buildStudentApprovals() {
    return Consumer<AdminController>(
      builder: (context, adminController, child) {
        if (adminController.isLoadingStudents) {
          return const Center(child: CircularProgressIndicator());
        }

        return Container(
          constraints: const BoxConstraints.expand(),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student Approvals',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                if (adminController.pendingStudents.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text(
                        'No pending students to approve.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: adminController.pendingStudents.length,
                      itemBuilder: (context, index) {
                        final student = adminController.pendingStudents[index];
                        return _buildStudentApprovalCard(student, adminController);
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStudentApprovalCard(User student, AdminController adminController) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.username ?? student.email,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Phone: ${student.phone}'),
                      Text('Registered: ${_formatDate(student.createdAt)}'),
                      const SizedBox(height: 4),
                      // Student information
                      if (student.enrollmentNo != null || student.class_ != null || student.year != null)
                        Row(
                          children: [
                            if (student.enrollmentNo != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.purple.withOpacity(0.3)),
                                ),
                                child: Text(
                                  'EN: ${student.enrollmentNo}',
                                  style: const TextStyle(
                                    color: Colors.purple,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            if (student.class_ != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                ),
                                child: Text(
                                  'Class: ${student.class_}',
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            if (student.year != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.teal.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.teal.withOpacity(0.3)),
                                ),
                                child: Text(
                                  'Year ${student.year}',
                                  style: const TextStyle(
                                    color: Colors.teal,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                    ],
                  ),
                ),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: CustomButton(
                          text: 'Approve',
                          onPressed: () => _showApprovalDialog(student, adminController),
                          backgroundColor: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: CustomButton(
                          text: 'Decline',
                          onPressed: () => _declineStudent(student, adminController),
                          backgroundColor: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Staff Management Section
  Widget _buildStaffManagement() {
    return Consumer<AdminController>(
      builder: (context, adminController, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Staff Management',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  CustomButton(
                    text: 'Add Staff',
                    onPressed: () => _showAddStaffDialog(adminController),
                    icon: Icons.person_add,
                    width: 120,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Search Bar for Staff
              Container(
                constraints: const BoxConstraints(maxWidth: 600),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _staffSearchController,
                        decoration: const InputDecoration(
                          hintText: 'Search staff by email or role...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Colors.grey),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _staffSearchQuery = value.toLowerCase();
                          });
                        },
                      ),
                    ),
                    if (_staffSearchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        onPressed: () {
                          _staffSearchController.clear();
                          setState(() {
                            _staffSearchQuery = '';
                          });
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              if (adminController.isLoadingStaff)
                const Center(child: CircularProgressIndicator())
              else if (adminController.allStaff.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No staff members found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Click "Add Staff" to create your first staff member',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: adminController.allStaff
                        .where((staff) => 
                            staff.email.toLowerCase().contains(_staffSearchQuery) ||
                            staff.role.toLowerCase().contains(_staffSearchQuery) ||
                            staff.phone.toLowerCase().contains(_staffSearchQuery))
                        .length,
                    itemBuilder: (context, index) {
                      final filteredStaff = adminController.allStaff
                          .where((staff) => 
                              staff.email.toLowerCase().contains(_staffSearchQuery) ||
                              staff.role.toLowerCase().contains(_staffSearchQuery) ||
                              staff.phone.toLowerCase().contains(_staffSearchQuery))
                          .toList();
                      final staff = filteredStaff[index];
                      return _buildStaffCard(staff, adminController);
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStaffCard(User staff, AdminController adminController) {
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
                  backgroundColor: staff.isAdmin ? Colors.purple : Colors.blue,
                  child: Icon(
                    staff.isAdmin ? Icons.admin_panel_settings : Icons.person,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        staff.email,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        staff.isAdmin ? 'Admin' : 'Staff',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Phone: ${staff.phone}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'promote':
                        _showPromoteDialog(staff, adminController);
                        break;
                      case 'reassign_students':
                        _showReassignStudentsDialog(staff, adminController);
                        break;
                      case 'delete':
                        _showDeleteStaffDialog(staff, adminController);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (!staff.isAdmin)
                      const PopupMenuItem(
                        value: 'promote',
                        child: Row(
                          children: [
                            Icon(Icons.admin_panel_settings, size: 20),
                            SizedBox(width: 8),
                            Text('Promote to Admin'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'reassign_students',
                      child: Row(
                        children: [
                          Icon(Icons.swap_horiz, size: 20),
                          SizedBox(width: 8),
                          Text('Reassign Students'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red, size: 20),
                          SizedBox(width: 8),
                          Text('Delete Staff', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                  child: const Icon(Icons.more_vert),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Level Management Section
  Widget _buildLevelManagement() {
    return Consumer<AdminController>(
      builder: (context, adminController, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Level Management',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  CustomButton(
                    text: 'Add Level',
                    onPressed: () => _showAddLevelDialog(adminController),
                    icon: Icons.add,
                    width: 120,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              if (adminController.isLoadingLevels)
                const Center(child: CircularProgressIndicator())
              else
                Expanded(
                  child: adminController.levels.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.quiz_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No levels found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Click "Add Level" to create your first level',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: adminController.levels.length,
                          itemBuilder: (context, index) {
                            final level = adminController.levels[index];
                            return _buildLevelCard(level);
                          },
                        ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLevelCard(Map<String, dynamic> level) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${level['level_number']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        level['title'] ?? 'Untitled Level',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (level['description'] != null)
                        Text(
                          level['description'],
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.quiz, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            '${level['total_questions'] ?? 0} questions',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistics',
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
                  Text('Dashboard statistics will be implemented here'),
                  SizedBox(height: 16),
                  Text('• Total Students'),
                  Text('• Total Staff'),
                  Text('• Total Levels'),
                  Text('• Average Performance'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Dialog and Action Methods
  void _showApprovalDialog(User student, AdminController adminController) {
    String? selectedStaffId;
    User? selectedStaff;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.person_add, color: Colors.blue[700], size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Approve Student',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Assign ${student.email} to a staff member',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              
              // Staff selection
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select Staff Member',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      Expanded(
                        child: adminController.allStaff.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.people_outline, size: 48, color: Colors.grey),
                                    SizedBox(height: 16),
                                    Text(
                                      'No staff members available',
                                      style: TextStyle(color: Colors.grey, fontSize: 16),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: adminController.allStaff.length,
                                itemBuilder: (context, index) {
                                  final staff = adminController.allStaff[index];
                                  final isSelected = selectedStaffId == staff.id;
                                  
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    elevation: isSelected ? 4 : 1,
                                    color: isSelected ? Colors.blue[50] : Colors.white,
                                    child: InkWell(
                                      onTap: () {
                                        setState(() {
                                          selectedStaffId = staff.id;
                                          selectedStaff = staff;
                                        });
                                      },
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 24,
                                              height: 24,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: isSelected ? Colors.blue : Colors.grey[300],
                                                border: Border.all(
                                                  color: isSelected ? Colors.blue : Colors.grey[400]!,
                                                  width: 2,
                                                ),
                                              ),
                                              child: isSelected
                                                  ? const Icon(
                                                      Icons.check,
                                                      color: Colors.white,
                                                      size: 14,
                                                    )
                                                  : null,
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    staff.email,
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Row(
                                                    children: [
                                                      Icon(
                                                        staff.isAdmin 
                                                            ? Icons.admin_panel_settings 
                                                            : Icons.person,
                                                        size: 16,
                                                        color: staff.isAdmin ? Colors.purple : Colors.blue,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        staff.isAdmin ? 'Admin' : 'Staff',
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.grey[600],
                                                        ),
                                                      ),
                                                      const SizedBox(width: 16),
                                                      Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                                                      const SizedBox(width: 4),
                                                      Text(
                                                        staff.phone,
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.grey[600],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Action buttons
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: 'Approve',
                        onPressed: selectedStaffId == null ? null : () async {
                          try {
                            await adminController.approveStudent(
                              studentId: student.id,
                              assignedStaffId: selectedStaffId!,
                            );
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Student ${student.email} approved successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error approving student: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _declineStudent(User student, AdminController adminController) async {
    await adminController.declineStudent(student.id);
  }

  void _showAddStaffDialog(AdminController adminController) {
    final _formKey = GlobalKey<FormState>();
    final _emailController = TextEditingController();
    final _phoneController = TextEditingController();
    final _passwordController = TextEditingController();
    bool _obscurePassword = true;
    bool _isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Staff Member'),
          content: Container(
            constraints: const BoxConstraints(
              minWidth: 400,
              maxWidth: 500,
              minHeight: 300,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomTextField(
                    controller: _emailController,
                    labelText: 'Email',
                    prefixIcon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter email';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _phoneController,
                    labelText: 'Phone Number',
                    prefixIcon: Icons.phone,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _passwordController,
                    labelText: 'Password',
                    prefixIcon: Icons.lock,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Staff members can view and manage their assigned students.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            CustomButton(
              text: _isLoading ? 'Adding...' : 'Add Staff',
              onPressed: _isLoading ? null : () async {
                if (!_formKey.currentState!.validate()) return;

                setState(() {
                  _isLoading = true;
                });

                try {
                  final success = await adminController.addStaffMember(
                    email: _emailController.text.trim(),
                    phone: _phoneController.text.trim(),
                    password: _passwordController.text,
                  );

                  if (success && mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Staff member ${_emailController.text.trim()} added successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(adminController.error ?? 'Failed to add staff member'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                }
              },
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }

  void _showPromoteDialog(User staff, AdminController adminController) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Promote to Admin'),
        content: Text('Are you sure you want to promote ${staff.email} to admin? This will give them full administrative privileges.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Promote',
            onPressed: () => Navigator.pop(context, true),
            backgroundColor: Colors.purple,
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await adminController.promoteStaffToAdmin(staff.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${staff.email} promoted to admin successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(adminController.error ?? 'Failed to promote staff member'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showReassignStudentsDialog(User staff, AdminController adminController) async {
    final _formKey = GlobalKey<FormState>();
    String? selectedStaffId;
    User? selectedStaff;
    bool _isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Reassign Students'),
          content: Container(
            constraints: const BoxConstraints(
              minWidth: 400,
              maxWidth: 500,
              minHeight: 200,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Select new staff member for students currently assigned to ${staff.email}:',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  // Staff selection dropdown
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: selectedStaffId,
                      decoration: const InputDecoration(
                        labelText: 'Select New Staff Member',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: adminController.allStaff
                          .where((s) => s.id != staff.id) // Exclude current staff
                          .map((s) => DropdownMenuItem(
                                value: s.id,
                                child: Text('${s.email} (${s.isAdmin ? 'Admin' : 'Staff'})'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedStaffId = value;
                          selectedStaff = adminController.allStaff.firstWhere((s) => s.id == value!);
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a staff member';
                        }
                        return null;
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.orange[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This action will reassign all students currently assigned to ${staff.email} to the selected staff member.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            CustomButton(
              text: _isLoading ? 'Reassigning...' : 'Reassign Students',
              onPressed: _isLoading ? null : () async {
                if (!_formKey.currentState!.validate()) return;

                setState(() {
                  _isLoading = true;
                });

                try {
                  final success = await adminController.reassignStudents(
                    currentStaffId: staff.id,
                    newStaffId: selectedStaffId!,
                  );

                  if (success && mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Students re-assigned successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(adminController.error ?? 'Failed to reassign students'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                }
              },
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteStaffDialog(User staff, AdminController adminController) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Staff Member'),
        content: Text('Are you sure you want to delete ${staff.email}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          CustomButton(
            text: 'Delete',
            onPressed: () => Navigator.pop(context, true),
            backgroundColor: Colors.red,
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await adminController.deleteStaffMember(staff.id);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Staff member ${staff.email} deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(adminController.error ?? 'Failed to delete staff member'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddLevelDialog(AdminController adminController) {
    final _formKey = GlobalKey<FormState>();
    final _titleController = TextEditingController();
    final _descriptionController = TextEditingController();
    final _levelNumberController = TextEditingController();
    final List<Map<String, dynamic>> _questions = [];
    bool _isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add New Level with Questions'),
          content: Container(
            constraints: const BoxConstraints(
              minWidth: 600,
              maxWidth: 800,
              minHeight: 400,
              maxHeight: 600,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Level Details Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Level Details',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _titleController,
                                labelText: 'Level Title',
                                prefixIcon: Icons.title,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a title for the level';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 120,
                              child: CustomTextField(
                                controller: _levelNumberController,
                                labelText: 'Level Number',
                                prefixIcon: Icons.numbers,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Required';
                                  }
                                  if (int.tryParse(value) == null) {
                                    return 'Invalid';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        CustomTextField(
                          controller: _descriptionController,
                          labelText: 'Level Description (Optional)',
                          prefixIcon: Icons.description,
                          keyboardType: TextInputType.multiline,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Questions Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Questions (${_questions.length})',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700],
                                fontSize: 16,
                              ),
                            ),
                            CustomButton(
                              text: 'Add Question',
                              onPressed: () => _showAddQuestionDialog(setState, _questions),
                              icon: Icons.add,
                              width: 120,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Questions List
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _questions.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No questions added yet. Click "Add Question" to get started.',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: _questions.length,
                                  itemBuilder: (context, index) {
                                    final question = _questions[index];
                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.green,
                                        child: Text(
                                          '${index + 1}',
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      title: Text(
                                        question['question'],
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                        '${question['options'].length} options • Correct: ${question['correct_answer'] + 1}',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () {
                                          setState(() {
                                            _questions.removeAt(index);
                                          });
                                        },
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            CustomButton(
              text: _isLoading ? 'Creating...' : 'Create Level',
              onPressed: _isLoading ? null : () async {
                if (!_formKey.currentState!.validate()) return;
                if (_questions.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please add at least one question'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                setState(() {
                  _isLoading = true;
                });

                try {
                  final success = await adminController.addLevelWithQuestions(
                    title: _titleController.text.trim(),
                    description: _descriptionController.text.trim(),
                    levelNumber: int.parse(_levelNumberController.text.trim()),
                    questions: _questions,
                  );

                  if (success && mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Level "${_titleController.text.trim()}" created with ${_questions.length} questions!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(adminController.error ?? 'Failed to create level'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                }
              },
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }

  void _showAddQuestionDialog(StateSetter setState, List<Map<String, dynamic>> questions) {
    final _questionController = TextEditingController();
    final List<TextEditingController> _optionControllers = [
      TextEditingController(),
      TextEditingController(),
      TextEditingController(),
      TextEditingController(),
    ];
    int _correctAnswer = 0;
    final _explanationController = TextEditingController();
    bool _isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Question'),
          content: Container(
            constraints: const BoxConstraints(
              minWidth: 500,
              maxWidth: 600,
              minHeight: 400,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomTextField(
                  controller: _questionController,
                  labelText: 'Question',
                  prefixIcon: Icons.quiz,
                  keyboardType: TextInputType.multiline,
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a question';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'Options',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                
                // Options
                ...List.generate(4, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Radio<int>(
                          value: index,
                          groupValue: _correctAnswer,
                          onChanged: (value) {
                            setDialogState(() {
                              _correctAnswer = value!;
                            });
                          },
                        ),
                        Expanded(
                          child: CustomTextField(
                            controller: _optionControllers[index],
                            labelText: 'Option ${index + 1}',
                            prefixIcon: Icons.radio_button_checked,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                
                const SizedBox(height: 16),
                
                CustomTextField(
                  controller: _explanationController,
                  labelText: 'Explanation (Optional)',
                  prefixIcon: Icons.lightbulb,
                  keyboardType: TextInputType.multiline,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            CustomButton(
              text: _isLoading ? 'Adding...' : 'Add Question',
              onPressed: _isLoading ? null : () {
                // Validate
                if (_questionController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a question')),
                  );
                  return;
                }
                
                for (int i = 0; i < 4; i++) {
                  if (_optionControllers[i].text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please enter option ${i + 1}')),
                    );
                    return;
                  }
                }
                
                // Add question
                final question = {
                  'question': _questionController.text.trim(),
                  'options': _optionControllers.map((c) => c.text.trim()).toList(),
                  'correct_answer': _correctAnswer,
                  'explanation': _explanationController.text.trim(),
                };
                
                setState(() {
                  questions.add(question);
                });
                
                Navigator.pop(context);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Question added successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }

  void _editLevel(dynamic level) {
    // Implementation for editing level
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit level functionality to be implemented')),
    );
  }

  void _addMCQsToLevel(dynamic level) {
    // Implementation for adding MCQs
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add MCQs functionality to be implemented')),
    );
  }

  // Student Management Section
  Widget _buildStudentManagement() {
    return Consumer<AdminController>(
      builder: (context, adminController, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Student Management',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Search Bar for Students
              Container(
                constraints: const BoxConstraints(maxWidth: 600),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search, color: Colors.grey[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _studentSearchController,
                        decoration: const InputDecoration(
                          hintText: 'Search students by email, status, phone, or assigned staff...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Colors.grey),
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 8),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _studentSearchQuery = value.toLowerCase();
                          });
                        },
                      ),
                    ),
                    if (_studentSearchQuery.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        onPressed: () {
                          _studentSearchController.clear();
                          setState(() {
                            _studentSearchQuery = '';
                          });
                        },
                      ),
                  ],
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
                child: FutureBuilder<List<User>>(
                  future: _loadAllStudents(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Row(
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 16),
                          Text('Loading statistics...'),
                        ],
                      );
                    }
                    
                    final students = snapshot.data ?? [];
                    final totalStudents = students.length;
                    final assignedStudents = students.where((s) => s.assignedStaffId != null).length;
                    final unassignedStudents = totalStudents - assignedStudents;
                    final activeStudents = students.where((s) => s.status == 'active').length;
                    final pendingStudents = students.where((s) => s.status == 'pending').length;
                    
                    return Row(
                      children: [
                        _buildStatCard('Total Students', totalStudents.toString(), Icons.people, Colors.blue),
                        const SizedBox(width: 16),
                        _buildStatCard('Assigned', assignedStudents.toString(), Icons.check_circle, Colors.green),
                        const SizedBox(width: 16),
                        _buildStatCard('Unassigned', unassignedStudents.toString(), Icons.warning, Colors.orange),
                        const SizedBox(width: 16),
                        _buildStatCard('Active', activeStudents.toString(), Icons.verified_user, Colors.green),
                        const SizedBox(width: 16),
                        _buildStatCard('Pending', pendingStudents.toString(), Icons.pending, Colors.orange),
                      ],
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 16),
              
              if (adminController.isLoading)
                const Center(child: CircularProgressIndicator())
              else
                Expanded(
                  child: FutureBuilder<List<User>>(
                    future: _loadAllStudents(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error loading students: ${snapshot.error}'),
                        );
                      }
                      
                      final students = snapshot.data ?? [];
                      
                      if (students.isEmpty) {
                        return const Center(
                          child: Text('No students found'),
                        );
                      }
                      
                      // Filter students based on search query
                      final filteredStudents = students.where((student) {
                        final searchQuery = _studentSearchQuery.toLowerCase();
                        
                        // Check student email
                        if (student.email.toLowerCase().contains(searchQuery)) return true;
                        
                        // Check student status
                        if (student.status.toLowerCase().contains(searchQuery)) return true;
                        
                        // Check student phone
                        if (student.phone.toLowerCase().contains(searchQuery)) return true;
                        
                        // Check assigned staff member
                        if (student.assignedStaffId != null) {
                          final assignedStaff = adminController.allStaff
                              .where((staff) => staff.id == student.assignedStaffId)
                              .firstOrNull;
                          if (assignedStaff != null) {
                            if (assignedStaff.email.toLowerCase().contains(searchQuery)) return true;
                            if (assignedStaff.role.toLowerCase().contains(searchQuery)) return true;
                          }
                        }
                        
                        return false;
                      }).toList();
                      
                      if (filteredStudents.isEmpty) {
                        return const Center(
                          child: Text('No students match your search'),
                        );
                      }
                      
                      return ListView.builder(
                        itemCount: filteredStudents.length,
                        itemBuilder: (context, index) {
                          final student = filteredStudents[index];
                          return _buildStudentCard(student, adminController);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<List<User>> _loadAllStudents() async {
    try {
      final studentsData = await SupabaseService.getAllStudents();
      return studentsData;
    } catch (e) {
      print('Error loading students: $e');
      return [];
    }
  }

  Widget _buildStudentCard(User student, AdminController adminController) {
    // Find the assigned staff member
    User? assignedStaff;
    if (student.assignedStaffId != null) {
      assignedStaff = adminController.allStaff
          .where((staff) => staff.id == student.assignedStaffId)
          .firstOrNull;
    }

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
                  backgroundColor: _getStatusColor(student.status),
                  child: Icon(Icons.person, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.username ?? student.email,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getStatusColor(student.status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _getStatusColor(student.status)),
                            ),
                            child: Text(
                              student.status.toUpperCase(),
                              style: TextStyle(
                                color: _getStatusColor(student.status),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Phone: ${student.phone}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Student information row
                      if (student.enrollmentNo != null || student.class_ != null || student.year != null)
                        Row(
                          children: [
                            if (student.enrollmentNo != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.purple.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.purple.withOpacity(0.3)),
                                ),
                                child: Text(
                                  'EN: ${student.enrollmentNo}',
                                  style: const TextStyle(
                                    color: Colors.purple,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            if (student.class_ != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                                ),
                                child: Text(
                                  'Class: ${student.class_}',
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            if (student.year != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.teal.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.teal.withOpacity(0.3)),
                                ),
                                child: Text(
                                  'Year ${student.year}',
                                  style: const TextStyle(
                                    color: Colors.teal,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      const SizedBox(height: 4),
                      if (assignedStaff != null)
                        Row(
                          children: [
                            Icon(Icons.person_outline, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              'Assigned to: ${assignedStaff.email}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: assignedStaff.isAdmin ? Colors.purple.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                assignedStaff.isAdmin ? 'Admin' : 'Staff',
                                style: TextStyle(
                                  color: assignedStaff.isAdmin ? Colors.purple : Colors.blue,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Icon(Icons.warning, size: 16, color: Colors.orange[600]),
                            const SizedBox(width: 4),
                            Text(
                              'No staff assigned',
                              style: TextStyle(
                                color: Colors.orange[600],
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'reassign':
                        _showReassignStudentDialog(student, adminController);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'reassign',
                      child: Row(
                        children: [
                          Icon(Icons.swap_horiz, size: 20),
                          SizedBox(width: 8),
                          Text('Reassign to Different Staff'),
                        ],
                      ),
                    ),
                  ],
                  child: const Icon(Icons.more_vert),
                ),
              ],
            ),
          ],
        ),
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

  void _showReassignStudentDialog(User student, AdminController adminController) async {
    final _formKey = GlobalKey<FormState>();
    String? selectedStaffId;
    User? selectedStaff;
    bool _isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Reassign Student'),
          content: Container(
            constraints: const BoxConstraints(
              minWidth: 400,
              maxWidth: 500,
              minHeight: 200,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Select new staff member for ${student.email}:',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  
                  // Staff selection dropdown
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: selectedStaffId,
                      decoration: const InputDecoration(
                        labelText: 'Select New Staff Member',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: adminController.allStaff
                          .where((s) => s.id != student.assignedStaffId) // Exclude current staff
                          .map((s) => DropdownMenuItem(
                                value: s.id,
                                child: Text('${s.email} (${s.isAdmin ? 'Admin' : 'Staff'})'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedStaffId = value;
                          selectedStaff = adminController.allStaff.firstWhere((s) => s.id == value!);
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a staff member';
                        }
                        return null;
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.orange[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This action will reassign ${student.email} to the selected staff member.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            CustomButton(
              text: _isLoading ? 'Reassigning...' : 'Reassign Student',
              onPressed: _isLoading ? null : () async {
                if (!_formKey.currentState!.validate()) return;

                setState(() {
                  _isLoading = true;
                });

                try {
                  final success = await adminController.reassignSpecificStudent(
                    studentId: student.id,
                    newStaffId: selectedStaffId!,
                  );

                  if (success && mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Student ${student.email} re-assigned successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(adminController.error ?? 'Failed to reassign student'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } finally {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                }
              },
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildLeaderboard() {
    return Consumer<LeaderboardController>(
      builder: (context, leaderboardController, child) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
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
              
              // Global Leaderboard
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Global Rankings',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      if (leaderboardController.isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (leaderboardController.globalLeaderboard.isEmpty)
                        const Center(
                          child: Text('No leaderboard data available yet.'),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: leaderboardController.globalLeaderboard.length,
                          itemBuilder: (context, index) {
                            final entry = leaderboardController.globalLeaderboard[index];
                            final rank = index + 1;
                            
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
                  'Level ${entry.levelNumber}: ${entry.levelTitle ?? 'Unknown Level'}',
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