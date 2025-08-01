import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/auth_controller.dart';
import '../../models/user.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  final _enrollmentNoController = TextEditingController();
  final _classController = TextEditingController();
  final _yearController = TextEditingController();
  
  bool _isLoading = false;
  String? _error;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _usernameController.dispose();
    _enrollmentNoController.dispose();
    _classController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final authController = context.read<AuthController>();
    _currentUser = authController.currentUser;
    
    if (_currentUser != null) {
      _phoneController.text = _currentUser!.phone;
      _usernameController.text = _currentUser!.username ?? '';
      _enrollmentNoController.text = _currentUser!.enrollmentNo ?? '';
      _classController.text = _currentUser!.class_ ?? '';
      _yearController.text = _currentUser!.year?.toString() ?? '';
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentUser == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await SupabaseService.updateUserProfile(
        userId: _currentUser!.id,
        phone: _phoneController.text.trim(),
        username: _usernameController.text.trim().isEmpty 
            ? null 
            : _usernameController.text.trim(),
        enrollmentNo: _enrollmentNoController.text.trim().isEmpty 
            ? null 
            : _enrollmentNoController.text.trim(),
        class_: _classController.text.trim().isEmpty 
            ? null 
            : _classController.text.trim(),
        year: _yearController.text.trim().isEmpty 
            ? null 
            : int.tryParse(_yearController.text.trim()),
      );

      // Update the current user in the auth controller
      final authController = context.read<AuthController>();
      await authController.refreshUserProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue, Colors.purple],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Icon(
                        _getUserIcon(),
                        size: 40,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _currentUser?.email ?? 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _getRoleDisplayName(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Read-only Email Field
              TextFormField(
                initialValue: _currentUser?.email ?? '',
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  helperText: 'Email cannot be changed',
                  helperStyle: TextStyle(color: Colors.grey.shade600),
                ),
                style: TextStyle(color: Colors.grey.shade700),
              ),
              
              const SizedBox(height: 16),
              
              // Editable Phone Field
              CustomTextField(
                controller: _phoneController,
                labelText: 'Phone Number',
                prefixIcon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Editable Username Field (only for students)
              if (_currentUser?.isStudent == true) ...[
                Text(
                  'Username',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _usernameController,
                  labelText: 'Display Name',
                  prefixIcon: Icons.person,
                  keyboardType: TextInputType.text,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a display name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
              
              // Student-specific fields (only show for students)
              if (_currentUser?.isStudent == true) ...[
                Text(
                  'Student Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _enrollmentNoController,
                        labelText: 'Enrollment Number',
                        prefixIcon: Icons.badge,
                        keyboardType: TextInputType.text,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter enrollment number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextField(
                        controller: _classController,
                        labelText: 'Class',
                        prefixIcon: Icons.class_,
                        keyboardType: TextInputType.text,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your class';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                CustomTextField(
                  controller: _yearController,
                  labelText: 'Year (1-4)',
                  prefixIcon: Icons.calendar_today,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your year';
                    }
                    final year = int.tryParse(value);
                    if (year == null || year < 1 || year > 4) {
                      return 'Please enter a valid year (1-4)';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 8),
                
                const SizedBox(height: 8),
                
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Text(
                          'e.g., EN2024001',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Text(
                          'e.g., CSE, ECE, ME',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Text(
                    'e.g., A, B, C, Morning, Evening',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
              ],
              
              // Error Message
              if (_error != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              
              const SizedBox(height: 24),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: _isLoading ? 'Saving...' : 'Save Changes',
                  onPressed: _isLoading ? null : _saveProfile,
                  isLoading: _isLoading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getUserIcon() {
    switch (_currentUser?.role) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'staff':
        return Icons.person;
      case 'student':
        return Icons.school;
      default:
        return Icons.person;
    }
  }

  String _getRoleDisplayName() {
    switch (_currentUser?.role) {
      case 'admin':
        return 'Administrator';
      case 'staff':
        return 'Staff Member';
      case 'student':
        return 'Student';
      default:
        return 'User';
    }
  }
} 