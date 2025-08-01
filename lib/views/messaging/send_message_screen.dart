import 'package:flutter/material.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_button.dart';

class SendMessageScreen extends StatefulWidget {
  final Map<String, dynamic>? student; // null for sending to all students

  const SendMessageScreen({
    super.key,
    this.student,
  });

  @override
  State<SendMessageScreen> createState() => _SendMessageScreenState();
}

class _SendMessageScreenState extends State<SendMessageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  String _selectedType = 'general';
  bool _isLoading = false;

  final List<String> _messageTypes = [
    'general',
    'meeting',
    'approval',
    'decline',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = await SupabaseService.getCurrentUser();
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      if (widget.student != null) {
        // Send to specific student
        await SupabaseService.sendNotification(
          senderId: currentUser.id,
          receiverId: widget.student!['id'],
          message: _messageController.text.trim(),
          type: _selectedType,
        );
      } else {
        // Send to all assigned students
        final assignedStudents = await SupabaseService.getStudentsByStaff(currentUser.id);
        for (final student in assignedStudents) {
          await SupabaseService.sendNotification(
            senderId: currentUser.id,
            receiverId: student.id,
            message: _messageController.text.trim(),
            type: _selectedType,
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.student != null
                  ? 'Message sent to ${widget.student!['username'] ?? widget.student!['email']}'
                  : 'Message sent to all assigned students',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $e'),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.student != null
              ? 'Send Message to ${widget.student!['username'] ?? widget.student!['email']}'
              : 'Send Message to All Students',
        ),
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
              // Recipient Info
              if (widget.student != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.blue,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.student!['username'] ?? widget.student!['email'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              if (widget.student!['enrollment_no'] != null)
                                Text('Enrollment: ${widget.student!['enrollment_no']}'),
                              if (widget.student!['class_name'] != null)
                                Text('Class: ${widget.student!['class_name']}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ] else ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(Icons.people, color: Colors.blue, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'All Assigned Students',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text('This message will be sent to all students assigned to you'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Message Type
              Text(
                'Message Type',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                items: _messageTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
              
              const SizedBox(height: 16),



              // Message Field
              TextFormField(
                controller: _messageController,
                maxLines: 6,
                decoration: InputDecoration(
                  labelText: 'Message',
                  prefixIcon: const Icon(Icons.message),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a message';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 24),

              // Send Button
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: _isLoading ? 'Sending...' : 'Send Message',
                  onPressed: _isLoading ? null : _sendMessage,
                  backgroundColor: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 