import 'package:cloud_firestore/cloud_firestore.dart';

class ExperienceModel {
  final String experienceId;
  final String userId;
  final String title;
  final String description;
  final String location;
  final DateTime date;
  final List<String> categories;
  final List<String> photoUrls;
  final int participantCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String status;
  final bool isPublic;

  ExperienceModel({
    required this.experienceId,
    required this.userId,
    required this.title,
    required this.description,
    required this.location,
    required this.date,
    this.categories = const [],
    this.photoUrls = const [],
    this.participantCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.status = 'Active',
    this.isPublic = true,
  });

  // Create a new instance with updated fields
  ExperienceModel copyWith({
    String? experienceId,
    String? userId,
    String? title,
    String? description,
    String? location,
    DateTime? date,
    List<String>? categories,
    List<String>? photoUrls,
    int? participantCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
    bool? isPublic,
  }) {
    return ExperienceModel(
      experienceId: experienceId ?? this.experienceId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      date: date ?? this.date,
      categories: categories ?? this.categories,
      photoUrls: photoUrls ?? this.photoUrls,
      participantCount: participantCount ?? this.participantCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      isPublic: isPublic ?? this.isPublic,
    );
  }

  // Create an ExperienceModel from a Firestore document
  factory ExperienceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Helper function to safely convert Timestamp to DateTime
    DateTime _timestampToDateTime(dynamic timestamp) {
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      }
      return DateTime.now();
    }

    // Helper function to safely convert to List<String>
    List<String> _toStringList(dynamic list) {
      if (list is List) {
        return list.map((item) => item.toString()).toList();
      }
      return [];
    }

    return ExperienceModel(
      experienceId: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      date: _timestampToDateTime(data['date']),
      categories: _toStringList(data['categories']),
      photoUrls: _toStringList(data['photoUrls']),
      participantCount: data['participantCount'] ?? 0,
      createdAt: _timestampToDateTime(data['createdAt']),
      updatedAt: _timestampToDateTime(data['updatedAt']),
      status: data['status'] ?? 'Active',
      isPublic: data['isPublic'] ?? true,
    );
  }

  // Convert ExperienceModel to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'location': location,
      'date': Timestamp.fromDate(date),
      'categories': categories,
      'photoUrls': photoUrls,
      'participantCount': participantCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'status': status,
      'isPublic': isPublic,
    };
  }

  // Create an empty experience model with default values
  factory ExperienceModel.empty() {
    final now = DateTime.now();
    return ExperienceModel(
      experienceId: '',
      userId: '',
      title: '',
      description: '',
      location: '',
      date: now.add(const Duration(days: 7)), // Default to a week from now
      createdAt: now,
      updatedAt: now,
    );
  }

  // Check if the experience is active
  bool get isActive => status == 'Active';

  // Check if the experience is completed
  bool get isCompleted => status == 'Completed';

  // Check if the experience is cancelled
  bool get isCancelled => status == 'Cancelled';
}
