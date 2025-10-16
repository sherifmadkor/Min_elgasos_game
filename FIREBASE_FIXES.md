# 🔧 Firebase Configuration Fixes

## 🚨 IMMEDIATE ACTIONS REQUIRED

### 1. Update Firestore Security Rules
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **min-el-gasos**
3. Navigate to **Firestore Database** → **Rules**
4. **Replace** existing rules with content from `firestore_security_rules.txt`
5. Click **Publish**

### 2. Create Required Firestore Indexes
You need to create composite indexes for the room queries to work properly.

#### Method 1: Automatic (Recommended)
1. Run the app and try to browse rooms
2. Check the console/logs for an error message with a link
3. Click the link - it will take you directly to Firebase Console
4. Click "Create Index" button

#### Method 2: Manual Creation
Go to **Firestore Database** → **Indexes** → **Add Index**

**Index 1: For Public Rooms**
- Collection: `gameRooms`
- Fields:
  - `type` (Ascending)
  - `status` (Ascending)  
  - `createdAt` (Descending)
- Query scope: Collection

**Index 2: For Room Cleanup**
- Collection: `gameRooms`
- Fields:
  - `status` (Ascending)
  - `createdAt` (Ascending)
- Query scope: Collection

**Index 3: For Rate Limiting**
- Collection: `gameRooms`
- Fields:
  - `hostId` (Ascending)
  - `createdAt` (Descending)
- Query scope: Collection

### 3. Initialize Required Collections
Run these commands in Firestore Console or use the Firebase Admin SDK:

```javascript
// In Firebase Console → Firestore → Start Collection

// 1. Create a test user (optional, for testing)
db.collection('users').doc('test-user-id').set({
  displayName: 'Test User',
  avatarEmoji: '🕵️‍♂️',
  rank: 'Iron',
  xp: 0,
  stats: {
    gamesPlayed: 0,
    wins: 0,
    losses: 0,
    spyWins: 0,
    detectiveWins: 0,
    winStreak: 0,
    winRate: '0.0'
  },
  createdAt: firebase.firestore.FieldValue.serverTimestamp()
});
```

## 🛡️ Security Improvements Implemented

### ✅ Input Validation
- Room names: 2-50 characters, alphanumeric only
- Display names: 2-30 characters
- Message length: Max 500 characters
- Profanity filtering
- XSS prevention through input sanitization

### ✅ Rate Limiting
- 30-second cooldown between room creations
- Maximum 3 active rooms per user
- Automatic cleanup of abandoned rooms (2+ hours old)

### ✅ Firestore Security Rules
- Authentication required for all operations
- User can only modify their own profile
- XP and stats protected from client manipulation
- Room creation validated server-side
- Message length and content validation

### ✅ Data Validation
- Player count: 3-10 players
- Spy count: 1 to (players-1)
- Game duration: 1-15 minutes
- Room codes: 4-digit numeric only

## 🐛 Fixed Issues

### Room Visibility Problem
**Issue**: Rooms weren't showing in the browser
**Solution**: 
- Added proper Firestore indexes
- Fixed timestamp handling (using FieldValue.serverTimestamp())
- Added error handling for missing/malformed data
- Improved query error logging

### Permission Denied Errors
**Issue**: Users couldn't create rooms
**Solution**:
- Updated security rules to allow authenticated users
- Added proper field validation
- Fixed timestamp comparison in rules

## 📝 Testing Checklist

After applying these fixes, test the following:

- [ ] User can create account
- [ ] User can login successfully
- [ ] User can create a public room
- [ ] Public room appears in room browser
- [ ] User can create a private room
- [ ] Private room generates 4-digit code
- [ ] Other users can join public room
- [ ] Other users can join private room with code
- [ ] Room shows correct player count
- [ ] Host can start game
- [ ] Rate limiting prevents spam (30s cooldown)
- [ ] Invalid room names are rejected
- [ ] Profanity in room names is blocked
- [ ] Old rooms are automatically cleaned up

## 🔍 Monitoring

Check Firebase Console for:
1. **Firestore Usage**: Monitor read/write operations
2. **Error Logs**: Check Functions logs for errors
3. **Security Rules**: Monitor denied operations
4. **Performance**: Check slow queries

## 📱 Client-Side Updates Required

The app will now show better error messages:
- Rate limiting warnings
- Input validation errors
- Connection issues
- Permission errors

## 🚀 Next Steps

1. Deploy security rules immediately
2. Create required indexes
3. Test room creation and joining
4. Monitor Firebase Console for any errors
5. Consider adding:
   - Email verification requirement
   - CAPTCHA for room creation
   - IP-based rate limiting
   - Report/ban system for abusive users

## ⚠️ Important Notes

- **Never** disable security rules for testing
- Always test with multiple user accounts
- Monitor Firebase billing (indexes may increase costs)
- Regularly audit security rules
- Keep Firebase SDK updated