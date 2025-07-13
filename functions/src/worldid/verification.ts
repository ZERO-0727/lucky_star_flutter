/**
 * World ID Verification Functions
 */
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import cors from "cors";
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

const corsHandler = cors({origin: true});
const db = admin.firestore();

/**
 * Initialize World ID Verification
 * Generates verification parameters and returns verification URL
 */
export const initWorldIDVerification = functions.https.onCall(async (data: any, context: any) => {
  console.log("🚀 initWorldIDVerification function started");
  console.log("Request data:", data);
  console.log("Context:", context);
  
  // Debug environment variables
  console.log("🔍 Environment variables:");
  console.log("- WORLD_ID_APP_ID:", process.env.WORLD_ID_APP_ID ? "SET" : "NOT SET");
  console.log("- WORLD_ID_API_KEY:", process.env.WORLD_ID_API_KEY ? "SET" : "NOT SET");
  console.log("- WORLD_ID_ACTION:", process.env.WORLD_ID_ACTION || "NOT SET");
  
  try {
    // Check if user is authenticated
    if (!context.auth) {
      console.log("❌ User not authenticated");
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
    }

    const userId = context.auth.uid;
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
export const verifyWorldIDProof = functions.https.onRequest(async (req, res) => {
  return corsHandler(req, res, async () => {
    console.log("🔍 verifyWorldIDProof function started");
    console.log("Request method:", req.method);
    console.log("Request body:", req.body);
    
    try {
      // Only allow POST requests
      if (req.method !== "POST") {
        console.log("❌ Method not allowed:", req.method);
        res.status(405).json({error: "Method not allowed"});
        return;
      }

      // Verify Firebase Auth token
      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith("Bearer ")) {
        res.status(401).json({error: "Unauthorized"});
        return;
      }

      const idToken = authHeader.split("Bearer ")[1];
      let decodedToken;
      try {
        decodedToken = await admin.auth().verifyIdToken(idToken);
      } catch (error) {
        console.error("Error verifying auth token:", error);
        res.status(401).json({error: "Invalid auth token"});
        return;
      }

      const userId = decodedToken.uid;
      const {
        nullifier_hash,
        merkle_root,
        proof,
        verification_level,
        signal,
      } = req.body as VerifyProofRequest;

      // Validate required fields
      if (!nullifier_hash || !merkle_root || !proof || !verification_level || !signal) {
        res.status(400).json({
          success: false,
          error: "Missing required fields",
        });
        return;
      }

      // Validate proof format
      if (!validateNullifierHash(nullifier_hash) || !validateProof(proof)) {
        res.status(400).json({
          success: false,
          error: "Invalid proof format",
        });
        return;
      }

      // Check if user is already verified
      const userDoc = await db.collection("users").doc(userId).get();
      if (userDoc.exists && userDoc.data()?.isVerified) {
        res.status(400).json({
          success: false,
          error: "User is already verified",
        });
        return;
      }

      // Check verification session
      const sessionDoc = await db.collection("worldid_sessions").doc(userId).get();
      if (!sessionDoc.exists || sessionDoc.data()?.signal !== signal) {
        res.status(400).json({
          success: false,
          error: "Invalid verification session",
        });
        return;
      }

      // Check if nullifier hash has been used before
      const nullifierQuery = await db
        .collection("world_id_nullifiers")
        .where("nullifierHash", "==", nullifier_hash)
        .get();

      if (!nullifierQuery.empty) {
        res.status(400).json({
          success: false,
          error: "This World ID has already been used for verification",
        });
        return;
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
        res.status(400).json({
          success: false,
          verified: false,
          error: verificationResult.detail || "Verification failed",
        });
        return;
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

      res.status(200).json(response);
    } catch (error) {
      console.error("Error in verifyWorldIDProof:", error);
      res.status(500).json({
        success: false,
        verified: false,
        error: "Internal server error",
      });
    }
  });
});

/**
 * Get World ID Verification Status
 * Returns the current verification status for a user
 */
export const getWorldIDVerificationStatus = functions.https.onRequest(async (req, res) => {
  return corsHandler(req, res, async () => {
    try {
      // Only allow GET requests
      if (req.method !== "GET") {
        res.status(405).json({error: "Method not allowed"});
        return;
      }

      // Verify Firebase Auth token
      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith("Bearer ")) {
        res.status(401).json({error: "Unauthorized"});
        return;
      }

      const idToken = authHeader.split("Bearer ")[1];
      let decodedToken;
      try {
        decodedToken = await admin.auth().verifyIdToken(idToken);
      } catch (error) {
        console.error("Error verifying auth token:", error);
        res.status(401).json({error: "Invalid auth token"});
        return;
      }

      const userId = decodedToken.uid;

      // Get user document
      const userDoc = await db.collection("users").doc(userId).get();
      if (!userDoc.exists) {
        res.status(404).json({error: "User not found"});
        return;
      }

      const userData = userDoc.data()!;
      const worldIdVerification = userData.worldIdVerification || {};

      res.status(200).json({
        success: true,
        isVerified: userData.isVerified || false,
        verificationMethod: worldIdVerification.verificationLevel || null,
        verifiedAt: worldIdVerification.verifiedAt || null,
        trustScore: userData.trustScore || 0,
        verificationBadges: userData.verificationBadges || [],
      });
    } catch (error) {
      console.error("Error in getWorldIDVerificationStatus:", error);
      res.status(500).json({
        success: false,
        error: "Internal server error",
      });
    }
  });
});
