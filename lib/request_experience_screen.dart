import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/chat_service.dart';
import 'chat_detail_screen.dart';

class RequestExperienceScreen extends StatefulWidget {
  final String? targetUserId;
  final String? targetUserName;
  final String? targetUserAvatar;

  const RequestExperienceScreen({
    super.key,
    this.targetUserId,
    this.targetUserName,
    this.targetUserAvatar,
  });

  @override
  _RequestExperienceScreenState createState() =>
      _RequestExperienceScreenState();
}

class _RequestExperienceScreenState extends State<RequestExperienceScreen> {
  final _formKey = GlobalKey<FormState>();
  final ChatService _chatService = ChatService();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  final List<String> _categories = ['Food', 'Sport', 'Travel'];
  final Map<String, bool> _selectedCategories = {};
  final List<String> _photos = [];
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _participantsController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    for (var category in _categories) {
      _selectedCategories[category] = false;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != _selectedTime) {
      setState(() => _selectedTime = picked);
    }
  }

  void _addPhoto() {
    // In a real app, this would open an image picker
    setState(() {
      _photos.add('placeholder');
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check if user is logged in
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to submit a request'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Check if we have a target user to send the request to
    if (widget.targetUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No target user specified for this request'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Build the request message with form details
      final requestMessage = _buildRequestMessage();

      // Create or get existing conversation
      final conversationId = await _chatService.createConversation(
        otherUserId: widget.targetUserId!,
        initialMessage: requestMessage,
      );

      if (mounted) {
        // Navigate to chat detail screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => ChatDetailScreen(
                  chatId: conversationId,
                  userName: widget.targetUserName ?? 'Host',
                  userAvatar: widget.targetUserAvatar,
                  initialMessage: requestMessage,
                ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String _buildRequestMessage() {
    final buffer = StringBuffer();
    buffer.writeln('🌟 Experience Request');
    buffer.writeln();
    buffer.writeln('Title: ${_titleController.text}');
    buffer.writeln();
    buffer.writeln('Description: ${_descController.text}');

    if (_selectedDate != null) {
      buffer.writeln();
      buffer.writeln(
        'Preferred Date: ${DateFormat.yMd().format(_selectedDate!)}',
      );
    }

    if (_selectedTime != null) {
      buffer.writeln('Preferred Time: ${_selectedTime!.format(context)}');
    }

    // Add selected categories
    final selectedCategories =
        _selectedCategories.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key)
            .toList();

    if (selectedCategories.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Categories: ${selectedCategories.join(', ')}');
    }

    // Add budget if specified
    if (_budgetController.text.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Budget: \$${_budgetController.text}');
    }

    // Add participants if specified
    if (_participantsController.text.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Participants: ${_participantsController.text}');
    }

    buffer.writeln();
    buffer.writeln(
      'I would love to connect with you about this experience! 😊',
    );

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Experience'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  hintText: 'What experience are you looking for?',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe the experience you want...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Date & Time Fields
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Preferred Date',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        child: Text(
                          _selectedDate != null
                              ? DateFormat.yMd().format(_selectedDate!)
                              : 'Select date',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectTime(context),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Preferred Time',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        child: Text(
                          _selectedTime != null
                              ? _selectedTime!.format(context)
                              : 'Select time',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Category Selection
              Text('Category', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                children:
                    _categories.map((category) {
                      return FilterChip(
                        label: Text(category),
                        selected: _selectedCategories[category]!,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategories[category] = selected;
                          });
                        },
                        backgroundColor: Colors.grey[200],
                        selectedColor: const Color(0xFF7153DF).withAlpha(51),
                        checkmarkColor: const Color(0xFF7153DF),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 24),

              // Optional Fields
              const Text(
                'Optional Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Budget Field
              TextFormField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Budget (optional)',
                  prefixText: '\$',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 16),

              // Participants Field
              TextFormField(
                controller: _participantsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Number of Participants (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 24),

              // Photo Upload
              Text(
                'Photos (optional)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _photos.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _photos.length) {
                      return InkWell(
                        onTap: _addPhoto,
                        child: Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add, size: 40),
                              Text('Add Photo'),
                            ],
                          ),
                        ),
                      );
                    }
                    return Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        color: Colors.grey[300],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            right: 0,
                            child: IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _photos.removeAt(index);
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 40),

              // Submit Button
              Center(
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7153DF),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.0),
                    ),
                    minimumSize: const Size(double.infinity, 50),
                    disabledBackgroundColor: Colors.grey.shade400,
                  ),
                  child:
                      _isSubmitting
                          ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Submitting...',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          )
                          : const Text(
                            'Submit Request',
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
