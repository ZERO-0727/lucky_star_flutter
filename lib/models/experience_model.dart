import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cross_file/cross_file.dart'; // Import XFile

class ExperienceModel {
  final String experienceId;
  final String userId;
  final DocumentReference? userRef;
  final String title;
  final String description;
  final String location;
  final DateTime date;
  final List<String> tags;
  final List<String> photoUrls;
  final List<XFile> images; // Add this line
  final int availableSlots;
  final int currentParticipants;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String status;
  final bool isPublic;

  ExperienceModel({
    required this.experienceId,
    required this.userId,
    this.userRef,
    required this.title,
    required this.description,
    required this.location,
    required this.date,
    this.tags = const [],
    this.photoUrls = const [],
    this.images = const [], // Add this line
    this.availableSlots = 1,
    this.currentParticipants = 0,
    required this.createdAt,
    required this.updatedAt,
    this.status = 'active',
    this.isPublic = true,
  });

  // Create a new instance with updated fields
  ExperienceModel copyWith({
    String? experienceId,
    String? userId,
    DocumentReference? userRef,
    String? title,
    String? description,
    String? location,
    DateTime? date,
    List<String>? tags,
    List<String>? photoUrls,
    List<XFile>? images, // Add this line
    int? availableSlots,
    int? currentParticipants,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
    bool? isPublic,
  }) {
    return ExperienceModel(
      experienceId: experienceId ?? this.experienceId,
      userId: userId ?? this.userId,
      userRef: userRef ?? this.userRef,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      date: date ?? this.date,
      tags: tags ?? this.tags,
      photoUrls: photoUrls ?? this.photoUrls,
      images: images ?? this.images, // Add this line
      availableSlots: availableSlots ?? this.availableSlots,
      currentParticipants: currentParticipants ?? this.currentParticipants,
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
    DateTime timestampToDateTime(dynamic timestamp) {
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      }
      return DateTime.now();
    }

    // Helper function to safely convert to List<String>
    List<String> toStringList(dynamic list) {
      if (list is List) {
        return list.map((item) => item.toString()).toList();
      }
      return [];
    }

    return ExperienceModel(
      experienceId: doc.id,
      userId: data['userId'] ?? '',
      userRef: data['userRef'] as DocumentReference?,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      date: timestampToDateTime(data['date']),
      tags: toStringList(data['tags']),
      photoUrls: toStringList(data['photoUrls']),
      images: [], // Add this line
      availableSlots: data['availableSlots'] ?? 1,
      currentParticipants: data['currentParticipants'] ?? 0,
      createdAt: timestampToDateTime(data['createdAt']),
      updatedAt: timestampToDateTime(data['updatedAt']),
      status: data['status'] ?? 'active',
      isPublic: data['isPublic'] ?? true,
    );
  }

  // Convert ExperienceModel to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userRef': userRef,
      'title': title,
      'description': description,
      'location': location,
      'date': Timestamp.fromDate(date),
      'tags': tags,
      'photoUrls': photoUrls, // Image URLs will be updated separately
      'availableSlots': availableSlots,
      'currentParticipants': currentParticipants,
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
      images: [], // Add this line
    );
  }

  // Check if the experience is active
  bool get isActive => status == 'active';

  // Check if the experience is completed
  bool get isCompleted => status == 'completed';

  // Check if the experience is cancelled
  bool get isCancelled => status == 'cancelled';

  // Check if the experience has available slots
  bool get hasAvailableSlots => currentParticipants < availableSlots;

  // Get remaining slots
  int get remainingSlots => availableSlots - currentParticipants;
}
