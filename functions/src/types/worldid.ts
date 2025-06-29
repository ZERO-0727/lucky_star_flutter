/**
 * World ID TypeScript interfaces and types
 */

export interface WorldIDConfig {
  appId: string;
  apiKey: string;
  verificationLevel: "orb" | "device" | "phone";
  baseUrl: string;
}

export interface VerificationRequest {
  signal: string;
  nullifier_hash: string;
  merkle_root: string;
  proof: string;
  verification_level: string;
}

export interface WorldIDVerificationResponse {
  success: boolean;
  detail?: string;
  code?: string;
  attribute?: any;
}

export interface InitVerificationRequest {
  userId: string;
  action: string;
}

export interface InitVerificationResponse {
  success: boolean;
  verificationUrl?: string;
  signal?: string;
  error?: string;
}

export interface VerifyProofRequest {
  userId: string;
  nullifier_hash: string;
  merkle_root: string;
  proof: string;
  verification_level: string;
  signal: string;
}

export interface VerifyProofResponse {
  success: boolean;
  verified: boolean;
  trustScoreBoost: number;
  verificationBadge: string;
  error?: string;
}

export interface UserVerificationStatus {
  isVerified: boolean;
  verificationMethod: string;
  verifiedAt: any; // Firestore Timestamp
  nullifierHash: string;
  verificationLevel: string;
  trustScoreBoost: number;
}

export interface NullifierRecord {
  nullifierHash: string;
  userId: string;
  verifiedAt: any; // Firestore Timestamp
  verificationLevel: string;
}
