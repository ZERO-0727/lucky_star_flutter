import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../lib/services/wish_service.dart';
import '../../lib/models/wish_model.dart';

// Mock classes for testing
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockCollectionReference extends Mock implements CollectionReference {}

class MockDocumentReference extends Mock implements DocumentReference {}

void main() {
  group('WishService Tests', () {
    late WishService wishService;
    late MockFirebaseFirestore mockFirestore;
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;

    setUp(() {
      mockFirestore = MockFirebaseFirestore();
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();
      wishService = WishService();
    });

    test('should create WishService instance', () {
      expect(wishService, isNotNull);
    });

    test('should have proper authentication getter', () {
      // Test that currentUser getter exists and can be accessed
      final user = wishService.currentUser;
      // Should not throw an error even if null
      expect(user, isA<User?>());
    });

    test('should validate WishModel creation', () {
      final now = DateTime.now();
      final wish = WishModel(
        wishId: 'test_wish_1',
        userId: 'test_user_1',
        title: 'Test Wish',
        description: 'This is a test wish',
        location: 'Test Location',
        preferredDate: now.add(const Duration(days: 7)),
        budget: 100.0,
        categories: ['Food', 'Travel'],
        photoUrls: ['https://example.com/photo1.jpg'],
        interestedCount: 5,
        createdAt: now,
        updatedAt: now,
        status: 'Open',
      );

      expect(wish.wishId, equals('test_wish_1'));
      expect(wish.title, equals('Test Wish'));
      expect(wish.description, equals('This is a test wish'));
      expect(wish.location, equals('Test Location'));
      expect(wish.budget, equals(100.0));
      expect(wish.categories, contains('Food'));
      expect(wish.categories, contains('Travel'));
      expect(wish.photoUrls, contains('https://example.com/photo1.jpg'));
      expect(wish.interestedCount, equals(5));
      expect(wish.status, equals('Open'));
      expect(wish.isOpen, isTrue);
      expect(wish.isFulfilled, isFalse);
      expect(wish.isClosed, isFalse);
    });

    test('should format budget correctly', () {
      final now = DateTime.now();

      // Test with budget
      final wishWithBudget = WishModel(
        wishId: 'test1',
        userId: 'user1',
        title: 'Test',
        description: 'Test',
        location: 'Test',
        preferredDate: now,
        budget: 150.50,
        createdAt: now,
        updatedAt: now,
      );

      expect(wishWithBudget.formattedBudget, equals('\$150.50'));

      // Test without budget
      final wishWithoutBudget = WishModel(
        wishId: 'test2',
        userId: 'user2',
        title: 'Test',
        description: 'Test',
        location: 'Test',
        preferredDate: now,
        budget: null,
        createdAt: now,
        updatedAt: now,
      );

      expect(wishWithoutBudget.formattedBudget, equals('Flexible'));
    });

    test('should create empty wish model', () {
      final emptyWish = WishModel.empty();

      expect(emptyWish.wishId, isEmpty);
      expect(emptyWish.userId, isEmpty);
      expect(emptyWish.title, isEmpty);
      expect(emptyWish.description, isEmpty);
      expect(emptyWish.location, isEmpty);
      expect(emptyWish.categories, isEmpty);
      expect(emptyWish.photoUrls, isEmpty);
      expect(emptyWish.interestedCount, equals(0));
      expect(emptyWish.budget, isNull);
      expect(emptyWish.status, equals('Open'));
    });

    test('should copy wish model with changes', () {
      final originalWish = WishModel.empty();
      final updatedWish = originalWish.copyWith(
        title: 'Updated Title',
        budget: 250.0,
        interestedCount: 10,
      );

      expect(updatedWish.title, equals('Updated Title'));
      expect(updatedWish.budget, equals(250.0));
      expect(updatedWish.interestedCount, equals(10));

      // Unchanged fields should remain the same
      expect(updatedWish.wishId, equals(originalWish.wishId));
      expect(updatedWish.userId, equals(originalWish.userId));
      expect(updatedWish.description, equals(originalWish.description));
    });

    test('should convert to Firestore format correctly', () {
      final now = DateTime.now();
      final wish = WishModel(
        wishId: 'test_wish',
        userId: 'test_user',
        title: 'Test Wish',
        description: 'Test Description',
        location: 'Test Location',
        preferredDate: now.add(const Duration(days: 7)),
        budget: 100.0,
        categories: ['Food'],
        photoUrls: ['url1'],
        interestedCount: 3,
        createdAt: now,
        updatedAt: now,
        status: 'Open',
      );

      final firestoreData = wish.toFirestore();

      expect(firestoreData['userId'], equals('test_user'));
      expect(firestoreData['title'], equals('Test Wish'));
      expect(firestoreData['description'], equals('Test Description'));
      expect(firestoreData['location'], equals('Test Location'));
      expect(firestoreData['budget'], equals(100.0));
      expect(firestoreData['categories'], equals(['Food']));
      expect(firestoreData['photoUrls'], equals(['url1']));
      expect(firestoreData['interestedCount'], equals(3));
      expect(firestoreData['status'], equals('Open'));
      expect(firestoreData['preferredDate'], isA<Timestamp>());
      expect(firestoreData['createdAt'], isA<Timestamp>());
      expect(firestoreData['updatedAt'], isA<Timestamp>());
    });
  });
}
