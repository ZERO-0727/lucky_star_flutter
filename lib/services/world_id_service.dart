import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class WorldIDService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Initialize World ID verification and get verification URL
  static Future<WorldIDInitResponse> initVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final callable = _functions.httpsCallable('initWorldIDVerification');
      final result = await callable.call({});

      final data = result.data;
      if (data['success'] == true) {
        return WorldIDInitResponse(
          success: true,
          verificationUrl: data['verificationUrl'],
          signal: data['signal'],
        );
      } else {
        return WorldIDInitResponse(
          success: false,
          error: data['error'] ?? 'Unknown error',
        );
      }
    } catch (e) {
      print('Error initializing World ID verification: $e');
      return WorldIDInitResponse(success: false, error: e.toString());
    }
  }

  /// Launch World ID verification in external app/browser
  static Future<bool> launchVerification(String verificationUrl) async {
    try {
      final uri = Uri.parse(verificationUrl);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      print('Error launching World ID verification: $e');
      return false;
    }
  }

  /// Verify World ID proof after user completes verification
  static Future<WorldIDVerifyResponse> verifyProof({
    required String nullifierHash,
    required String merkleRoot,
    required String proof,
    required String verificationLevel,
    required String signal,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final callable = _functions.httpsCallable('verifyWorldIDProof');
      final result = await callable.call({
        'nullifier_hash': nullifierHash,
        'merkle_root': merkleRoot,
        'proof': proof,
        'verification_level': verificationLevel,
        'signal': signal,
      });

      final data = result.data;
      return WorldIDVerifyResponse(
        success: data['success'] ?? false,
        verified: data['verified'] ?? false,
        trustScoreBoost: data['trustScoreBoost'] ?? 0,
        verificationBadge: data['verificationBadge'] ?? '',
        error: data['error'],
      );
    } catch (e) {
      print('Error verifying World ID proof: $e');
      return WorldIDVerifyResponse(
        success: false,
        verified: false,
        error: e.toString(),
      );
    }
  }

  /// Get current user's World ID verification status
  static Future<WorldIDStatusResponse> getVerificationStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final callable = _functions.httpsCallable('getWorldIDVerificationStatus');
      final result = await callable.call({});

      final data = result.data;
      return WorldIDStatusResponse(
        success: data['success'] ?? false,
        isVerified: data['isVerified'] ?? false,
        verificationMethod: data['verificationMethod'],
        verifiedAt: data['verifiedAt'],
        trustScore: data['trustScore'] ?? 0,
        verificationBadges: List<String>.from(data['verificationBadges'] ?? []),
        error: data['error'],
      );
    } catch (e) {
      print('Error getting World ID verification status: $e');
      return WorldIDStatusResponse(
        success: false,
        isVerified: false,
        error: e.toString(),
      );
    }
  }

  /// Parse World ID response from URL callback (if using web redirect flow)
  static WorldIDProofData? parseCallbackUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final queryParams = uri.queryParameters;

      if (queryParams.containsKey('nullifier_hash') &&
          queryParams.containsKey('merkle_root') &&
          queryParams.containsKey('proof') &&
          queryParams.containsKey('verification_level')) {
        return WorldIDProofData(
          nullifierHash: queryParams['nullifier_hash']!,
          merkleRoot: queryParams['merkle_root']!,
          proof: queryParams['proof']!,
          verificationLevel: queryParams['verification_level']!,
        );
      }
      return null;
    } catch (e) {
      print('Error parsing World ID callback URL: $e');
      return null;
    }
  }
}

/// Response model for World ID initialization
class WorldIDInitResponse {
  final bool success;
  final String? verificationUrl;
  final String? signal;
  final String? error;

  WorldIDInitResponse({
    required this.success,
    this.verificationUrl,
    this.signal,
    this.error,
  });
}

/// Response model for World ID verification
class WorldIDVerifyResponse {
  final bool success;
  final bool verified;
  final int trustScoreBoost;
  final String verificationBadge;
  final String? error;

  WorldIDVerifyResponse({
    required this.success,
    required this.verified,
    this.trustScoreBoost = 0,
    this.verificationBadge = '',
    this.error,
  });
}

/// Response model for World ID status
class WorldIDStatusResponse {
  final bool success;
  final bool isVerified;
  final String? verificationMethod;
  final dynamic verifiedAt;
  final int trustScore;
  final List<String> verificationBadges;
  final String? error;

  WorldIDStatusResponse({
    required this.success,
    required this.isVerified,
    this.verificationMethod,
    this.verifiedAt,
    this.trustScore = 0,
    this.verificationBadges = const [],
    this.error,
  });
}

/// Model for World ID proof data
class WorldIDProofData {
  final String nullifierHash;
  final String merkleRoot;
  final String proof;
  final String verificationLevel;

  WorldIDProofData({
    required this.nullifierHash,
    required this.merkleRoot,
    required this.proof,
    required this.verificationLevel,
  });

  Map<String, dynamic> toJson() {
    return {
      'nullifier_hash': nullifierHash,
      'merkle_root': merkleRoot,
      'proof': proof,
      'verification_level': verificationLevel,
    };
  }
}

/// Verification states for UI
enum WorldIDVerificationState {
  idle,
  initializing,
  awaitingUserAction,
  verifying,
  verified,
  failed,
}
