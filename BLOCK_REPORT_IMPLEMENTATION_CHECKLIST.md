# Block User & Report User Implementation Checklist

## Overview
This checklist provides a comprehensive guide for implementing robust Block User and Report User functionality, following Twitter's approach and ensuring production-ready implementation.

## ✅ PHASE 1: DATA MODELS & FIREBASE STRUCTURE

### 1.1 UserModel Updates
- [ ] **CRITICAL**: Add `blockedUsers` field to UserModel
  ```dart
  final List<String> blockedUsers;
  ```
- [ ] Add `blockedByUsers` field for reverse lookup (optional but recommended)
  ```dart
  final List<String> blockedByUsers;
  ```
- [ ] Update `UserModel.fromFirestore()` constructor to handle new fields
- [ ] Update `UserModel.toFirestore()` method to include new fields
- [ ] Update `UserModel.copyWith()` method for new fields
- [ ] Add helper methods:
  ```dart
  bool isUserBlocked(String userId) => blockedUsers.contains(userId);
  bool isBlockedByUser(String userId) => blockedByUsers.contains(userId);
  ```

### 1.2 Block Data Model
- [ ] Create `lib/models/block_model.dart`
  ```dart
  class BlockModel {
    final String id;
    final String blockerId;
    final String blockedUserId;
    final DateTime createdAt;
    final String reason; // optional
    final String status; // active, removed
    final Map<String, dynamic> metadata; // context info
  }
  ```

### 1.3 Report Data Model  
- [ ] Create `lib/models/report_model.dart`
  ```dart
  class ReportModel {
    final String id;
    final String reporterId;
    final String reportedUserId;
    final ReportReason reason;
    final String category; // harassment, spam, inappropriate, fake, other
    final String description;
    final String? chatId; // context if reported from chat
    final String? messageId; // specific message if applicable
    final List<String> evidence; // screenshot URLs, etc.
    final ReportStatus status; // pending, reviewing, resolved, dismissed
    final DateTime createdAt;
    final DateTime? resolvedAt;
    final String? adminNotes;
    final ReportSeverity severity; // low, medium, high, critical
  }
  
  enum ReportReason {
    harassment, spam, inappropriateContent, fakeAccount, 
    impersonation, selfHarm, violence, other
  }
  
  enum ReportStatus { pending, reviewing, resolved, dismissed }
  enum ReportSeverity { low, medium, high, critical }
  ```

## ✅ PHASE 2: FIREBASE SECURITY RULES

### 2.1 Update firestore.rules
- [ ] Add rules for `blocks` collection:
  ```javascript
  match /blocks/{blockId} {
    allow read: if isSignedIn() && 
      (request.auth.uid == resource.data.blockerId || isAdmin());
    allow create: if isSignedIn() && 
      request.auth.uid == request.resource.data.blockerId;
    allow update, delete: if isSignedIn() && 
      (request.auth.uid == resource.data.blockerId || isAdmin());
  }
  ```

- [ ] Add rules for `reports` collection:
  ```javascript
  match /reports/{reportId} {
    allow read: if isSignedIn() && 
      (request.auth.uid == resource.data.reporterId || isAdmin());
    allow create: if isSignedIn() && 
      request.auth.uid == request.resource.data.reporterId;
    allow update: if isAdmin(); // Only admins can update reports
    allow delete: if isAdmin(); // Only admins can delete reports
  }
  ```

- [ ] Update users collection rules to handle blocked user filtering
- [ ] Add admin helper function

### 2.2 Database Indexes
- [ ] Create composite indexes in Firebase Console:
  - `blocks`: `blockerId` (Ascending), `status` (Ascending), `createdAt` (Descending)
  - `blocks`: `blockedUserId` (Ascending), `status` (Ascending), `createdAt` (Descending)
  - `reports`: `reportedUserId` (Ascending), `status` (Ascending), `severity` (Descending)
  - `reports`: `reporterId` (Ascending), `createdAt` (Descending)
  - `reports`: `status` (Ascending), `createdAt` (Descending) - for admin dashboard

## ✅ PHASE 3: BACKEND SERVICE UPDATES

