import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/feedback_service.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({Key? key}) : super(key: key);

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final TextEditingController _feedbackController = TextEditingController();
  String _selectedType = 'Bug report';
  bool _submitted = false;
  bool _isSubmitting = false;

  final List<String> _feedbackTypes = [
    'Bug report',
    'Suggestion',
    'Complaint',
    'Other',
  ];

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (_feedbackController.text.trim().isEmpty || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      await FeedbackService.submitFeedback(
        type: _selectedType,
        content: _feedbackController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _submitted = true;
          _isSubmitting = false;
        });

        // Auto-close after showing success message
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    } catch (e) {
      print('Error submitting feedback: $e');

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        // Show error dialog
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text(
                  'Error',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                content: Text(
                  'Failed to submit feedback. Please check your internet connection and try again.',
                  style: GoogleFonts.poppins(),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'OK',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFF7153DF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Give Us Feedback'),
        centerTitle: true,
        elevation: 0,
      ),
      body:
          _submitted
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.check_circle, color: Colors.pink, size: 64),
                    SizedBox(height: 24),
                    Text(
                      'Feedback sent',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32.0),
                      child: Text(
                        'Thank you for submitting product feedback. We will share this with the appropriate team.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              )
              : Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    const Text(
                      'We’d love to hear your thoughts, suggestions, or any issues you’ve encountered.',
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      items:
                          _feedbackTypes
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ),
                              )
                              .toList(),
                      onChanged: (value) {
                        if (value != null)
                          setState(() => _selectedType = value);
                      },
                      decoration: const InputDecoration(
                        labelText: 'Type of feedback',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _feedbackController,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        hintText: 'Write your feedback here...',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                _feedbackController.text.trim().isEmpty ||
                                        _isSubmitting
                                    ? null
                                    : _submitFeedback,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.pink,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child:
                                _isSubmitting
                                    ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Submitting...',
                                          style: GoogleFonts.poppins(),
                                        ),
                                      ],
                                    )
                                    : Text(
                                      'Submit',
                                      style: GoogleFonts.poppins(),
                                    ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
    );
  }
}
