# Flutter Run Troubleshooting Guide

This guide helps you fix common issues when running `flutter run` for SafeDocs.

## Quick Diagnostic Steps

### Step 1: Check if Flutter is Installed
```powershell
flutter --version
```

**If this fails**: Flutter is not in your PATH. See "Flutter Not Found" section below.

### Step 2: Check Flutter Doctor
```powershell
flutter doctor
```

This shows what's missing or misconfigured.

### Step 3: Get Dependencies
```powershell
flutter pub get
```

### Step 4: Check for Connected Devices
```powershell
flutter devices
```

You need at least one device (emulator, physical device, or Chrome for web).

---

## Common Issues & Solutions

### Issue 1: "flutter: command not found" or "flutter is not recognized"

**Problem**: Flutter is not installed or not in PATH.

**Solution A: Install Flutter**
1. Download Flutter from: https://docs.flutter.dev/get-started/install/windows
2. Extract to `C:\flutter` (avoid spaces in path)
3. Add to PATH:
   - Press `Win + R`, type `sysdm.cpl`, press Enter
   - Advanced → Environment Variables
   - Edit "Path" under User variables
   - Add: `C:\flutter\bin`
   - Restart terminal/IDE

**Solution B: Use IDE (Easiest)**
- **VS Code**: Install "Flutter" extension, press `F5`
- **Android Studio**: Install Flutter plugin, click Run button

---

### Issue 2: "No devices found"

**Problem**: No emulator, physical device, or web browser available.

**Solutions**:

**Option A: Use Android Emulator**
```powershell
# List available emulators
flutter emulators

# Launch an emulator (replace with your emulator name)
flutter emulators --launch <emulator_id>

# Or use Android Studio:
# Tools → Device Manager → Create/Start emulator
```

**Option B: Use Physical Device**
1. Enable Developer Options on Android phone
2. Enable USB Debugging
3. Connect via USB
4. Run `flutter devices` to verify

**Option C: Run on Web**
```powershell
flutter run -d chrome
```

**Option D: Run on Windows Desktop**
```powershell
flutter run -d windows
```

---

### Issue 3: "Gradle build failed" or Android Build Errors

**Problem**: Android build configuration issues.

**Solutions**:

1. **Clean build**:
```powershell
cd android
gradlew clean
cd ..
flutter clean
flutter pub get
```

2. **Check Android SDK**:
```powershell
flutter doctor --android-licenses
# Accept all licenses
```

3. **Update Gradle** (if needed):
   - Check `android/gradle/wrapper/gradle-wrapper.properties`
   - Ensure Gradle version is compatible

4. **Check minSdkVersion**:
   - Open `android/app/build.gradle.kts`
   - Ensure `minSdkVersion` is at least 21 (required for flutter_secure_storage)

---

### Issue 4: "Package not found" or Dependency Errors

**Problem**: Dependencies not installed or version conflicts.

**Solutions**:

1. **Get dependencies**:
```powershell
flutter pub get
```

2. **Clean and reinstall**:
```powershell
flutter clean
flutter pub get
```

3. **Check pubspec.yaml**:
   - Ensure all dependencies are correctly listed
   - Check for typos in package names

4. **Update Flutter**:
```powershell
flutter upgrade
flutter pub get
```

---

### Issue 5: "Supabase initialization failed"

**Problem**: Invalid Supabase keys or network issues.

**Solutions**:

1. **Verify Supabase keys in `lib/main.dart`**:
   - Ensure URL is correct: `https://xxxxx.supabase.co`
   - Ensure anon key is correct (long JWT token)
   - No extra spaces or quotes

2. **Test Supabase connection**:
   - Go to Supabase dashboard
   - Check if project is active
   - Verify API keys in Settings → API

3. **Check internet connection**:
   - Supabase requires internet access
   - Check firewall/antivirus isn't blocking

---

### Issue 6: "PlatformException" or Native Code Errors

**Problem**: Platform-specific configuration issues.

**Solutions**:

**For Android**:
1. Check `android/app/build.gradle.kts`:
   - `minSdkVersion` should be 21+
   - `compileSdkVersion` should be 34+

2. Check `android/build.gradle.kts`:
   - Kotlin version compatibility