### 3.1 UserService Enhancements
- [ ] **CRITICAL**: Fix `blockUser()` method to update UserModel properly:
  ```dart
  Future<void> blockUser(String blockedUserId) async {
    final currentUserId = _getCurrentUserId();
    
    // Update current user's blockedUsers array
    await _usersCollection.doc(currentUserId).update({
      'blockedUsers': FieldValue.arrayUnion([blockedUserId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    // Optionally update blocked user's blockedByUsers array
    await _usersCollection.doc(blockedUserId).update({
      'blockedByUsers': FieldValue.arrayUnion([currentUserId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    // Create block record with enhanced data
    await _firestore.collection('blocks').add({
      'blockerId': currentUserId,
      'blockedUserId': blockedUserId,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'active',
      'reason': reason ?? 'user_initiated',
      'metadata': metadata ?? {},
    });
  }
  ```

- [ ] Add `unblockUser()` method
- [ ] Update `getAllUsersFiltered()` to exclude blocked users
- [ ] Update `searchUsersByName()` to exclude blocked users
- [ ] Add `getMutuallyBlockedUsers()` for admin purposes
- [ ] Enhance `isUserBlocked()` with caching for performance

### 3.2 Enhanced Report Service
- [ ] Create `lib/services/report_service.dart`
- [ ] Implement comprehensive reporting with categories:
  ```dart
  Future<void> reportUser({
    required String reportedUserId,
    required ReportReason reason,
    required String category,
    required String description,
    String? chatId,
    String? messageId,
    List<String> evidence = const [],
  })
  ```
- [ ] Add automatic severity assignment based on reason
- [ ] Implement report deduplication logic
- [ ] Add batch reporting for spam detection

### 3.3 Chat Service Updates
- [ ] Prevent message sending between blocked users:
  ```dart
  Future<String> sendMessage({
    required String conversationId,
    required String text,
  }) async {
    // Check if users are mutually blocked
    final conversation = await getConversationById(conversationId);
    final otherUserId = _getOtherParticipantId(conversation);
    
    final isBlocked = await _userService.isUserBlocked(otherUserId);
    final isBlockedBy = await _userService.isBlockedByUser(otherUserId);
    
    if (isBlocked || isBlockedBy) {
      throw Exception('Cannot send message to blocked user');
    }
    
    // Continue with normal message sending...
  }
  ```
- [ ] Filter conversations list to exclude blocked users
- [ ] Handle existing conversations with newly blocked users

### 3.4 Search & Discovery Updates
- [ ] Update ExperienceService to filter blocked users from results
- [ ] Update WishService to filter blocked users from results
- [ ] Update all recommendation algorithms to exclude blocked users
- [ ] Ensure blocked users don't appear in "People you may know" suggestions

## ✅ PHASE 4: USER INTERFACE IMPLEMENTATION

### 4.1 Enhanced Report User Flow
- [ ] Create `lib/screens/report_user_screen.dart`
- [ ] Multi-step reporting process:
  - Step 1: Reason selection (radio buttons for main categories)
  - Step 2: Detailed description (text input)
  - Step 3: Evidence upload (optional screenshots)
  - Step 4: Confirmation and submission
- [ ] Context-aware reporting (different options for chat vs profile)
- [ ] Success feedback with next steps information

### 4.2 Block User Experience
- [ ] Update block confirmation dialog with clear consequences
- [ ] Add immediate UI feedback (blocked user disappears from lists)
- [ ] Create "Blocked Users" management screen in account settings
- [ ] Add unblock functionality with confirmation

