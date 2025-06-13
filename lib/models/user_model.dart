import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String displayName;
  final String bio;
  final String avatarUrl;
  final List<String> interests;
  final List<String> visitedCountries;
  final List<String> verificationBadges;
  final int referenceCount;
  final Map<String, dynamic> statistics;
  final String status;
  final String location;
  final String gender;
  final List<String> languages;
  final int trustScore;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.userId,
    required this.displayName,
    this.bio = '',
    this.avatarUrl = '',
    this.interests = const [],
    this.visitedCountries = const [],
    this.verificationBadges = const [],
    this.referenceCount = 0,
    this.statistics = const {},
    this.status = 'Available',
    this.location = '',
    this.gender = '',
    this.languages = const [],
    this.trustScore = 0,
    this.isVerified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create a new instance with updated fields
  UserModel copyWith({
    String? userId,
    String? displayName,
    String? bio,
    String? avatarUrl,
    List<String>? interests,
    List<String>? visitedCountries,
    List<String>? verificationBadges,
    int? referenceCount,
    Map<String, dynamic>? statistics,
    String? status,
    String? location,
    String? gender,
    List<String>? languages,
    int? trustScore,
    bool? isVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      interests: interests ?? this.interests,
      visitedCountries: visitedCountries ?? this.visitedCountries,
      verificationBadges: verificationBadges ?? this.verificationBadges,
      referenceCount: referenceCount ?? this.referenceCount,
      statistics: statistics ?? this.statistics,
      status: status ?? this.status,
      location: location ?? this.location,
      gender: gender ?? this.gender,
      languages: languages ?? this.languages,
      trustScore: trustScore ?? this.trustScore,
      isVerified: isVerified ?? this.isVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Create a UserModel from a Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Helper function to safely convert Timestamp to DateTime
    DateTime? timestampToDateTime(dynamic timestamp) {
      if (timestamp is Timestamp) {
        return timestamp.toDate();
      }
      return null;
    }

    // Helper function to safely convert to List<String>
    List<String> toStringList(dynamic list) {
      if (list is List) {
        return list.map((item) => item.toString()).toList();
      }
      return [];
    }

    return UserModel(
      userId: doc.id,
      displayName: data['displayName'] ?? '',
      bio: data['bio'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      interests: toStringList(data['interests']),
      visitedCountries: toStringList(data['visitedCountries']),
      verificationBadges: toStringList(data['verificationBadges']),
      referenceCount: data['referenceCount'] ?? 0,
      statistics: data['statistics'] as Map<String, dynamic>? ?? {},
      status: data['status'] ?? 'Available',
      location: data['location'] ?? '',
      gender: data['gender'] ?? '',
      languages: toStringList(data['languages']),
      trustScore: data['trustScore'] ?? 0,
      isVerified: data['isVerified'] ?? false,
      createdAt: timestampToDateTime(data['createdAt']) ?? DateTime.now(),
      updatedAt: timestampToDateTime(data['updatedAt']) ?? DateTime.now(),
    );
  }

  // Convert UserModel to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'displayName': displayName,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'interests': interests,
      'visitedCountries': visitedCountries,
      'verificationBadges': verificationBadges,
      'referenceCount': referenceCount,
      'statistics': statistics,
      'status': status,
      'location': location,
      'gender': gender,
      'languages': languages,
      'trustScore': trustScore,
      'isVerified': isVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Helper methods to access statistics
  int get experiencesCount => statistics['experiencesCount'] as int? ?? 0;
  int get wishesCount => statistics['wishesCount'] as int? ?? 0;
  int get wishesFullfilledCount =>
      statistics['wishesFullfilledCount'] as int? ?? 0;
  int get responseRate => statistics['responseRate'] as int? ?? 0;

  // Create an empty user model with default values
  factory UserModel.empty() {
    final now = DateTime.now();
    return UserModel(
      userId: '',
      displayName: 'Guest User',
      createdAt: now,
      updatedAt: now,
    );
  }
}
