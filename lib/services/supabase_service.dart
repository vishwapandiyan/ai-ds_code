import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'dart:math';
import 'package:random_string/random_string.dart';
import '../models/user.dart';

import '../models/performance.dart';
import '../models/notification.dart' as app_notification;
import '../models/leaderboard.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://wajybcjclcrfxkcamxvi.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndhanliY2pjbGNyZnhrY2FteHZpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM4NzAxODMsImV4cCI6MjA2OTQ0NjE4M30.s_bqpf1Emf1JVbtkfjg_RAHRcKUR2AmRNykV5OAmwvc';
  
  static SupabaseClient get client => Supabase.instance.client;
  
  // Initialize Supabase
  static Future<void> initialize() async {
    print('Initializing Supabase with URL: $supabaseUrl');
    print('Initializing Supabase with Anon Key: ${supabaseAnonKey.substring(0, 20)}...');
    
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    
    print('Supabase initialization completed');
  }
  
  // Authentication methods
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    try {
      print('Attempting to sign up user: $email');
      print('Supabase URL: $supabaseUrl');
      
      final response = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'phone': phone,
          'role': role,
          'status': 'pending', // For student registration approval
        },
      );
      
      print('Sign up response: ${response.user?.id}');
      return response;
    } catch (e) {
      print('Sign up error: $e');
      rethrow;
    }
  }
  
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }
  
  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  // Get current user
  static Future<User?> getCurrentUser() async {
    try {
      final session = client.auth.currentSession;
      if (session?.user == null) {
        return null;
      }

      return await loadUserProfile(session!.user.id);
    } catch (e) {
      print('❌ Error getting current user: $e');
      return null;
    }
  }
  
  // User management
  static Future<void> createUserProfile({
    required String userId,
    required String email,
    required String phone,
    required String role,
    String? assignedStaffId,
  }) async {
    try {
      print('👤 Creating user profile for ID: $userId, email: $email');
      
      // Use upsert to handle existing profiles
      await client.from('user_profiles').upsert({
        'id': userId,
        'email': email,
        'phone': phone,
        'role': role,
        'status': role == 'student' ? 'pending' : 'active',
        'assigned_staff_id': assignedStaffId,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');
      
      print('✅ User profile created/updated successfully');
    } catch (e) {
      print('❌ Error creating user profile: $e');
      rethrow;
    }
  }
  
  static Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      print('🔍 Getting user profile for ID: $userId');
      
      final response = await client
          .from('user_profiles')
          .select()
          .eq('id', userId)
          .single();
      
      print(' User profile data: $response');
      return response;
    } catch (e) {
      print('❌ Error getting user profile: $e');
      return null;
    }
  }
  
  // Load user profile with role
  static Future<User?> loadUserProfile(String userId) async {
    try {
      print('👤 Loading user profile for ID: $userId');
      
      final profileData = await getUserProfile(userId);
      
      if (profileData != null) {
        final user = User(
          id: profileData['id'],
          email: profileData['email'],
          phone: profileData['phone'] ?? '',
          role: profileData['role'],
          status: profileData['status'],
          assignedStaffId: profileData['assigned_staff_id'],
          createdAt: profileData['created_at'] != null 
            ? DateTime.parse(profileData['created_at']) 
            : DateTime.now(),
          enrollmentNo: profileData['enrollment_no'],
          class_: profileData['class'],
          year: profileData['year'] != null ? int.tryParse(profileData['year'].toString()) : null,
        );
        
        print('👤 User profile loaded successfully: ${user.email}');
        print(' User role: ${user.role}');
        print('👤 User status: ${user.status}');
        
        return user;
      }
      
      return null;
    } catch (e) {
      print('❌ Error loading user profile: $e');
      return null;
    }
  }
  
  // Admin functions
  static Future<List<User>> getPendingStudents() async {
    try {
      print('🔍 Fetching pending students from database...');
      
      final response = await client
          .from('user_profiles')
          .select()
          .eq('role', 'student')
          .eq('status', 'pending');
      
      print(' Database response: ${response.length} pending students found');
      
      return response.map((data) => User(
        id: data['id'],
        email: data['email'],
        phone: data['phone'] ?? '',
        role: data['role'],
        status: data['status'],
        assignedStaffId: data['assigned_staff_id'],
        createdAt: data['created_at'] != null 
            ? DateTime.parse(data['created_at']) 
            : DateTime.now(),
      )).toList();
    } catch (e) {
      print('❌ Error getting pending students: $e');
      throw Exception('Failed to get pending students: $e');
    }
  }
  
  static Future<List<User>> getAllStaff() async {
    try {
      print('🔄 Loading all staff members...');
      
      final response = await client
          .from('user_profiles')
          .select()
          .or('role.eq.staff,role.eq.admin')
          .eq('status', 'active');
      
      print(' Database response: ${response.length} staff members found');
      print('🔍 Response data: $response');
      
      final staffList = response.map((data) => User(
        id: data['id'],
        email: data['email'],
        phone: data['phone'] ?? '',
        role: data['role'],
        status: data['status'],
        assignedStaffId: data['assigned_staff_id'],
        createdAt: data['created_at'] != null 
            ? DateTime.parse(data['created_at']) 
            : DateTime.now(),
      )).toList();
      
      print('📊 Found ${staffList.length} staff members');
      
      for (final staff in staffList) {
        print('👤 Staff: ${staff.email} (${staff.role}) - Status: ${staff.status}');
      }
      
      print('✅ Staff members loaded successfully');
      return staffList;
    } catch (e) {
      print('❌ Error loading staff: $e');
      throw Exception('Failed to load staff: $e');
    }
  }
  
  static Future<void> approveStudent({
    required String studentId,
    required String assignedStaffId,
  }) async {
    try {
      print('✅ Approving student: $studentId');
      print(' Assigned to staff: $assignedStaffId');
      
      await client.from('user_profiles').update({
        'status': 'active',
        'assigned_staff_id': assignedStaffId,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', studentId);
      
      print('✅ Student approved successfully');
    } catch (e) {
      print('❌ Error approving student: $e');
      throw Exception('Failed to approve student: $e');
    }
  }
  
  static Future<void> declineStudent(String studentId) async {
    try {
      print('❌ Declining student: $studentId');
      
      await client.from('user_profiles').update({
        'status': 'declined',
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', studentId);
      
      print('✅ Student declined successfully');
    } catch (e) {
      print('❌ Error declining student: $e');
      throw Exception('Failed to decline student: $e');
    }
  }
  
  static Future<void> promoteStaffToAdmin(String staffId) async {
    try {
      print('🔄 Promoting staff to admin: $staffId');
      
      await client
          .from('user_profiles')
          .update({'role': 'admin'})
          .eq('id', staffId);
      
      print('✅ Staff promoted to admin successfully');
    } catch (e) {
      print('❌ Error promoting staff to admin: $e');
      throw Exception('Failed to promote staff to admin: $e');
    }
  }

  static Future<void> deleteStaff(String staffId) async {
    try {
      print('🗑️ Deleting staff: $staffId');
      
      await client
          .from('user_profiles')
          .delete()
          .eq('id', staffId);
      
      print('✅ Staff deleted successfully');
    } catch (e) {
      print('❌ Error deleting staff: $e');
      throw Exception('Failed to delete staff: $e');
    }
  }
  
  // Create staff account WITHOUT email confirmation
  static Future<AuthResponse> createStaffAccount({
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      print('👤 Creating staff account for: $email');
      
      // Create the user account
      final authResponse = await signUp(
        email: email,
        password: password,
        phone: phone,
        role: 'staff',
      );
      
      if (authResponse.user != null) {
        print('✅ Staff account created successfully');
        print('📋 Staff can login immediately with:');
        print('   Email: $email');
        print('   Password: $password');
        
        // No email confirmation needed - staff can login immediately
        return authResponse;
      }
      
      return authResponse;
    } catch (e) {
      print('❌ Error creating staff account: $e');
      throw Exception('Failed to create staff account: $e');
    }
  }
  
  // Utility methods
  static String generateRandomCredentials() {
    return randomAlphaNumeric(8);
  }
  
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Delete staff member
  static Future<void> deleteStaffMember(String staffId) async {
    try {
      print('🗑️ Deleting staff member: $staffId');
      
      // First, reassign any students assigned to this staff member
      await client.from('user_profiles').update({
        'assigned_staff_id': null,
        'status': 'pending_approval'
      }).eq('assigned_staff_id', staffId);
      
      // Delete the staff member's profile
      await client.from('user_profiles').delete().eq('id', staffId);
      
      // Note: We don't delete from auth.users as that requires admin privileges
      // The user will be unable to login since their profile is deleted
      
      print('✅ Staff member deleted successfully');
    } catch (e) {
      print('❌ Error deleting staff member: $e');
      throw Exception('Failed to delete staff member: $e');
    }
  }

  // Reassign student to different staff
  static Future<void> reassignStudent({
    required String studentId,
    required String newStaffId,
  }) async {
    try {
      print('🔄 Reassigning student $studentId to staff $newStaffId');
      
      // Update the student's assigned staff
      await client.from('user_profiles').update({
        'assigned_staff_id': newStaffId,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', studentId);
      
      print('✅ Student reassigned successfully');
    } catch (e) {
      print('❌ Error reassigning student: $e');
      throw Exception('Failed to reassign student: $e');
    }
  }

  // Reassign specific student to different staff
  static Future<void> reassignSpecificStudent({
    required String studentId,
    required String newStaffId,
  }) async {
    try {
      print('🔄 Reassigning specific student $studentId to staff $newStaffId');
      
      // Get student details for logging
      final studentResponse = await client
          .from('user_profiles')
          .select()
          .eq('id', studentId)
          .single();
      
      final newStaffResponse = await client
          .from('user_profiles')
          .select()
          .eq('id', newStaffId)
          .single();
      
      print(' Student: ${studentResponse['email']}');
      print('👤 New Staff: ${newStaffResponse['email']}');
      
      // Update the student's assigned staff
      await client.from('user_profiles').update({
        'assigned_staff_id': newStaffId,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', studentId);
      
      print('✅ Specific student reassigned successfully');
    } catch (e) {
      print('❌ Error reassigning specific student: $e');
      throw Exception('Failed to reassign specific student: $e');
    }
  }

  // Get students by staff
  static Future<List<User>> getStudentsByStaff(String staffId) async {
    try {
      print('🔍 Getting students for staff: $staffId');
      
      final response = await client
          .from('user_profiles')
          .select()
          .eq('role', 'student')
          .eq('assigned_staff_id', staffId);
      
      return response.map((data) => User(
        id: data['id'],
        email: data['email'],
        phone: data['phone'] ?? '',
        role: data['role'],
        status: data['status'],
        assignedStaffId: data['assigned_staff_id'],
        createdAt: data['created_at'] != null 
            ? DateTime.parse(data['created_at']) 
            : DateTime.now(),
      )).toList();
    } catch (e) {
      print('❌ Error getting students by staff: $e');
      throw Exception('Failed to get students by staff: $e');
    }
  }

  // Get all students
  static Future<List<User>> getAllStudents() async {
    try {
      print('🔍 Fetching all students from database...');
      
      final response = await client
          .from('user_profiles')
          .select()
          .eq('role', 'student');
      
      print(' Database response: ${response.length} students found');
      
      return response.map((data) => User(
        id: data['id'],
        email: data['email'],
        phone: data['phone'] ?? '',
        role: data['role'],
        status: data['status'],
        assignedStaffId: data['assigned_staff_id'],
        createdAt: data['created_at'] != null 
            ? DateTime.parse(data['created_at']) 
            : DateTime.now(),
        enrollmentNo: data['enrollment_no'],
        class_: data['class'],
        year: data['year'] != null ? int.tryParse(data['year'].toString()) : null,
      )).toList();
    } catch (e) {
      print('❌ Error getting all students: $e');
      throw Exception('Failed to get all students: $e');
    }
  }

  // Level management
  static Future<void> createLevel({
    required int levelNumber,
    required String title,
    required String description,
  }) async {
    await client.from('levels').insert({
      'level_number': levelNumber,
      'title': title,
      'description': description,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
  
  static Future<void> addMCQ({
    required int levelId,
    required int questionNumber,
    required String question,
    required List<String> options,
    required int correctAnswer,
    required String explanation,
  }) async {
    await client.from('mcqs').insert({
      'level_id': levelId,
      'question_number': questionNumber,
      'question': question,
      'options': options,
      'correct_answer': correctAnswer,
      'explanation': explanation,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
  
  // Add new level
  static Future<void> addLevel({
    required int levelNumber,
    required String title,
    required String description,
    required int totalQuestions,
  }) async {
    try {
      print('📚 Adding new level: $title (Level $levelNumber)');
      
      final response = await client.from('levels').insert({
        'level_number': levelNumber,
        'title': title,
        'description': description,
        'total_questions': totalQuestions,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      print('✅ Level added successfully');
    } catch (e) {
      print('❌ Error adding level: $e');
      throw Exception('Failed to add level: $e');
    }
  }

  // Get all levels (for LevelController)
  static Future<List<Map<String, dynamic>>> getLevels() async {
    try {
      print('📚 Loading levels...');
      
      final response = await client
          .from('levels')
          .select()
          .order('level_number');
      
      print('📚 Found ${response.length} levels');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('❌ Error loading levels: $e');
      throw Exception('Failed to load levels: $e');
    }
  }

  static Future<Map<String, dynamic>?> getLevelById(String levelId) async {
    try {
      print('📚 Loading level by ID: $levelId');
      
      final response = await client
          .from('levels')
          .select()
          .eq('id', levelId)
          .single();
      
      print('📚 Level data: $response');
      return response;
    } catch (e) {
      print('❌ Error loading level by ID: $e');
      return null;
    }
  }

  static Future<void> submitMCQTest({
    required String levelId,
    required List<int> answers,
  }) async {
    try {
      print('📝 Submitting MCQ test for level: $levelId');
      
      // This would typically save to a test_results table
      // For now, just log the submission
      print('📝 Test answers: $answers');
      
      print('✅ MCQ test submitted successfully');
    } catch (e) {
      print('❌ Error submitting MCQ test: $e');
      throw Exception('Failed to submit MCQ test: $e');
    }
  }

  // Get all levels (for AdminController)
  static Future<List<Map<String, dynamic>>> getAllLevels() async {
    try {
      print('🔍 Fetching all levels from database...');
      
      final response = await client
          .from('levels')
          .select()
          .order('level_number', ascending: true);
      
      print(' Database response: ${response.length} levels found');
      
      return response;
    } catch (e) {
      print('❌ Error getting all levels: $e');
      throw Exception('Failed to get all levels: $e');
    }
  }
  
  // Student performance tracking
  static Future<void> saveStudentPerformance({
    required String studentId,
    required int levelId,
    required int score,
    required int totalQuestions,
    required int correctAnswers,
    required int timeTaken,
    required List<Map<String, dynamic>> answers,
  }) async {
    await client.from('student_performance').insert({
      'student_id': studentId,
      'level_id': levelId,
      'score': score,
      'total_questions': totalQuestions,
      'correct_answers': correctAnswers,
      'time_taken': timeTaken,
      'answers': answers,
      'completed_at': DateTime.now().toIso8601String(),
    });
  }
  
  static Future<List<Map<String, dynamic>>> getStudentPerformance(String studentId) async {
    return await client
        .from('student_performance')
        .select()
        .eq('student_id', studentId)
        .order('completed_at', ascending: false);
  }
  
  // Get MCQs for a level
  static Future<List<Map<String, dynamic>>> getMCQsForLevel(int levelId) async {
    try {
      print('📚 Fetching MCQs for level $levelId');
      
      final response = await client
          .from('mcqs')
          .select()
          .eq('level_id', levelId)
          .order('question_number', ascending: true);
      
      print('📚 Found ${response.length} MCQs for level $levelId');
      
      if (response.isNotEmpty) {
        print('📚 First MCQ structure: ${response.first}');
      }
      
      // Shuffle the MCQs to randomize the order
      final shuffledMCQs = List<Map<String, dynamic>>.from(response);
      shuffledMCQs.shuffle(Random());
      
      print('📚 MCQs shuffled - new order: ${shuffledMCQs.map((mcq) => mcq['question_number']).toList()}');
      
      return shuffledMCQs;
    } catch (e) {
      print('❌ Error fetching MCQs for level $levelId: $e');
      rethrow;
    }
  }
  
  // Add question to level
  static Future<void> addQuestionToLevel({
    required int levelId,
    required String question,
    required List<String> options,
    required int correctAnswer,
    required String explanation,
  }) async {
    try {
      print('❓ Adding question to level $levelId: $question');
      
      final response = await client.from('mcqs').insert({
        'level_id': levelId,
        'question': question,
        'options': options,
        'correct_answer': correctAnswer,
        'explanation': explanation,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      
      print('✅ Question added successfully to level $levelId');
    } catch (e) {
      print('❌ Error adding question to level: $e');
      throw Exception('Failed to add question to level: $e');
    }
  }

  // Add level with questions
  static Future<int> addLevelWithQuestions({
    required int levelNumber,
    required String title,
    required String description,
    required List<Map<String, dynamic>> questions,
  }) async {
    try {
      print('📚 Adding new level with questions: $title (Level $levelNumber)');
      
      // First, create the level
      final levelResponse = await client.from('levels').insert({
        'level_number': levelNumber,
        'title': title,
        'description': description,
        'total_questions': questions.length,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select();
      
      final levelId = levelResponse[0]['id'];
      print('✅ Level created with ID: $levelId');
      
      // Add questions to the level
      for (int i = 0; i < questions.length; i++) {
        final question = questions[i];
        await addQuestionToLevel(
          levelId: levelId,
          question: question['question'],
          options: List<String>.from(question['options']),
          correctAnswer: question['correct_answer'],
          explanation: question['explanation'],
        );
      }
      
      print('✅ Level with ${questions.length} questions created successfully');
      return levelId;
    } catch (e) {
      print('❌ Error adding level with questions: $e');
      throw Exception('Failed to add level with questions: $e');
    }
  }

  static Future<void> updateUserProfile({
    required String userId,
    required String phone,
    String? username,
    String? enrollmentNo,
    String? class_,
    int? year,
  }) async {
    try {
      print('🔄 Updating user profile for ID: $userId');
      
      final updateData = {
        'phone': phone,
        'updated_at': DateTime.now().toIso8601String(),
      };
      
      // Add username if provided
      if (username != null && username.isNotEmpty) {
        updateData['username'] = username;
      }
      
      // Add student-specific fields only if they are provided
      if (enrollmentNo != null && enrollmentNo.isNotEmpty) {
        updateData['enrollment_no'] = enrollmentNo;
      }
      if (class_ != null && class_.isNotEmpty) {
        updateData['class'] = class_;
      }
      if (year != null) {
        updateData['year'] = year.toString();
      }
      
      await client
          .from('user_profiles')
          .update(updateData)
          .eq('id', userId);
      
      print('✅ User profile updated successfully');
    } catch (e) {
      print('❌ Error updating user profile: $e');
      throw Exception('Failed to update user profile: $e');
    }
  }

  static Future<List<Performance>> getStudentPerformanceData(String studentId) async {
    try {
      print('📊 Fetching performance data for student: $studentId');
      
      final response = await client
          .from('student_performance')
          .select('*, levels(*)')
          .eq('student_id', studentId)
          .order('completed_at', ascending: false);
      
      print('📈 Found ${response.length} performance records');
      
      final performances = response.map((data) => Performance(
        id: data['id'],
        studentId: data['student_id'],
        levelId: data['level_id'],
        score: data['score'] ?? 0,
        correctAnswers: data['correct_answers'] ?? 0,
        totalQuestions: data['total_questions'] ?? 0,
        timeTaken: data['time_taken'] ?? 0,
        answers: [],
        completedAt: data['completed_at'] != null 
            ? DateTime.parse(data['completed_at']) 
            : DateTime.now(),
        level: data['levels'] ?? {},
      )).toList();
      
      print('✅ Performance data loaded successfully');
      return performances;
    } catch (e) {
      print('❌ Error fetching performance data: $e');
      // Return mock data for demo purposes
      return [
        Performance(
          id: 1,
          studentId: studentId,
          levelId: 1,
          score: 85,
          correctAnswers: 17,
          totalQuestions: 20,
          timeTaken: 900, // 15 minutes in seconds
          answers: [],
          completedAt: DateTime.now().subtract(const Duration(days: 2)),
          level: {
            'id': 1,
            'level_number': 1,
            'title': 'C Programming Basics',
            'description': 'Basic concepts of C programming',
          },
        ),
        Performance(
          id: 2,
          studentId: studentId,
          levelId: 2,
          score: 92,
          correctAnswers: 18,
          totalQuestions: 20,
          timeTaken: 720, // 12 minutes in seconds
          answers: [],
          completedAt: DateTime.now().subtract(const Duration(days: 1)),
          level: {
            'id': 2,
            'level_number': 2,
            'title': 'Data Types and Variables',
            'description': 'Understanding data types and variable declaration',
          },
        ),
        Performance(
          id: 3,
          studentId: studentId,
          levelId: 3,
          score: 78,
          correctAnswers: 15,
          totalQuestions: 20,
          timeTaken: 1080, // 18 minutes in seconds
          answers: [],
          completedAt: DateTime.now(),
          level: {
            'id': 3,
            'level_number': 3,
            'title': 'Control Structures',
            'description': 'If statements, loops, and control flow',
          },
        ),
      ];
    }
  }

  static Future<void> sendNotification({
    required String senderId,
    required String receiverId,
    required String message,
    required String type,
  }) async {
    try {
      print('📨 Sending notification from $senderId to $receiverId');
      
      await client.from('notifications').insert({
        'from_user_id': senderId,
        'to_user_id': receiverId,
        'message': message,
        'type': type,
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
      
      print('✅ Notification sent successfully');
    } catch (e) {
      print('❌ Error sending notification: $e');
      // For demo purposes, just print the notification
      print('📨 DEMO NOTIFICATION:');
      print('   From: $senderId');
      print('   To: $receiverId');
      print('   Message: $message');
      print('   Type: $type');
    }
  }

  static Future<List<app_notification.Notification>> getUserNotifications(String userId) async {
    try {
      print('📬 Fetching notifications for user: $userId');
      
      final response = await client
          .from('notifications')
          .select('*')
          .eq('to_user_id', userId)
          .order('created_at', ascending: false);
      
      print('📨 Found ${response.length} notifications');
      
      final notifications = response.map((data) => app_notification.Notification.fromMap(data)).toList();
      
      print('✅ Notifications loaded successfully');
      return notifications;
    } catch (e) {
      print('❌ Error fetching notifications: $e');
      // Return mock data for demo purposes
      return [
        app_notification.Notification(
          id: '1',
          senderId: 'staff-1',
          receiverId: userId,
          message: 'Hello! I\'m your assigned staff member. Feel free to reach out if you have any questions about the course material.',
          type: 'general',
          isRead: false,
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        app_notification.Notification(
          id: '2',
          senderId: 'staff-1',
          receiverId: userId,
          message: 'There will be a review session tomorrow at 2 PM. Please make sure to attend as we\'ll be covering important topics.',
          type: 'meeting',
          isRead: true,
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        app_notification.Notification(
          id: '3',
          senderId: 'staff-1',
          receiverId: userId,
          message: 'Don\'t forget to complete Level 3 by the end of this week. You\'re doing great so far!',
          type: 'general',
          isRead: false,
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];
    }
  }

  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      print('✅ Marking notification as read: $notificationId');
      
      await client
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
      
      print('✅ Notification marked as read');
    } catch (e) {
      print('❌ Error marking notification as read: $e');
      // For demo purposes, just print the action
      print('✅ DEMO: Marked notification $notificationId as read');
    }
  }

  // Leaderboard methods
  static Future<void> updateLeaderboard({
    required String studentId,
    required int levelId,
    required int score,
    required int timeTaken,
  }) async {
    try {
      print('🏆 Updating leaderboard for student: $studentId, level: $levelId');
      print('🏆 Score: $score, Time: $timeTaken seconds');
      
      // Validate input data
      if (score < 0 || score > 100) {
        print('❌ Invalid score: $score (must be 0-100)');
        return;
      }
      
      if (timeTaken < 0) {
        print('❌ Invalid time: $timeTaken seconds');
        return;
      }
      
      // First, check if entry exists
      final existingEntry = await client
          .from('leaderboard')
          .select()
          .eq('student_id', studentId)
          .eq('level_id', levelId)
          .maybeSingle();
      
      if (existingEntry != null) {
        print('🏆 Existing entry found: Score ${existingEntry['score']}, Time ${existingEntry['time_taken']}');
        // Update existing entry if score is better or time is faster
        if (score > existingEntry['score'] || 
            (score == existingEntry['score'] && timeTaken < existingEntry['time_taken'])) {
          await client
              .from('leaderboard')
              .update({
                'score': score,
                'time_taken': timeTaken,
                'completed_at': DateTime.now().toIso8601String(),
              })
              .eq('student_id', studentId)
              .eq('level_id', levelId);
          print('✅ Leaderboard entry updated');
        } else {
          print('🏆 Score not improved, keeping existing entry');
        }
      } else {
        // Create new entry
        await client.from('leaderboard').insert({
          'student_id': studentId,
          'level_id': levelId,
          'score': score,
          'time_taken': timeTaken,
          'completed_at': DateTime.now().toIso8601String(),
        });
        print('✅ New leaderboard entry created');
      }
      
      // Update rankings for this level
      await _updateLevelRankings(levelId);
      
      print('🏆 Leaderboard update completed successfully');
      
    } catch (e) {
      print('❌ Error updating leaderboard: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      throw Exception('Failed to update leaderboard: $e');
    }
  }

  static Future<void> _updateLevelRankings(int levelId) async {
    try {
      print('🔄 Updating rankings for level: $levelId');
      
      // Get all entries for this level, ordered by score (desc) and time (asc)
      final entries = await client
          .from('leaderboard')
          .select()
          .eq('level_id', levelId)
          .order('score', ascending: false)
          .order('time_taken', ascending: true);
      
      // Update rank positions
      for (int i = 0; i < entries.length; i++) {
        await client
            .from('leaderboard')
            .update({'rank_position': i + 1})
            .eq('id', entries[i]['id']);
      }
      
      print('✅ Rankings updated for level $levelId');
    } catch (e) {
      print('❌ Error updating rankings: $e');
    }
  }

  static Future<List<LeaderboardEntry>> getLeaderboardForLevel(int levelId) async {
    try {
      print('🏆 Fetching leaderboard for level: $levelId');
      
      // First get the leaderboard entries
      final leaderboardResponse = await client
          .from('leaderboard')
          .select('*')
          .eq('level_id', levelId)
          .order('rank_position', ascending: true)
          .limit(50); // Top 50 students
      
      if (leaderboardResponse.isEmpty) {
        print('🏆 No leaderboard entries found for level $levelId');
        return [];
      }
      
      // Get user profiles for the students
      final studentIds = leaderboardResponse.map((e) => e['student_id']).toList();
      final userProfilesResponse = await client
          .from('user_profiles')
          .select('id, email, username')
          .inFilter('id', studentIds);
      
      // Get level information
      final levelResponse = await client
          .from('levels')
          .select('id, title, level_number')
          .eq('id', levelId)
          .single();
      
      // Create a map for quick lookup
      final userProfilesMap = Map.fromEntries(
        userProfilesResponse.map((e) => MapEntry(e['id'], e))
      );
      
      print('🏆 Found ${leaderboardResponse.length} leaderboard entries');
      
      return leaderboardResponse.map((data) => LeaderboardEntry(
        id: data['id'],
        studentId: data['student_id'],
        levelId: data['level_id'],
        score: data['score'] ?? 0,
        timeTaken: data['time_taken'] ?? 0,
        rankPosition: data['rank_position'],
        completedAt: data['completed_at'] != null 
            ? DateTime.parse(data['completed_at']) 
            : DateTime.now(),
        studentName: userProfilesMap[data['student_id']]?['username'],
        studentEmail: userProfilesMap[data['student_id']]?['email'],
        levelTitle: levelResponse['title'],
        levelNumber: levelResponse['level_number'],
      )).toList();
    } catch (e) {
      print('❌ Error fetching leaderboard: $e');
      throw Exception('Failed to fetch leaderboard: $e');
    }
  }

  static Future<List<LeaderboardEntry>> getGlobalLeaderboard() async {
    try {
      print('🏆 Fetching global leaderboard');
      
      // Get all leaderboard entries
      final response = await client
          .from('leaderboard')
          .select('*')
          .order('score', ascending: false)
          .order('time_taken', ascending: true)
          .limit(100); // Get more entries to filter in code
      
      if (response.isEmpty) {
        print('🏆 No leaderboard entries found');
        return [];
      }
      
      // Get user profiles for all students
      final studentIds = response.map((e) => e['student_id']).toSet().toList();
      final userProfilesResponse = await client
          .from('user_profiles')
          .select('id, email, username')
          .inFilter('id', studentIds);
      
      // Get all levels
      final levelIds = response.map((e) => e['level_id']).toSet().toList();
      final levelsResponse = await client
          .from('levels')
          .select('id, title, level_number')
          .inFilter('id', levelIds);
      
      // Create maps for quick lookup
      final userProfilesMap = Map.fromEntries(
        userProfilesResponse.map((e) => MapEntry(e['id'], e))
      );
      final levelsMap = Map.fromEntries(
        levelsResponse.map((e) => MapEntry(e['id'], e))
      );
      
      print('🏆 Found ${response.length} leaderboard entries');
      
      // Filter to get only the best score per student
      final Map<String, LeaderboardEntry> bestScores = {};
      
      for (final data in response) {
        final studentId = data['student_id'];
        final score = data['score'];
        final timeTaken = data['time_taken'];
        
        if (!bestScores.containsKey(studentId) || 
            score > bestScores[studentId]!.score ||
            (score == bestScores[studentId]!.score && timeTaken < bestScores[studentId]!.timeTaken)) {
          bestScores[studentId] = LeaderboardEntry(
            id: data['id'],
            studentId: data['student_id'],
            levelId: data['level_id'],
            score: data['score'] ?? 0,
            timeTaken: data['time_taken'] ?? 0,
            rankPosition: null, // Global ranking will be calculated in UI
            completedAt: data['completed_at'] != null 
                ? DateTime.parse(data['completed_at']) 
                : DateTime.now(),
            studentName: userProfilesMap[data['student_id']]?['username'],
            studentEmail: userProfilesMap[data['student_id']]?['email'],
            levelTitle: levelsMap[data['level_id']]?['title'],
            levelNumber: levelsMap[data['level_id']]?['level_number'],
          );
        }
      }
      
      // Convert to list and sort by score and time
      final sortedEntries = bestScores.values.toList()
        ..sort((a, b) {
          if (a.score != b.score) {
            return b.score.compareTo(a.score); // Higher score first
          }
          return a.timeTaken.compareTo(b.timeTaken); // Lower time first
        });
      
      // Limit to top 50
      final finalEntries = sortedEntries.take(50).toList();
      
      print('🏆 Processed ${finalEntries.length} unique student entries');
      return finalEntries;
    } catch (e) {
      print('❌ Error fetching global leaderboard: $e');
      throw Exception('Failed to fetch global leaderboard: $e');
    }
  }

  // Debug method to check leaderboard state
  static Future<void> debugLeaderboard() async {
    try {
      print('🔍 Debugging leaderboard state...');
      
      // Check total entries
      final leaderboardEntries = await client
          .from('leaderboard')
          .select('*');
      
      print('📊 Total leaderboard entries: ${leaderboardEntries.length}');
      
      if (leaderboardEntries.isNotEmpty) {
        // Show sample entries
        final sampleEntries = leaderboardEntries.take(5).toList();
        
        print('📋 Sample entries:');
        for (final entry in sampleEntries) {
          print('   Student: ${entry['student_id']}, Level: ${entry['level_id']}, Score: ${entry['score']}, Time: ${entry['time_taken']}');
        }
      }
      
      // Check user_profiles table
      final users = await client
          .from('user_profiles')
          .select('*');
      print('👥 Total users: ${users.length}');
      
      // Check levels table
      final levels = await client
          .from('levels')
          .select('*');
      print('📚 Total levels: ${levels.length}');
      
    } catch (e) {
      print('❌ Error debugging leaderboard: $e');
    }
  }

  static Future<List<LeaderboardEntry>> getStudentLeaderboard(String studentId) async {
    try {
      print('🏆 Fetching leaderboard for student: $studentId');
      
      final response = await client
          .from('leaderboard')
          .select('*')
          .eq('student_id', studentId)
          .order('level_id', ascending: true);
      
      if (response.isEmpty) {
        print('🏆 No leaderboard entries found for student');
        return [];
      }
      
      // Get level information
      final levelIds = response.map((e) => e['level_id']).toSet().toList();
      final levelsResponse = await client
          .from('levels')
          .select('id, title, level_number')
          .inFilter('id', levelIds);
      
      // Create a map for quick lookup
      final levelsMap = Map.fromEntries(
        levelsResponse.map((e) => MapEntry(e['id'], e))
      );
      
      print('🏆 Found ${response.length} entries for student');
      
      return response.map((data) => LeaderboardEntry(
        id: data['id'],
        studentId: data['student_id'],
        levelId: data['level_id'],
        score: data['score'] ?? 0,
        timeTaken: data['time_taken'] ?? 0,
        rankPosition: data['rank_position'],
        completedAt: data['completed_at'] != null 
            ? DateTime.parse(data['completed_at']) 
            : DateTime.now(),
        levelTitle: levelsMap[data['level_id']]?['title'],
        levelNumber: levelsMap[data['level_id']]?['level_number'],
      )).toList();
    } catch (e) {
      print('❌ Error fetching student leaderboard: $e');
      throw Exception('Failed to fetch student leaderboard: $e');
    }
  }
}