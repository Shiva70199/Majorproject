# OTP Email Configuration Guide

## Overview
The app uses the `email_auth` package to send OTP codes for email verification during registration. You need to configure SMTP settings for this to work.

## Configuration Steps

### Option 1: Using Gmail SMTP (Recommended for Development)

1. **Enable 2-Step Verification** on your Gmail account
2. **Generate an App Password**:
   - Go to Google Account settings
   - Security → 2-Step Verification → App passwords
   - Generate a password for "Mail"
   - Copy the 16-character password

3. **Update `lib/services/otp_service.dart`**:
   ```dart
   OTPService() {
     _emailAuth = EmailAuth(
       sessionName: "SafeDocs Verification",
     );
     
     // Configure SMTP settings
     _emailAuth.config(
       remoteServerConfiguration: {
         "server": "smtp.gmail.com",
         "serverPort": 587,
         "email": "your-email@gmail.com",
         "password": "your-app-password", // 16-character app password
       },
     );
   }
   ```

### Option 2: Using Other SMTP Providers

For other email providers (Outlook, Yahoo, custom SMTP), update the configuration:

```dart
_emailAuth.config(
  remoteServerConfiguration: {
    "server": "smtp.your-provider.com",
    "serverPort": 587, // or 465 for SSL
    "email": "your-email@domain.com",
    "password": "your-password",
  },
);
```

### Option 3: Using Firebase Extensions (Production)

For production, consider using Firebase Extensions:
- **Firebase Email Extension**: Automatically sends emails via Firebase
- **SendGrid Extension**: Professional email delivery service

## Testing

After configuration:
1. Try registering a new user
2. Check the email inbox for the OTP code
3. Enter the OTP to complete registration

## Troubleshooting

- **OTP not received**: Check spam folder, verify SMTP credentials
- **Connection timeout**: Check firewall/network settings
- **Authentication failed**: Verify email and password are correct

## Security Notes

- Never commit SMTP credentials to version control
- Use environment variables or secure storage for production
- Consider using a dedicated email service for production (SendGrid, AWS SES, etc.)

