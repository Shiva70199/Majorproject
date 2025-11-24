# Quick Email Configuration Guide

## Step-by-Step Instructions

### Step 1: Get Gmail App Password

1. Go to your Google Account: https://myaccount.google.com/security
2. Enable **2-Step Verification** (if not already enabled)
3. Go to **App passwords**: https://myaccount.google.com/apppasswords
4. Select:
   - **App**: Mail
   - **Device**: Other (Custom name) - type "SafeDocs App"
5. Click **Generate**
6. Copy the 16-character password (it will look like: `abcd efgh ijkl mnop`)

### Step 2: Configure Email Settings

1. Open `lib/config/email_config.dart` in your project
2. On **line 41**, replace `'your-email@gmail.com'` with your actual Gmail address
   - Example: `static const String smtpEmail = 'myemail@gmail.com';`
3. On **line 42**, replace `'your-app-password'` with the 16-character app password you copied
   - Example: `static const String smtpPassword = 'abcdefghijklmnop';`
   - **Important**: Remove any spaces from the password (it should be 16 characters without spaces)
4. On **line 61**, change `isConfigured = false` to `isConfigured = true`

### Example Configuration

After configuration, your file should look like this:

```dart
static const String smtpServer = 'smtp.gmail.com';
static const int smtpPort = 587;
static const String smtpEmail = 'myemail@gmail.com'; // Your Gmail
static const String smtpPassword = 'abcdefghijklmnop'; // Your app password (16 chars)
...
static const bool isConfigured = true; // Changed to true
```

### Step 3: Test

1. Save the file
2. Restart your app
3. Try signing up as a new student
4. You should receive an OTP email at the email address you entered

## Important Notes

- **The Gmail account is just for sending emails** - students will receive OTP at their own email addresses
- **Use App Password, NOT your regular Gmail password** - this is required for security
- **Students enter their own email** during signup, and OTP will be sent to that email

## Troubleshooting

- **"Invalid credentials"**: Check that you're using the App Password, not your regular password
- **"Connection failed"**: Make sure 2-Step Verification is enabled
- **No email received**: Check spam folder, verify the student's email is correct

