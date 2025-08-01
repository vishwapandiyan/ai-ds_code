import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/user.dart';

class AdminController extends ChangeNotifier {
  List<User> _pendingStudents = [];
  List<User> _allStaff = [];
  List<Map<String, dynamic>> _levels = [];
  bool _isLoading = false;
  bool _isLoadingStudents = false;
  bool _isLoadingStaff = false;
  bool _isLoadingLevels = false;
  String? _error;

  List<User> get pendingStudents => _pendingStudents;
  List<User> get allStaff => _allStaff;
  List<Map<String, dynamic>> get levels => _levels;
  bool get isLoading => _isLoading;
  bool get isLoadingStudents => _isLoadingStudents;
  bool get isLoadingStaff => _isLoadingStaff;
  bool get isLoadingLevels => _isLoadingLevels;
  String? get error => _error;

  Future<void> loadData() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final pendingStudents = await SupabaseService.getPendingStudents();
      final allStaff = await SupabaseService.getAllStaff();
      final levels = await SupabaseService.getLevels();

      _pendingStudents = pendingStudents;
      _allStaff = allStaff;
      _levels = levels;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPendingStudents() async {
    if (_isLoadingStudents) return; // Prevent multiple simultaneous calls
    
    try {
      _isLoadingStudents = true;
      notifyListeners();
      
      final pendingStudents = await SupabaseService.getPendingStudents();
      _pendingStudents = pendingStudents;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingStudents = false;
      notifyListeners();
    }
  }

  Future<void> loadAllStaff() async {
    if (_isLoadingStaff) return; // Prevent multiple simultaneous calls
    
    try {
      _isLoadingStaff = true;
      notifyListeners();
      
      final allStaff = await SupabaseService.getAllStaff();
      _allStaff = allStaff;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingStaff = false;
      notifyListeners();
    }
  }

  Future<List<Map<String, dynamic>>> getAllLevels() async {
    if (_isLoadingLevels) return _levels; // Return cached data if already loading
    
    try {
      _isLoadingLevels = true;
      notifyListeners();
      
      final levels = await SupabaseService.getLevels();
      _levels = levels;
      return levels;
    } catch (e) {
      _error = e.toString();
      return _levels; // Return cached data on error
    } finally {
      _isLoadingLevels = false;
      notifyListeners();
    }
  }

  Future<bool> addStaffMember({required String email, required String password, required String phone}) async {
    try {
      await SupabaseService.createStaffAccount(
        email: email,
        password: password,
        phone: phone,
      );
      await loadAllStaff();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteStaffMember(String staffId) async {
    try {
      await SupabaseService.deleteStaff(staffId);
      await loadAllStaff();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> addLevelWithQuestions({
    required String title,
    required String description,
    required int levelNumber,
    required List<Map<String, dynamic>> questions,
  }) async {
    try {
      await SupabaseService.addLevel(
        title: title,
        description: description,
        levelNumber: levelNumber,
        totalQuestions: questions.length,
      );
      // Don't reload all data, just update the levels
      final levels = await SupabaseService.getLevels();
      _levels = levels;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> reassignSpecificStudent({required String studentId, required String newStaffId}) async {
    try {
      await SupabaseService.reassignStudent(
        studentId: studentId,
        newStaffId: newStaffId,
      );
      await loadPendingStudents();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> approveStudent({required String studentId, required String assignedStaffId}) async {
    try {
      await SupabaseService.approveStudent(
        studentId: studentId,
        assignedStaffId: assignedStaffId,
      );
      await loadPendingStudents();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> declineStudent(String studentId) async {
    try {
      await SupabaseService.declineStudent(studentId);
      await loadPendingStudents();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> createStaffAccount(String email, String password, String phone) async {
    try {
      await SupabaseService.createStaffAccount(
        email: email,
        password: password,
        phone: phone,
      );
      
      await loadData(); // Reload data to get updated staff list
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> promoteStaffToAdmin(String staffId) async {
    try {
      await SupabaseService.promoteStaffToAdmin(staffId);
      await loadAllStaff();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> deleteStaff(String staffId) async {
    try {
      await SupabaseService.deleteStaff(staffId);
      await loadData(); // Reload data
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<bool> reassignStudents({required String currentStaffId, required String newStaffId}) async {
    try {
      // Get all students assigned to the current staff
      final studentsToReassign = _pendingStudents
          .where((student) => student.assignedStaffId == currentStaffId)
          .map((student) => student.id)
          .toList();

      // Reassign each student
      for (final studentId in studentsToReassign) {
        await SupabaseService.reassignStudent(
          studentId: studentId,
          newStaffId: newStaffId,
        );
      }

      await loadPendingStudents();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
} 