**For iOS** (if on Mac):
1. Run `pod install` in `ios/` directory
2. Open Xcode and check for errors

**For Windows**:
1. Ensure Visual Studio is installed with C++ tools
2. Run `flutter doctor` to check Windows toolchain

---

### Issue 7: "Out of memory" or Build Timeout

**Problem**: Insufficient resources or slow build.

**Solutions**:

1. **Increase Gradle memory**:
   - Edit `android/gradle.properties`:
   ```
   org.gradle.jvmargs=-Xmx4096m -XX:MaxMetaspaceSize=512m
   ```

2. **Close other applications**

3. **Use release mode** (faster):
```powershell
flutter run --release
```

---

### Issue 8: "Hot reload not working"

**Problem**: Hot reload issues (app runs but changes don't apply).

**Solutions**:

1. **Full restart**:
   - Press `R` in terminal (capital R)
   - Or stop and run again

2. **Check for errors**:
   - Look for red errors in terminal
   - Fix compilation errors first

---

## Step-by-Step Fix Process

If you're not sure what's wrong, follow these steps:

### Step 1: Verify Flutter Installation
```powershell
flutter doctor -v
```
Fix any issues shown (❌ or ⚠️).

### Step 2: Clean Everything
```powershell
flutter clean
flutter pub get
```

### Step 3: Check Dependencies
```powershell
flutter pub outdated
flutter pub upgrade
```

### Step 4: Verify Project Structure
- Ensure `lib/main.dart` exists
- Ensure `pubspec.yaml` is valid
- Check for syntax errors: `flutter analyze`

### Step 5: Try Running
```powershell
# List devices first
flutter devices

# Then run (replace with your device)
flutter run -d <device_id>
```

---

## Platform-Specific Commands

### Run on Specific Platform
```powershell
# Android
flutter run -d android

# iOS (Mac only)
flutter run -d ios

# Web
flutter run -d chrome

# Windows
flutter run -d windows

# Linux
flutter run -d linux
```

### Build for Release
```powershell
# Android APK
flutter build apk

# Android App Bundle
flutter build appbundle

# iOS (Mac only)
flutter build ios

# Web
flutter build web
```

---

## Quick Test Commands

Run these to diagnose:

```powershell
# 1. Check Flutter
flutter --version

# 2. Check setup
flutter doctor

# 3. Check devices
flutter devices

# 4. Analyze code
flutter analyze

# 5. Get dependencies
flutter pub get

# 6. Clean build
flutter clean

# 7. Try running
flutter run
```

---

## Still Not Working?

### Get More Information

1. **Run with verbose output**:
```powershell
flutter run -v
```
This shows detailed error messages.

2. **Check Flutter logs**:
```powershell
flutter logs
```

3. **Check specific platform logs**:
   - Android: `adb logcat` (if Android device connected)
   - Check IDE console for errors

### Common Error Messages

| Error | Solution |
|-------|----------|
| `Gradle task assembleDebug failed` | Clean build, check Android SDK |
| `No devices found` | Start emulator or connect device |
| `Package not found` | Run `flutter pub get` |
| `PlatformException` | Check platform-specific config |
| `Supabase initialization failed` | Verify Supabase keys |
| `Out of memory` | Increase Gradle memory |

---

## Recommended Setup

For best results:

1. **Use VS Code or Android Studio** (handles Flutter automatically)
2. **Install Flutter extension/plugin**
3. **Use Android Studio's emulator** (most reliable)
4. **Keep Flutter updated**: `flutter upgrade`

---

## Need More Help?

1. **Flutter Documentation**: https://docs.flutter.dev
2. **Flutter Community**: https://flutter.dev/community
3. **Stack Overflow**: Tag questions with `flutter`
4. **Check your specific error** in Flutter's GitHub issues

---

**Quick Fix Checklist**:
- [ ] Flutter installed and in PATH
- [ ] `flutter doctor` shows no critical issues
- [ ] `flutter pub get` completed successfully
- [ ] At least one device available (`flutter devices`)
- [ ] Supabase keys are correct in `lib/main.dart`
- [ ] No syntax errors (`flutter analyze`)

If all checked, try `flutter run` again!

