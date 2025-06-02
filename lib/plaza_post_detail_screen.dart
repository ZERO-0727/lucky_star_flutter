import 'package:flutter/material.dart';

class PlazaPostDetailScreen extends StatefulWidget {
  final String title;
  final String displayName;
  final String timestamp;
  final String description;
  final List<String> categories;
  final List<String> comments;

  const PlazaPostDetailScreen({
    Key? key,
    this.title = 'Post Details',
    this.displayName = 'Anonymous',
    this.timestamp = 'Just now',
    this.description = 'No description provided',
    this.categories = const [],
    this.comments = const [],
  }) : super(key: key);

  @override
  _PlazaPostDetailScreenState createState() => _PlazaPostDetailScreenState();
}

class _PlazaPostDetailScreenState extends State<PlazaPostDetailScreen> {
  final TextEditingController _commentController = TextEditingController();
  final List<String> _photos = ['placeholder1', 'placeholder2', 'placeholder3'];
  int _likeCount = 42;
  bool _isLiked = false;
  bool _isBookmarked = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Detail'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Implement share functionality
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Author Info
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        widget.displayName,
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.timestamp,
                        style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Image Carousel
                  SizedBox(
                    height: 300,
                    child: PageView.builder(
                      itemCount: _photos.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.grey[300],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Engagement Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      IconButton(
                        icon: Icon(
                          _isLiked ? Icons.favorite : Icons.favorite_border,
                          color: _isLiked ? Colors.red : null,
                        ),
                        onPressed: () {
                          setState(() {
                            _isLiked = !_isLiked;
                            _likeCount += _isLiked ? 1 : -1;
                          });
                        },
                      ),
                      Text('$_likeCount Likes'),
                      IconButton(
                        icon: Icon(
                          _isBookmarked
                              ? Icons.bookmark
                              : Icons.bookmark_border,
                        ),
                        onPressed: () {
                          setState(() {
                            _isBookmarked = !_isBookmarked;
                          });
                        },
                      ),
                      const Text('Bookmark'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Description
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.description,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),

                  // Category Tags
                  if (widget.categories.isNotEmpty) ...[
                    const Text(
                      'Categories',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children:
                          widget.categories.map((category) {
                            return Chip(
                              label: Text(category),
                              backgroundColor: const Color(
                                0xFF7153DF,
                              ).withAlpha(25),
                              labelStyle: const TextStyle(
                                color: Color(0xFF7153DF),
                              ),
                            );
                          }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Comments Section
                  const Text(
                    'Comments',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (widget.comments.isEmpty)
                    const Center(child: Text('No comments yet')),
                  ...widget.comments.map((comment) {
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.person),
                      ),
                      title: Text(comment),
                      subtitle: const Text('2 hours ago'),
                      trailing: IconButton(
                        icon: const Icon(Icons.favorite_border),
                        onPressed: () {},
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 80), // Spacer for fixed input
                ],
              ),
            ),
          ),

          // Fixed Comment Input
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF7153DF)),
                  onPressed: () {
                    if (_commentController.text.isNotEmpty) {
                      // Add comment
                      setState(() {
                        widget.comments.add(_commentController.text);
                        _commentController.clear();
                      });
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
