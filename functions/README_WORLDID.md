# World ID Firebase Functions Setup

This document provides step-by-step instructions for configuring and deploying Firebase Functions for World ID verification.

## Overview

The World ID integration consists of:
- **Backend**: Firebase Functions that handle World ID verification logic
- **Frontend**: Flutter service that communicates with the functions
- **Security**: Environment-based configuration and nullifier hash tracking

## World ID Configuration Requirements

Before deployment, you need to obtain the following from [Worldcoin Developer Portal](https://developer.worldcoin.org/):

### Required Environment Variables

```bash
# World ID Configuration
WORLD_ID_APP_ID=app_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
WORLD_ID_API_KEY=sk_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
WORLD_ID_VERIFICATION_LEVEL=orb  # Options: orb, device, phone
WORLD_ID_API_BASE_URL=https://developer.worldcoin.org/api/v1

# Trust Score Configuration
TRUST_SCORE_BOOST=50  # Points added when verified
VERIFICATION_BADGE_NAME=World ID Verified

# Optional: Custom action identifier
WORLD_ID_ACTION=verify_identity
```

## Setup Instructions

### 1. Install Dependencies

```bash
cd functions
npm install
```

### 2. Configure Environment Variables

#### For Development (Local Testing)
```bash
# In the functions directory
firebase functions:config:set \
  worldid.app_id="your_app_id" \
  worldid.api_key="your_api_key" \
  worldid.verification_level="orb" \
  worldid.api_base_url="https://developer.worldcoin.org/api/v1" \
  worldid.trust_score_boost="50" \
  worldid.verification_badge_name="World ID Verified"
```

#### For Production Deployment
Set environment variables using Firebase Functions configuration:

```bash
firebase functions:config:set \
  worldid.app_id="app_production_id" \
  worldid.api_key="sk_production_key" \
  worldid.verification_level="orb" \
  worldid.api_base_url="https://developer.worldcoin.org/api/v1" \
  worldid.trust_score_boost="50" \
  worldid.verification_badge_name="World ID Verified"
```

### 3. Update Environment Variable Access

Update the utility functions to read from Firebase config:

```typescript
// In functions/src/utils/worldid.ts
export function getWorldIDConfig(): WorldIDConfig {
  const config = functions.config();
  const appId = config.worldid?.app_id || process.env.WORLD_ID_APP_ID;
  const apiKey = config.worldid?.api_key || process.env.WORLD_ID_API_KEY;
  const verificationLevel = (config.worldid?.verification_level || process.env.WORLD_ID_VERIFICATION_LEVEL || 'orb') as 'orb' | 'device' | 'phone';
  const baseUrl = config.worldid?.api_base_url || process.env.WORLD_ID_API_BASE_URL || 'https://developer.worldcoin.org/api/v1';

  if (!appId || !apiKey) {
    throw new Error('World ID configuration missing. Please set worldid.app_id and worldid.api_key in Firebase config.');
  }

  return {
    appId,
    apiKey,
    verificationLevel,
    baseUrl,
  };
}
```

### 4. Build and Deploy Functions

```bash
# Build the functions
npm run build

# Deploy to Firebase
firebase deploy --only functions
```

## Firestore Security Rules

Add these rules to your `firestore.rules` file:

```javascript
// World ID verification sessions (temporary)
match /worldid_sessions/{userId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}

// World ID nullifier hashes (prevent reuse)
match /world_id_nullifiers/{nullifierId} {
  allow read: if request.auth != null;
  allow write: if false; // Only functions can write
}

// User verification status updates
match /users/{userId} {
  allow read: if request.auth != null;
  allow write: if request.auth != null && request.auth.uid == userId
    && (!('isVerified' in request.resource.data) 
        || resource == null 
        || !('isVerified' in resource.data) 
        || resource.data.isVerified == false); // Prevent downgrading verification
}
```

## Flutter App Configuration

### 1. Add Dependencies

Ensure these dependencies are in your `pubspec.yaml`:

```yaml
dependencies:
  cloud_functions: ^5.1.3
  url_launcher: ^6.2.6
```

### 2. Initialize Cloud Functions

In your `main.dart` or Firebase initialization:

```dart
import 'package:cloud_functions/cloud_functions.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // For local development with emulator
  if (kDebugMode) {
    FirebaseFunctions.instance.useFunctionsEmulator('localhost', 5001);
  }
  
  runApp(MyApp());
}
```

## Testing the Integration

### 1. Local Testing with Firebase Emulator

```bash
# Start the emulator
firebase emulators:start

# In another terminal, test the functions
curl -X POST http://localhost:5001/your-project/us-central1/initWorldIDVerification \
  -H "Authorization: Bearer YOUR_ID_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"action": "verify"}'
```

### 2. Production Testing

1. Deploy the functions
2. Open your Flutter app
3. Navigate to the verification page
4. Select "World ID Verification"
5. Complete the flow using the World ID app

## Security Considerations

### 1. Nullifier Hash Tracking
- Each World ID can only be used once
- Nullifier hashes are stored in Firestore to prevent reuse
- Failed verifications don't consume the nullifier

### 2. Session Management
- Verification sessions expire after a set time
- Sessions are tied to specific user IDs
- Signals are unique per session

### 3. API Key Security
- Never expose API keys in client-side code
- Use Firebase Functions configuration for production
- Rotate keys regularly

## Troubleshooting

### Common Issues

1. **"Configuration missing" error**
   - Check that environment variables are set correctly
   - Verify Firebase Functions configuration

2. **"Network error during verification"**
   - Check internet connectivity
   - Verify World ID API endpoint is accessible
   - Check API key validity

3. **"Nullifier already used" error**
   - Each World ID can only verify once
   - Check if user has already verified with this World ID

4. **Functions not deploying**
   - Check TypeScript compilation errors
   - Verify all dependencies are installed
   - Check Firebase project permissions

### Debug Logs

Enable debug logging in Firebase Functions:

```typescript
import { logger } from 'firebase-functions';

// Add to your functions
logger.info('World ID verification initiated', { userId });
logger.error('Verification failed', { error, userId });
```

View logs:
```bash
firebase functions:log
```

## API Endpoints

After deployment, your functions will be available at:

- `initWorldIDVerification` - Initialize verification process
- `verifyWorldIDProof` - Verify submitted proof
- `getWorldIDVerificationStatus` - Get user verification status

Base URL: `https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net/`

## Support

For World ID specific issues:
- [World ID Documentation](https://docs.worldcoin.org/)
- [World ID Developer Portal](https://developer.worldcoin.org/)

For Firebase Functions issues:
- [Firebase Functions Documentation](https://firebase.google.com/docs/functions)