### 4.3 Account Settings Integration
- [ ] Add "Privacy and Safety" section in account settings
- [ ] Include blocked users management
- [ ] Add reporting history (user's own reports)
- [ ] Privacy controls related to blocking

### 4.4 Chat UI Updates
- [ ] Show appropriate messaging when trying to message blocked users
- [ ] Handle existing chat threads with blocked users
- [ ] Prevent new conversation creation with blocked users

## ✅ PHASE 5: ERROR HANDLING & USER FEEDBACK

### 5.1 Error States
- [ ] Handle blocking already blocked users gracefully
- [ ] Prevent self-blocking with clear error messages
- [ ] Handle network errors during block/report operations
- [ ] Implement retry mechanisms for failed operations

### 5.2 User Notifications
- [ ] Success confirmations for blocking actions
- [ ] Report submission confirmations with reference numbers
- [ ] No notifications to blocked users (maintain privacy)

### 5.3 Edge Cases
- [ ] Handle blocking while in active chat
- [ ] Manage existing shared content (experiences/wishes)
- [ ] Consider group interactions (if applicable to your app)
- [ ] Handle mutual blocks appropriately

## ✅ PHASE 6: MODERATION & ADMIN FEATURES

### 6.1 Admin Dashboard Considerations
- [ ] Design report review interface structure
- [ ] Implement report status tracking
- [ ] Add bulk action capabilities for moderators
- [ ] Create report analytics and trends

### 6.2 Automated Moderation
- [ ] Implement thresholds for automatic flags
- [ ] Consider temporary restrictions for frequently reported users
- [ ] Add pattern detection for spam/harassment

### 6.3 User Communication
- [ ] Template responses for report outcomes
- [ ] Appeal process framework
- [ ] User education about reporting/blocking

## ✅ PHASE 7: TESTING & VALIDATION

### 7.1 Unit Tests
- [ ] Test UserService blocking methods
- [ ] Test report creation and validation
- [ ] Test filtering logic in all services
- [ ] Test error handling scenarios

### 7.2 Integration Tests
- [ ] Test complete block/unblock flow
- [ ] Test complete reporting flow
- [ ] Test chat behavior with blocked users
- [ ] Test search filtering with blocked users

### 7.3 UI Tests
- [ ] Test reporting screen flow
- [ ] Test blocked users management
- [ ] Test error states and loading states
- [ ] Test accessibility compliance

### 7.4 Security Tests
- [ ] Verify security rules prevent unauthorized access
- [ ] Test that blocked users cannot interact
- [ ] Verify report data privacy
- [ ] Test admin-only operations

## ✅ PHASE 8: PERFORMANCE OPTIMIZATION

### 8.1 Caching Strategy
- [ ] Implement blocked users list caching
- [ ] Cache frequently accessed user block statuses
- [ ] Optimize database queries with proper indexing

### 8.2 Batch Operations
- [ ] Implement batch filtering for large user lists
- [ ] Optimize report queries for admin dashboard
- [ ] Use Firestore array-contains-any for efficient filtering

## ✅ PHASE 9: MONITORING & ANALYTICS

### 9.1 Metrics Tracking
- [ ] Track block/unblock rates
- [ ] Monitor report submission trends
- [ ] Measure impact on user engagement
- [ ] Track moderation response times

### 9.2 Error Monitoring
- [ ] Set up alerts for blocking/reporting failures
- [ ] Monitor database query performance
- [ ] Track user experience issues

## ✅ PHASE 10: DOCUMENTATION & DEPLOYMENT

### 10.1 User Documentation
- [ ] Create help articles about blocking
- [ ] Document reporting process for users
- [ ] Create safety guidelines and best practices

### 10.2 Developer Documentation
- [ ] Update API documentation
- [ ] Document new database schema
- [ ] Create troubleshooting guides for common issues

### 10.3 Gradual Rollout
- [ ] Plan feature flags for gradual rollout
- [ ] Prepare rollback procedures
- [ ] Monitor metrics during rollout

## ⚠️ CRITICAL DEPENDENCIES

Before starting implementation:
1. **UserModel must be updated** - Current code will fail without blockedUsers field
2. **Security rules must be deployed** - New collections need proper access controls
3. **Database indexes must be created** - Performance will suffer without proper indexing
4. **Existing user data migration** - Consider adding empty blockedUsers arrays to existing users

## 🎯 SUCCESS METRICS

Implementation success should be measured by:
- Zero runtime errors related to blocking functionality
- Complete mutual invisibility between blocked users
- Successful report submission and tracking
- Improved user safety and platform quality
- Maintainable and scalable code architecture

## 📋 ESTIMATED TIMELINE

- **Phase 1-3**: Backend & Data (2-3 days)
- **Phase 4**: UI Implementation (3-4 days) 
- **Phase 5-6**: Polish & Moderation (2-3 days)
- **Phase 7**: Testing (2-3 days)
- **Phase 8-10**: Optimization & Launch (1-2 days)

**Total Estimated Time: 10-15 days**

---

**Note**: This checklist prioritizes user safety, privacy, and platform integrity while following industry best practices for blocking and reporting systems.
