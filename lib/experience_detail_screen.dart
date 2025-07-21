import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'models/experience_model.dart';
import 'models/user_model.dart';
import 'services/experience_service.dart';
import 'services/favorites_service.dart';
import 'services/user_service.dart';
import 'services/chat_service.dart';
import 'chat_detail_screen.dart';
import 'user_detail_page.dart';

class ExperienceDetailScreen extends StatefulWidget {
  final String experienceId;
  final ExperienceModel? experience; // Optional - if we already have the data

  const ExperienceDetailScreen({
    super.key,
    required this.experienceId,
    this.experience,
  });

  @override
  State<ExperienceDetailScreen> createState() => _ExperienceDetailScreenState();
}

class _ExperienceDetailScreenState extends State<ExperienceDetailScreen> {
  final ExperienceService _experienceService = ExperienceService();
  final UserService _userService = UserService();
  final ChatService _chatService = ChatService();
  ExperienceModel? _experience;
  UserModel? _publisher;
  bool _isLoading = true;
  bool _isLoadingPublisher = true;
  bool _isJoining = false;
  bool _isFavorited = false;
  String? _error;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (widget.experience != null) {
      _experience = widget.experience;
      _isLoading = false;
      _loadPublisherData();
      _loadFavoriteStatus();
    } else {
      _loadExperience();
    }
  }

  Future<void> _loadExperience() async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('experiences')
              .doc(widget.experienceId)
              .get();

      if (doc.exists) {
        setState(() {
          _experience = ExperienceModel.fromFirestore(doc);
          _isLoading = false;
        });
        _loadPublisherData();
        _loadFavoriteStatus();
      } else {
        setState(() {
          _error = 'Experience not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading experience: $e';
        _isLoading = false;
      });
    }
  }

  // Fetch user data for the experience publisher
  Future<void> _loadPublisherData() async {
    if (_experience == null) return;

    setState(() {
      _isLoadingPublisher = true;
    });

    try {
      if (_experience!.userRef != null) {
        // Fetch from userRef if available
        final doc = await _experience!.userRef!.get();
        if (doc.exists) {
          _publisher = UserModel.fromFirestore(
            doc as DocumentSnapshot<Map<String, dynamic>>,
          );
        }
      }

      _publisher ??= await _userService.getUserById(_experience!.userId);
    } catch (e) {
      print('Error fetching publisher data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPublisher = false;
        });
      }
    }
  }

  // Check if publisher has Pro membership
  bool get _isProMember {
    return _publisher?.verificationBadges.contains('pro') ?? false;
  }

  Future<void> _loadFavoriteStatus() async {
    if (_currentUserId == null) return;

    try {
      final isFavorited = await FavoritesService.isExperienceFavorited(
        widget.experienceId,
      );
      if (mounted) {
        setState(() {
          _isFavorited = isFavorited;
        });
      }
    } catch (e) {
      print('Error loading favorite status: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to add favorites'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final success = await FavoritesService.toggleExperienceFavorite(
        widget.experienceId,
      );
      if (success && mounted) {
        setState(() {
          _isFavorited = !_isFavorited;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isFavorited ? 'Added to favorites' : 'Removed from favorites',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating favorites: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _joinExperience() {
    if (_experience == null) return;
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to join experiences'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    _showJoinExperienceDialog(_experience!);
  }

  Future<void> _showJoinExperienceDialog(ExperienceModel experience) async {
    final TextEditingController messageController = TextEditingController();

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Join Experience'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Experience preview
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        // Thumbnail
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: Colors.grey.shade300,
                          ),
                          child:
                              experience.photoUrls.isNotEmpty
                                  ? ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.network(
                                      experience.photoUrls.first,
                                      fit: BoxFit.cover,
                                      errorBuilder: (
                                        context,
                                        error,
                                        stackTrace,
                                      ) {
                                        return const Icon(
                                          Icons.image,
                                          color: Colors.grey,
                                        );
                                      },
                                    ),
                                  )
                                  : const Icon(
                                    Icons.explore,
                                    color: Colors.grey,
                                  ),
                        ),
                        const SizedBox(width: 12),
                        // Content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                experience.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${DateFormat('MMM dd').format(experience.date)} • ${experience.location}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Message input
                  TextField(
                    controller: messageController,
                    maxLines: 3,
                    maxLength: 200,
                    decoration: InputDecoration(
                      hintText: 'Send a message to the host...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Reminder text
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You can only send one message. The host must reply to continue.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (messageController.text.trim().isEmpty) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter a message'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                    return;
                  }

                  // Close the dialog and show loading indicator
                  Navigator.of(context).pop();

                  setState(() {
                    _isJoining = true;
                  });

                  try {
                    final initialMessage = messageController.text.trim();

                    // Create or get the conversation
                    final conversationId = await _chatService
                        .createConversation(
                          otherUserId: experience.userId,
                          experienceId: experience.experienceId,
                          initialMessage: initialMessage,
                        );

                    // Get the host details
                    String hostName = 'Host';
                    String? hostAvatar;

                    if (_publisher != null) {
                      hostName =
                          _publisher!.displayName.isNotEmpty
                              ? _publisher!.displayName
                              : 'Host';
                      hostAvatar = _publisher!.avatarUrl;
                    }

                    if (mounted) {
                      // Navigate to chat detail screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => ChatDetailScreen(
                                chatId: conversationId,
                                userName: hostName,
                                userAvatar: hostAvatar,
                                experience: experience,
                                initialMessage: initialMessage,
                              ),
                        ),
                      );
                    }
                  } catch (e, stackTrace) {
                    // Print detailed error information to terminal
                    _printDetailedError('Join Experience', e, stackTrace);

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Failed to start chat: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isJoining = false;
                      });
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Send Message and Start Chat'),
              ),
            ],
          ),
    );
  }

  Future<void> _contactHost() async {
    if (_experience == null || _currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to contact the host'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isJoining = true;
    });

    try {
      // Create or get the conversation (without sending automatic message)
      final conversationId = await _chatService.createConversation(
        otherUserId: _experience!.userId,
        experienceId: _experience!.experienceId,
      );

      // Get the host details
      String hostName = 'Host';
      String? hostAvatar;

      if (_publisher != null) {
        hostName =
            _publisher!.displayName.isNotEmpty
                ? _publisher!.displayName
                : 'Host';
        hostAvatar = _publisher!.avatarUrl;
      }

      if (mounted) {
        // Navigate to chat detail screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ChatDetailScreen(
                  chatId: conversationId,
                  userName: hostName,
                  userAvatar: hostAvatar,
                  experience: _experience,
                ),
          ),
        );
      }
    } catch (e, stackTrace) {
      // Print detailed error information to terminal
      _printDetailedError('Contact Host', e, stackTrace);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final experience = _experience!;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with back button + Host Info (horizontally aligned)
          SliverAppBar(
            leadingWidth: 40, // Slightly reduced width for the back button
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Row(
              children: [
                // Publisher Avatar with loading states - Tappable
                GestureDetector(
                  onTap: () {
                    if (_publisher != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => UserDetailPage(
                                userId: _publisher!.userId,
                                displayName: _publisher!.displayName,
                              ),
                        ),
                      );
                    }
                  },
                  child:
                      _isLoadingPublisher ||
                              _publisher == null ||
                              _publisher!.avatarUrl.isEmpty
                          ? CircleAvatar(
                            radius: 18,
                            backgroundColor: Theme.of(context).primaryColor,
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 16,
                            ),
                          )
                          : CircleAvatar(
                            radius: 18,
                            backgroundImage: NetworkImage(
                              _publisher!.avatarUrl,
                            ),
                            backgroundColor: Colors.grey.shade200,
                          ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          _isLoadingPublisher ||
                                  _publisher == null ||
                                  _publisher!.displayName.isEmpty
                              ? 'Host: ${experience.userId.substring(0, min(8, experience.userId.length))}...'
                              : _publisher!.displayName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).primaryColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Pro badge if user has Pro membership
                      if (_publisher != null && _isProMember)
                        Container(
                          margin: const EdgeInsets.only(left: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade700,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'PRO',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            actions: [
              if (_isCurrentUserAuthor())
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.black),
                  onSelected: _handleMenuAction,
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'share',
                          child: ListTile(
                            leading: Icon(Icons.share),
                            title: Text('Share this post'),
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(Icons.delete, color: Colors.red),
                            title: Text(
                              'Delete this post',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                ),
            ],
          ),

          // Image Gallery with timestamp overlay at top-right
          SliverToBoxAdapter(
            child: Stack(
              children: [
                _buildImageGallery(experience.photoUrls),

                // Posted time ago overlay (moved to top-right corner)
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withOpacity(0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 12,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTimeAgo(experience.createdAt),
                          style: TextStyle(
                            color: Colors.grey.shade800,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title with Star
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          experience.title,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _isFavorited ? Icons.star : Icons.star_border,
                          color: Colors.blue.shade600,
                          size: 28,
                        ),
                        onPressed: _toggleFavorite,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Available Slots Badge
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.people,
                            size: 16,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${experience.availableSlots} slots',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Description
                  _buildDescription(experience),
                  const SizedBox(height: 24),

                  // Details Section removed - no need for spacing

                  // Tags
                  _buildTags(experience),
                  const SizedBox(height: 24),

                  // Location
                  _buildLocation(experience),
                  const SizedBox(height: 32),

                  // Action Buttons - Only show if NOT the current user's post
                  if (!_isCurrentUserAuthor()) _buildActionButtons(experience),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery(List<String> photoUrls) {
    if (photoUrls.isEmpty) {
      return Container(
        height: 240,
        color: Colors.grey.shade300,
        child: const Center(
          child: Icon(Icons.image, size: 80, color: Colors.grey),
        ),
      );
    }

    // Current displayed image index for PageView
    final ValueNotifier<int> currentIndex = ValueNotifier<int>(0);

    if (photoUrls.length == 1) {
      return GestureDetector(
        onTap: () => _showFullscreenImage(context, photoUrls, 0),
        child: Container(
          height: 500, // Maximum height for desktop as per requirements
          constraints: const BoxConstraints(maxHeight: 500),
          width: double.infinity,
          color: const Color(0xFFF5F5F5), // Light gray background (#f5f5f5)
          child: Center(
            child: Image.network(
              photoUrls.first,
              fit: BoxFit.contain, // Complete display of image
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade300,
                  child: const Center(
                    child: Icon(
                      Icons.broken_image,
                      size: 80,
                      color: Colors.grey,
                    ),
                  ),
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        value:
                            loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading image...',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );
    }

    // Multiple images with carousel
    return Column(
      children: [
        SizedBox(
          height: 500, // Maximum height for desktop
          child: Stack(
            children: [
              // Main carousel
              PageView.builder(
                itemCount: photoUrls.length,
                onPageChanged: (index) {
                  currentIndex.value = index;
                },
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap:
                        () => _showFullscreenImage(context, photoUrls, index),
                    child: Container(
                      color: const Color(0xFFF5F5F5), // Light gray background
                      child: Center(
                        child: Image.network(
                          photoUrls[index],
                          fit: BoxFit.contain, // Complete display
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey.shade300,
                              child: const Center(
                                child: Icon(
                                  Icons.broken_image,
                                  size: 80,
                                  color: Colors.grey,
                                ),
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    value:
                                        loadingProgress.expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Loading image...',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Left and right navigation arrows
              Positioned.fill(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left arrow
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.black54,
                        ),
                        onPressed: () {
                          if (currentIndex.value > 0) {
                            currentIndex.value--;
                          } else {
                            currentIndex.value =
                                photoUrls.length - 1; // Loop to end
                          }
                        },
                      ),
                    ),
                    // Right arrow
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.black54,
                        ),
                        onPressed: () {
                          if (currentIndex.value < photoUrls.length - 1) {
                            currentIndex.value++;
                          } else {
                            currentIndex.value = 0; // Loop to beginning
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Image counter
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ValueListenableBuilder<int>(
                    valueListenable: currentIndex,
                    builder: (context, index, _) {
                      return Text(
                        '${index + 1}/${photoUrls.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),

        // Dot indicators at bottom
        const SizedBox(height: 12),
        ValueListenableBuilder<int>(
          valueListenable: currentIndex,
          builder: (context, index, _) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                photoUrls.length,
                (i) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        i == index
                            ? Colors.blue.shade600
                            : Colors.grey.shade300,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // Method to show fullscreen image viewer
  void _showFullscreenImage(
    BuildContext context,
    List<String> photoUrls,
    int initialIndex,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final ValueNotifier<int> currentIndex = ValueNotifier<int>(
          initialIndex,
        );

        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Main image viewer with PageView for swiping
              PageView.builder(
                itemCount: photoUrls.length,
                controller: PageController(initialPage: initialIndex),
                onPageChanged: (index) {
                  currentIndex.value = index;
                },
                itemBuilder: (context, index) {
                  return InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Center(
                      child: Image.network(
                        photoUrls[index],
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.broken_image,
                                  size: 80,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Image could not be loaded',
                                  style: TextStyle(color: Colors.grey.shade400),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),

              // Close button (X)
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),

              // Image counter
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ValueListenableBuilder<int>(
                    valueListenable: currentIndex,
                    builder: (context, index, _) {
                      return Text(
                        '${index + 1}/${photoUrls.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Navigation arrows (only show for multiple images)
              if (photoUrls.length > 1)
                Positioned.fill(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left arrow
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: 32,
                        ),
                        onPressed: () {
                          if (currentIndex.value > 0) {
                            currentIndex.value--;
                          } else {
                            currentIndex.value =
                                photoUrls.length - 1; // Loop to end
                          }
                        },
                      ),
                      // Right arrow
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 32,
                        ),
                        onPressed: () {
                          if (currentIndex.value < photoUrls.length - 1) {
                            currentIndex.value++;
                          } else {
                            currentIndex.value = 0; // Loop to beginning
                          }
                        },
                      ),
                    ],
                  ),
                ),

              // Hint text for zooming
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Pinch to zoom • Swipe to navigate',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDescription(ExperienceModel experience) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'About this experience',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          experience.description,
          style: const TextStyle(fontSize: 16, height: 1.5),
        ),
      ],
    );
  }

  // Details section completely removed as it's redundant
  Widget _buildDetails(ExperienceModel experience) {
    // Return an empty widget as this section is no longer needed
    return const SizedBox.shrink();
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildTags(ExperienceModel experience) {
    if (experience.tags.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Categories',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              experience.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue.shade300),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildLocation(ExperienceModel experience) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: Colors.blue.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              experience.location,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ExperienceModel experience) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _isJoining ? null : _joinExperience,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              disabledBackgroundColor: Colors.grey.shade400,
            ),
            child:
                _isJoining
                    ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                    : const Text(
                      'Join Experience',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: _isJoining ? null : _contactHost,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue.shade600,
              side: BorderSide(color: Colors.blue.shade600),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Contact Host',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  bool _isCurrentUserAuthor() {
    if (_currentUserId == null || _experience == null) return false;
    return _currentUserId == _experience!.userId;
  }

  void _handleMenuAction(String action) async {
    switch (action) {
      case 'share':
        await _sharePost();
        break;
      case 'delete':
        await _showDeleteConfirmation();
        break;
    }
  }

  Future<void> _sharePost() async {
    try {
      final experienceUrl =
          'https://luckystar.app/experience/${widget.experienceId}';
      await Clipboard.setData(ClipboardData(text: experienceUrl));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Link copied to clipboard!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy link: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Experience'),
            content: const Text(
              'Are you sure you want to delete this experience? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await _deleteExperience();
    }
  }

  Future<void> _deleteExperience() async {
    try {
      await FirebaseFirestore.instance
          .collection('experiences')
          .doc(widget.experienceId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Experience deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete experience: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime);
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  /// Print detailed error information to terminal for debugging
  /// This is especially useful for Firestore database index errors
  void _printDetailedError(
    String actionType,
    dynamic error,
    StackTrace? stackTrace,
  ) {
    print('\n' + '=' * 80);
    print('🚨 CHAT/MESSAGING ERROR DETAILS');
    print('=' * 80);
    print('Action Type: $actionType');
    print('Screen: Experience Detail Screen');
    print('Timestamp: ${DateTime.now().toIso8601String()}');

    if (_experience != null) {
      print('\nExperience Context:');
      print('  - Experience ID: ${_experience!.experienceId}');
      print('  - Host User ID: ${_experience!.userId}');
      print('  - Experience Title: ${_experience!.title}');
      print('  - Experience Location: ${_experience!.location}');
    }

    if (_currentUserId != null) {
      print('\nUser Context:');
      print('  - Current User ID: $_currentUserId');
    }

    print('\nError Details:');
    print('  Error Type: ${error.runtimeType}');
    print('  Error Message: $error');

    // Check if this looks like a Firestore index error
    final errorString = error.toString().toLowerCase();
    if (errorString.contains('index') ||
        errorString.contains('composite') ||
        errorString.contains('requires an index')) {
      print('\n🔍 INDEX ERROR DETECTED!');
      print('This error indicates that a Firestore database index is missing.');
      print('Follow these steps to resolve:');
      print('');
      print('1. Go to Firebase Console: https://console.firebase.google.com/');
      print('2. Navigate to your project');
      print('3. Go to Firestore Database > Indexes');
      print(
        '4. Look for the suggested index configuration in the error message above',
      );
      print('5. Create the composite index as suggested');
      print('');
      print(
        'Alternative: Check the Firebase Console for automatic index creation suggestions.',
      );
    }

    // Check for permission errors
    if (errorString.contains('permission') || errorString.contains('denied')) {
      print('\n🔒 PERMISSION ERROR DETECTED!');
      print(
        'This error indicates insufficient Firestore security rules permissions.',
      );
      print(
        'Check your Firestore security rules for the chats/conversations collection.',
      );
    }

    // Print current action configuration for debugging
    print('\nAction Configuration:');
    print('  Collection: chats/conversations');
    print('  Operation: Create conversation and send message');

    if (actionType.contains('Contact Host')) {
      print('  Scenario: Direct contact to experience host');
      print(
        '  Required Fields: participants, experienceId, lastMessage, createdAt, updatedAt',
      );
    } else if (actionType.contains('Join Experience')) {
      print('  Scenario: Join experience with initial message');
      print(
        '  Required Fields: participants, experienceId, lastMessage, initialMessage, createdAt, updatedAt',
      );
    }

    print('\n💡 Common Chat Service Index Requirements:');
    print('  Collection: chats');
    print('  Typical indexes needed:');
    print('    - participants (Arrays), updatedAt (Descending)');
    print(
      '    - participants (Arrays), experienceId (Ascending), updatedAt (Descending)',
    );
    print('    - experienceId (Ascending), updatedAt (Descending)');

    // Print stack trace if available
    if (stackTrace != null) {
      print('\nStack Trace:');
      print(stackTrace.toString());
    }

    print('=' * 80);
    print('END ERROR DETAILS');
    print('=' * 80 + '\n');
  }
}
