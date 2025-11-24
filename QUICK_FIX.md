# Quick Fix for Flutter Run Issues

## Most Common Fixes (Try These First!)

### 1. Clean and Rebuild
```powershell
flutter clean
flutter pub get
flutter run
```

### 2. Check for Devices
```powershell
flutter devices
```
If no devices, start an emulator or connect a physical device.

### 3. Remove Firebase Conflicts (Already Fixed!)
✅ I've removed Firebase configuration from Android build files that was conflicting with Supabase.

### 4. Verify Dependencies
```powershell
flutter pub get
```

### 5. Run with Specific Device
```powershell
# For web
flutter run -d chrome

# For Windows desktop
flutter run -d windows

# For Android (if emulator running)
flutter run -d android
```

---

## If Still Not Working

### Get Detailed Error
```powershell
flutter run -v
```
This shows the exact error message. Share it for more specific help.

### Common Error Messages

**"No devices found"**
- Solution: Start Android emulator or connect device
- Or use: `flutter run -d chrome` for web

**"Gradle build failed"**
- Solution: 
  ```powershell
  cd android
  gradlew clean
  cd ..
  flutter clean
  flutter pub get
  flutter run
  ```

**"Package not found"**
- Solution:
  ```powershell
  flutter pub get
  ```

**"Supabase initialization failed"**
- Check: `lib/main.dart` - verify Supabase keys are correct
- Check: Internet connection

---

## Next Steps

1. Try `flutter clean && flutter pub get && flutter run`
2. If error persists, run `flutter run -v` and share the error
3. Check `FLUTTER_RUN_TROUBLESHOOTING.md` for detailed solutions

