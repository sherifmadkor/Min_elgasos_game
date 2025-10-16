# Firebase Security Rules Setup Instructions

## 🚨 **URGENT: Fix Permission Denied Error**

Your app is failing to create rooms because Firebase Security Rules are blocking access. Follow these steps to fix it:

## Step 1: Access Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **min-el-gasos**
3. Navigate to **Firestore Database** in the left sidebar
4. Click on **Rules** tab

## Step 2: Update Security Rules
1. **Replace** the existing rules with the content from `firestore_rules.txt`
2. Click **Publish** to save the changes
3. Wait for the rules to propagate (usually takes a few seconds)

## Step 3: Test the App
1. Install the debug APK on your device
2. Try creating a room (both public and private)
3. Check if the creation succeeds

## Current Issue
The error logs show:
```
Status{code=PERMISSION_DENIED, description=Missing or insufficient permissions.}
```

This means your current Firebase rules are either:
- Set to deny all access (test mode expired)
- Too restrictive for authenticated users
- Missing rules for the required collections

## What These Rules Allow
✅ **Authenticated users** can:
- Read/write their own user documents in `/users/{userId}`
- Read/write any game room in `/gameRooms/{roomId}`
- Read/write room messages in `/gameRooms/{roomId}/messages/{messageId}`
- Access test collection for debugging

❌ **Unauthenticated users** are denied all access

## Security Features
- Users can only modify their own user profiles
- Any authenticated user can create/join game rooms (needed for multiplayer)
- Room messages are accessible to all authenticated users in that room
- All other collections are protected

## Alternative: Temporary Test Rules (NOT RECOMMENDED FOR PRODUCTION)
If you want to test quickly, you can use these temporary rules (REMOVE BEFORE PUBLISHING):

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

**⚠️ WARNING:** These temporary rules allow authenticated users to access ALL data. Only use for testing!

## After Updating Rules
Your app should work correctly and the debug logs should show:
```
✓ Read test PASSED
✓ Write test PASSED  
✓ GameRooms read test PASSED
✓ Room saved successfully
```