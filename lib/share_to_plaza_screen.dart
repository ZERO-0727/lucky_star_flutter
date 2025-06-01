import 'package:flutter/material.dart';

class ShareToPlazaScreen extends StatefulWidget {
  const ShareToPlazaScreen({Key? key}) : super(key: key);

  @override
  _ShareToPlazaScreenState createState() => _ShareToPlazaScreenState();
}

class _ShareToPlazaScreenState extends State<ShareToPlazaScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final List<String> _categories = ['Food', 'Sport', 'Travel'];
  final Map<String, bool> _selectedCategories = {};
  final List<String> _photos = [];

  @override
  void initState() {
    super.initState();
    for (var category in _categories) {
      _selectedCategories[category] = false;
    }
  }

  void _addPhoto() {
    // In a real app, this would open an image picker
    setState(() {
      _photos.add('placeholder');
    });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Form is valid, process data
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post shared successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Share to Plaza'), centerTitle: true),
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
                  hintText: 'Add a title for your post',
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
                  hintText: 'What would you like to share?',
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
                        selectedColor: const Color(0xFF7153DF).withOpacity(0.2),
                        checkmarkColor: const Color(0xFF7153DF),
                      );
                    }).toList(),
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
                              Icon(Icons.camera_alt, size: 40),
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
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7153DF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Share Post',
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
