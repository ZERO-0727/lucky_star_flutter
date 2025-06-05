import 'package:cloud_firestore/cloud_firestore.dart';

class WishModel {
  final String wishId;
  final String userId;
  final String title;
  final String description;
  final String location;
  final DateTime preferredDate;
  final double? budget;
  final List<String> categories;
  final List<String> photoUrls;
  final int interestedCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String status;

  WishModel({
    required this.wishId,
    required this.userId,
    required this.title,
    required this.description,
    required this.location,
    required this.preferredDate,
    this.budget,
    this.categories = const [],
    this.photoUrls = const [],
    this.interestedCount = 0,
    required this.createdAt,
    required this.updatedAt,
    this.status = 'Open',
  });

  // Create a new instance with updated fields
  WishModel copyWith({
    String? wishId,
    String? userId,
    String? title,
    String? description,
    String? location,
    DateTime? preferredDate,
    double? budget,
    List<String>? categories,
    List<String>? photoUrls,
    int? interestedCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? status,
  }) {
    return WishModel(
      wishId: wishId ?? this.wishId,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      preferredDate: preferredDate ?? this.preferredDate,
      budget: budget ?? this.budget,
      categories: categories ?? this.categories,
      photoUrls: photoUrls ?? this.photoUrls,
      interestedCount: interestedCount ?? this.interestedCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
    );
  }

  // Create a WishModel from a Firestore document
  factory WishModel.fromFirestore(DocumentSnapshot doc) {
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

    return WishModel(
      wishId: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      preferredDate: _timestampToDateTime(data['preferredDate']),
      budget:
          data['budget'] != null ? (data['budget'] as num).toDouble() : null,
      categories: _toStringList(data['categories']),
      photoUrls: _toStringList(data['photoUrls']),
      interestedCount: data['interestedCount'] ?? 0,
      createdAt: _timestampToDateTime(data['createdAt']),
      updatedAt: _timestampToDateTime(data['updatedAt']),
      status: data['status'] ?? 'Open',
    );
  }

  // Convert WishModel to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    final Map<String, dynamic> data = {
      'userId': userId,
      'title': title,
      'description': description,
      'location': location,
      'preferredDate': Timestamp.fromDate(preferredDate),
      'categories': categories,
      'photoUrls': photoUrls,
      'interestedCount': interestedCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'status': status,
    };

    // Only add budget if it's not null
    if (budget != null) {
      data['budget'] = budget;
    }

    return data;
  }

  // Create an empty wish model with default values
  factory WishModel.empty() {
    final now = DateTime.now();
    return WishModel(
      wishId: '',
      userId: '',
      title: '',
      description: '',
      location: '',
      preferredDate: now.add(
        const Duration(days: 14),
      ), // Default to two weeks from now
      createdAt: now,
      updatedAt: now,
    );
  }

  // Check if the wish is open
  bool get isOpen => status == 'Open';

  // Check if the wish is fulfilled
  bool get isFulfilled => status == 'Fulfilled';

  // Check if the wish is closed
  bool get isClosed => status == 'Closed';

  // Format the budget as a string with currency symbol
  String get formattedBudget {
    if (budget == null) return 'Flexible';
    return '\$${budget!.toStringAsFixed(2)}';
  }
}
