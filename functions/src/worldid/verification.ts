/**
 * World ID Verification Functions
 */
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import {
  InitVerificationResponse,
  VerifyProofRequest,
  VerifyProofResponse,
  VerificationRequest,
  NullifierRecord,
} from "../types/worldid";
import {
  getWorldIDConfig,
  getWorldIDAction,
  generateSignal,
  verifyWorldIDProof as verifyProofWithAPI,
  generateWorldIDVerificationUrl,
  validateNullifierHash,
  validateProof,
  getTrustScoreBoost,
  getVerificationBadgeName,
} from "../utils/worldid";

// Initialize Firebase Admin SDK
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Initialize World ID Verification
 * Generates verification parameters and returns verification URL
 */
export const initWorldIDVerification = functions.https.onCall(async (request: functions.https.CallableRequest) => {
  console.log("🚀 initWorldIDVerification function started");
  console.log("Request data:", request.data);
  console.log("Context:", request);
  
  // Debug environment variables
  console.log("🔍 Environment variables:");
  console.log("- WORLD_ID_APP_ID:", process.env.WORLD_ID_APP_ID ? "SET" : "NOT SET");
  console.log("- WORLD_ID_API_KEY:", process.env.WORLD_ID_API_KEY ? "SET" : "NOT SET");
  console.log("- WORLD_ID_ACTION:", process.env.WORLD_ID_ACTION || "NOT SET");
  
  try {
    // Check if user is authenticated
    if (!request.auth) {
      console.log("❌ User not authenticated");
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const userId = request.auth.uid;
    console.log("✅ User authenticated:", userId);

    // Use custom action from environment variable
    const action = getWorldIDAction();
    console.log("🎯 Action:", action);

    // Check if user is already verified
    console.log("📋 Checking if user is already verified...");
    const userDoc = await db.collection("users").doc(userId).get();
    if (userDoc.exists && userDoc.data()?.isVerified) {
      console.log("❌ User is already verified");
      throw new functions.https.HttpsError('failed-precondition', 'User is already verified with World ID');
    }
    console.log("✅ User is not yet verified");

    // Get World ID configuration
    console.log("⚙️ Getting World ID configuration...");
    const config = getWorldIDConfig();
    console.log("✅ World ID config loaded:", {
      appId: config.appId.substring(0, 8) + "...",
      hasApiKey: !!config.apiKey,
      verificationLevel: config.verificationLevel,
      baseUrl: config.baseUrl
    });

    // Generate unique signal for this verification
    const signal = generateSignal(userId, action);
    console.log("🔗 Generated signal:", signal.substring(0, 20) + "...");

    // Generate verification URL
    const verificationUrl = generateWorldIDVerificationUrl(config.appId, signal, action);
    console.log("🌐 Generated verification URL:", verificationUrl.substring(0, 50) + "...");

    // Store verification session
    console.log("💾 Storing verification session...");
    await db.collection("worldid_sessions").doc(userId).set({
      signal,
      action,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt: admin.firestore.FieldValue.serverTimestamp(),
      verified: false,
    });
    console.log("✅ Verification session stored");

    const response: InitVerificationResponse = {
      success: true,
      verificationUrl,
      signal,
    };

    console.log("🎉 initWorldIDVerification completed successfully");
    return response;
  } catch (error) {
    console.error("💥 Unexpected error in initWorldIDVerification:", error);
    console.error("Error stack:", error instanceof Error ? error.stack : "No stack trace");
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', 'Internal server error', {
      details: error instanceof Error ? error.message : "Unknown error"
    });
  }
});

/**
 * Verify World ID Proof
 * Validates the proof from World ID and updates user verification status
 */
