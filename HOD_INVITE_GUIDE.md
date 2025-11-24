# HOD Invite Guide

## How HODs Get Password Setting Links

### Overview
HODs (Head of Department) receive password reset links via email to set their passwords. The system automatically handles account creation if needed.

### Step-by-Step Process

#### 1. **Configure HOD Emails**
Edit `lib/config/hod_config.dart` and add HOD email addresses:
```dart
static const List<String> allowedHodEmails = [
  'hod@college.edu',
  'head.department@university.edu',
  // Add more HOD emails here
];
```

#### 2. **Send Invite to HOD**
There are two ways to send invites:

**Option A: Using the App (Recommended)**
1. Open the app
2. On the login screen, click **"Invite HOD"** button (at the bottom)
3. You'll see all configured HOD emails
4. Click the **send icon** next to an email to send invite to that HOD
5. Or click **"Send Invite to All HODs"** to send to all at once

**Option B: Using Firebase Console (Manual)**
1. Go to Firebase Console → Authentication
2. Click "Users" tab
3. If HOD account doesn't exist, you can create it manually
4. Click on the user → "Reset password" → Send reset email

#### 3. **What Happens When You Send Invite**

**If HOD account already exists:**
- Password reset link is sent to their email
- HOD clicks link → Sets new password → Can login

**If HOD account doesn't exist:**
- System creates account with temporary password
- Password reset link is sent to their email
- HOD clicks link → Sets their own password → Can login
- Profile is created automatically with HOD role when they first login

#### 4. **HOD Receives Email**
- HOD receives email from Firebase with subject: "Reset your password"
- Email contains a link to reset password
- Link expires after some time (Firebase default)

#### 5. **HOD Sets Password**
1. HOD clicks the link in email
2. Opens in browser
3. Enters new password
4. Password is set
5. HOD can now login to the app

#### 6. **HOD Logs In**
1. HOD opens app
2. Enters email and password
3. System automatically:
   - Creates profile in Supabase (if doesn't exist)
   - Assigns HOD role (based on email whitelist)
   - Shows HOD dashboard

### Accessing the Invite Screen

**From Login Screen:**
- Look for "Invite HOD" link at the bottom of the login screen
- Click it to open the HOD invite screen

**Direct Navigation:**
- You can navigate to `HodInviteScreen` from anywhere in the app

### Features of HOD Invite Screen

- ✅ Shows all configured HOD emails
- ✅ Send invite to individual HOD
- ✅ Send invite to all HODs at once
- ✅ Shows status (sent/failed) for each email
- ✅ Visual feedback with colors (green = success, red = failed)

### Important Notes

1. **Email Must Be in Whitelist**: Only emails in `hod_config.dart` can receive HOD invites
2. **Automatic Role Assignment**: When HOD logs in, they automatically get HOD role (no manual assignment needed)
3. **Profile Creation**: Profile is created automatically on first login with correct role
4. **Password Reset Links**: Links expire after some time (Firebase default), you can resend if needed

### Troubleshooting

**HOD didn't receive email:**
- Check spam folder
- Verify email is correct in `hod_config.dart`
- Try resending invite
- Check Firebase Console → Authentication → Users to see if account exists

**"Email not authorized" error:**
- Make sure email is added to `allowedHodEmails` in `hod_config.dart`
- Restart app after adding email

**Account creation fails:**
- Check Firebase Console for errors
- Verify email format is correct
- Make sure Firebase project is properly configured

### Code Files

- **HOD Config**: `lib/config/hod_config.dart` - Add HOD emails here
- **Invite Service**: `lib/services/hod_invite_service.dart` - Handles sending invites
- **Invite Screen**: `lib/screens/hod_invite_screen.dart` - UI for sending invites
- **Login Screen**: `lib/screens/login_screen.dart` - Has link to invite screen

