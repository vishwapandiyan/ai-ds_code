import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/user.dart';

class AuthController extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;
  String? _error;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser != null;
  String? get error => _error;

  AuthController() {
    // Don't auto-initialize in constructor to avoid setState during build
  }

  Future<void> initialize() async {
    try {
      _isLoading = true;
      notifyListeners();

      final user = await SupabaseService.getCurrentUser();
      _currentUser = user;
      _error = null;
      
      print('🔐 AuthController initialized - User: ${user?.email}');
    } catch (e) {
      _error = e.toString();
      print('❌ AuthController initialization error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> login({required String email, required String password}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await SupabaseService.signIn(email: email, password: password);
      
      // Get the user from the response
      if (response.user != null) {
        _currentUser = await SupabaseService.getCurrentUser();
      }
      
      return _currentUser != null;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> registerStudent({required String email, required String password, required String phone}) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await SupabaseService.signUp(
        email: email,
        password: password,
        phone: phone,
        role: 'student',
      );
      
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await SupabaseService.signOut();
      _currentUser = null;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> refreshUserProfile() async {
    try {
      _currentUser = await SupabaseService.getCurrentUser();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
} 