export const verifyWorldIDProof = functions.https.onCall(async (request: functions.https.CallableRequest) => {
  console.log("🔍 verifyWorldIDProof function started");
  console.log("Request data:", request.data);
  
  try {
    // Check if user is authenticated
    if (!request.auth) {
      console.log("❌ User not authenticated");
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const userId = request.auth.uid;
    const {
      nullifier_hash,
      merkle_root,
      proof,
      verification_level,
      signal,
    } = request.data as VerifyProofRequest;

    // Validate required fields
    if (!nullifier_hash || !merkle_root || !proof || !verification_level || !signal) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
    }

    // Validate proof format
    if (!validateNullifierHash(nullifier_hash) || !validateProof(proof)) {
      throw new functions.https.HttpsError('invalid-argument', 'Invalid proof format');
    }

    // Check if user is already verified
    const userDoc = await db.collection("users").doc(userId).get();
    if (userDoc.exists && userDoc.data()?.isVerified) {
      throw new functions.https.HttpsError('failed-precondition', 'User is already verified');
    }

    // Check verification session
    const sessionDoc = await db.collection("worldid_sessions").doc(userId).get();
    if (!sessionDoc.exists || sessionDoc.data()?.signal !== signal) {
      throw new functions.https.HttpsError('invalid-argument', 'Invalid verification session');
    }

    // Check if nullifier hash has been used before
    const nullifierQuery = await db
      .collection("world_id_nullifiers")
      .where("nullifierHash", "==", nullifier_hash)
      .get();

    if (!nullifierQuery.empty) {
      throw new functions.https.HttpsError('invalid-argument', 'This World ID has already been used for verification');
    }

    // Get World ID configuration
    const config = getWorldIDConfig();

    // Verify proof with World ID API
    const verificationRequest: VerificationRequest = {
      signal,
      nullifier_hash,
      merkle_root,
      proof,
      verification_level,
    };

    const verificationResult = await verifyProofWithAPI(verificationRequest, config);

    if (!verificationResult.success) {
      throw new functions.https.HttpsError('invalid-argument', verificationResult.detail || 'Verification failed');
    }

    // Get configuration values
    const trustScoreBoost = getTrustScoreBoost();
    const verificationBadge = getVerificationBadgeName();

    // Update user verification status
    const batch = db.batch();

    // Update user document
    const userRef = db.collection("users").doc(userId);
    const userData = userDoc.data() || {};
    const currentTrustScore = userData.trustScore || 0;
    const currentBadges = userData.verificationBadges || [];

    batch.update(userRef, {
      isVerified: true,
      trustScore: currentTrustScore + trustScoreBoost,
      verificationBadges: [...currentBadges, verificationBadge],
      worldIdVerification: {
        verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
        nullifierHash: nullifier_hash,
        verificationLevel: verification_level,
        trustScoreBoost,
      },
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Store nullifier hash to prevent reuse
    const nullifierRef = db.collection("world_id_nullifiers").doc();
    const nullifierRecord: NullifierRecord = {
      nullifierHash: nullifier_hash,
      userId,
      verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
      verificationLevel: verification_level,
    };
    batch.set(nullifierRef, nullifierRecord);

    // Update verification session
    const sessionRef = db.collection("worldid_sessions").doc(userId);
    batch.update(sessionRef, {
      verified: true,
      verifiedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Commit all updates
    await batch.commit();

    const response: VerifyProofResponse = {
      success: true,
      verified: true,
      trustScoreBoost,
      verificationBadge,
    };

    return response;
  } catch (error) {
    console.error("Error in verifyWorldIDProof:", error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', 'Internal server error', {
      details: error instanceof Error ? error.message : "Unknown error"
    });
  }
});

/**
 * Get World ID Verification Status
 * Returns the current verification status for a user
 */
export const getWorldIDVerificationStatus = functions.https.onCall(async (request: functions.https.CallableRequest) => {
  console.log("🔍 getWorldIDVerificationStatus function started");
  
  try {
    // Check if user is authenticated
    if (!request.auth) {
      console.log("❌ User not authenticated");
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const userId = request.auth.uid;

    // Get user document
    const userDoc = await db.collection("users").doc(userId).get();
    if (!userDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'User not found');
    }

    const userData = userDoc.data()!;
    const worldIdVerification = userData.worldIdVerification || {};

    return {
      success: true,
      isVerified: userData.isVerified || false,
      verificationMethod: worldIdVerification.verificationLevel || null,
      verifiedAt: worldIdVerification.verifiedAt || null,
      trustScore: userData.trustScore || 0,
      verificationBadges: userData.verificationBadges || [],
    };
  } catch (error) {
    console.error("Error in getWorldIDVerificationStatus:", error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError('internal', 'Internal server error', {
      details: error instanceof Error ? error.message : "Unknown error"
    });
  }
});
