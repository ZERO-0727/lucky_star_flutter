/**
 * World ID Utility Functions
 */
import {WorldIDConfig, WorldIDVerificationResponse, VerificationRequest} from '../types/worldid';
import fetch from 'node-fetch';

/**
 * Get World ID configuration from environment variables
 */
export function getWorldIDConfig(): WorldIDConfig {
  const appId = process.env.WORLD_ID_APP_ID;
  const apiKey = process.env.WORLD_ID_API_KEY;
  const verificationLevel = (process.env.WORLD_ID_VERIFICATION_LEVEL || 'orb') as 'orb' | 'device' | 'phone';
  const baseUrl = process.env.WORLD_ID_API_BASE_URL || 'https://developer.worldcoin.org/api/v1';

  if (!appId || !apiKey) {
    throw new Error('World ID configuration missing. Please set WORLD_ID_APP_ID and WORLD_ID_API_KEY environment variables.');
  }

  return {
    appId,
    apiKey,
    verificationLevel,
    baseUrl,
  };
}

/**
 * Generate a unique signal for verification
 */
export function generateSignal(userId: string, action: string): string {
  const timestamp = Date.now();
  const randomSalt = Math.random().toString(36).substring(2, 15);
  return `${userId}:${action}:${timestamp}:${randomSalt}`;
}

/**
 * Verify World ID proof with Worldcoin API
 */
export async function verifyWorldIDProof(
  proof: VerificationRequest,
  config: WorldIDConfig
): Promise<WorldIDVerificationResponse> {
  try {
    const response = await fetch(`${config.baseUrl}/verify/${config.appId}`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${config.apiKey}`,
      },
      body: JSON.stringify({
        nullifier_hash: proof.nullifier_hash,
        merkle_root: proof.merkle_root,
        proof: proof.proof,
        verification_level: proof.verification_level,
        signal: proof.signal,
      }),
    });

    if (!response.ok) {
      const errorData = await response.json();
      console.error('World ID verification failed:', errorData);
      return {
        success: false,
        detail: errorData.detail || 'Verification failed',
        code: errorData.code || 'VERIFICATION_ERROR',
      };
    }

    const data = await response.json();
    return {
      success: true,
      ...data,
    };
  } catch (error) {
    console.error('Error verifying World ID proof:', error);
    return {
      success: false,
      detail: 'Network error during verification',
      code: 'NETWORK_ERROR',
    };
  }
}

/**
 * Generate World ID verification URL for mobile app
 */
export function generateWorldIDVerificationUrl(
  appId: string,
  signal: string,
  action: string = 'verify'
): string {
  const params = new URLSearchParams({
    app_id: appId,
    signal,
    action,
  });

  return `https://worldcoin.org/verify?${params.toString()}`;
}

/**
 * Validate nullifier hash format
 */
export function validateNullifierHash(nullifierHash: string): boolean {
  // Nullifier hash should be a 64-character hexadecimal string
  const nullifierRegex = /^[0-9a-fA-F]{64}$/;
  return nullifierRegex.test(nullifierHash);
}

/**
 * Validate proof format
 */
export function validateProof(proof: string): boolean {
  try {
    // Basic validation - proof should be a valid JSON string or hex string
    if (proof.startsWith('{') && proof.endsWith('}')) {
      JSON.parse(proof);
      return true;
    }
    // Check if it's a valid hex string
    return /^[0-9a-fA-F]+$/.test(proof) && proof.length > 0;
  } catch {
    return false;
  }
}

/**
 * Get trust score boost amount from environment
 */
export function getTrustScoreBoost(): number {
  const boost = process.env.TRUST_SCORE_BOOST;
  return boost ? parseInt(boost, 10) : 50;
}

/**
 * Get verification badge name from environment
 */
export function getVerificationBadgeName(): string {
  return process.env.VERIFICATION_BADGE_NAME || 'World ID Verified';
}
