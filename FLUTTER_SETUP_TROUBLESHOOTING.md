# Flutter Setup Troubleshooting Guide

## Issue: `flutter run` command not found

This means Flutter is either:
1. Not installed on your system
2. Installed but not added to your system PATH

---

## Solution 1: Install Flutter (If Not Installed)

### Step 1: Download Flutter
1. Go to https://docs.flutter.dev/get-started/install/windows
2. Download the Flutter SDK zip file
3. Extract it to a location like `C:\flutter` (avoid spaces in path)

### Step 2: Add Flutter to PATH
1. **Open System Environment Variables**:
   - Press `Win + R`, type `sysdm.cpl`, press Enter
   - Click "Advanced" tab → "Environment Variables"

2. **Edit PATH variable**:
   - Under "User variables", find "Path" and click "Edit"
   - Click "New" and add: `C:\flutter\bin` (or wherever you extracted Flutter)
   - Click "OK" on all dialogs

3. **Restart your terminal/IDE** (or restart computer)

4. **Verify installation**:
   ```powershell
   flutter --version
   flutter doctor
   ```

---

## Solution 2: Use Flutter from Full Path (Temporary Fix)

If Flutter is installed but not in PATH, you can use the full path:

```powershell
# Replace with your actual Flutter path
C:\flutter\bin\flutter.bat run
```

Or find your Flutter installation:
```powershell
# Search for flutter.bat
Get-ChildItem -Path "C:\" -Recurse -Filter "flutter.bat" -ErrorAction SilentlyContinue | Select-Object -First 1 FullName
```

---

## Solution 3: Use IDE to Run (Easiest)

### Option A: VS Code
1. Install "Flutter" extension in VS Code
2. Open your project folder
3. Press `F5` or click "Run" button
4. VS Code will automatically find Flutter if installed

### Option B: Android Studio
1. Install Flutter plugin in Android Studio
2. Open your project
3. Click the green "Run" button
4. Android Studio will handle Flutter automatically

### Option C: Use Android Studio's Terminal
1. Open Android Studio
2. Go to View → Tool Windows → Terminal
3. The terminal in Android Studio usually has Flutter in PATH
4. Run `flutter run` from there

---

## Solution 4: Check if Flutter is Installed via Other Tools

### Check Android Studio
If you have Android Studio installed, Flutter might be bundled:
```powershell
# Check Android Studio's Flutter
Test-Path "$env:LOCALAPPDATA\Android\flutter\bin\flutter.bat"
```

### Check Common Installation Paths
```powershell
# Check various common paths
$paths = @(
    "$env:LOCALAPPDATA\flutter\bin\flutter.bat",
    "C:\flutter\bin\flutter.bat",
    "C:\src\flutter\bin\flutter.bat",
    "$env:USERPROFILE\flutter\bin\flutter.bat",
    "$env:ProgramFiles\flutter\bin\flutter.bat"
)

foreach ($path in $paths) {
    if (Test-Path $path) {
        Write-Host "Found Flutter at: $path"
        break
    }
}
```

---

## Quick Fix: Add Flutter to PATH in Current Session

If you know where Flutter is installed, you can temporarily add it to PATH for this session:

```powershell
# Replace C:\flutter\bin with your actual Flutter path
$env:Path += ";C:\flutter\bin"
flutter --version
```

---

## Verify Flutter Installation

Once Flutter is accessible, run:

```powershell
flutter doctor
```

This will show:
- ✅ What's working
- ❌ What needs to be fixed
- 📋 What dependencies are missing

Common issues:
- **Android toolchain**: Install Android Studio
- **VS Code**: Install Flutter extension
- **Android licenses**: Run `flutter doctor --android-licenses`

---

## After Flutter is Working

1. **Get dependencies**:
   ```powershell
   flutter pub get
   ```

2. **Check for devices**:
   ```powershell
   flutter devices
   ```

3. **Run the app**:
   ```powershell
   flutter run
   ```

---

## Alternative: Use VS Code Tasks

If you're using VS Code, you can create a task to run Flutter:

1. Create `.vscode/tasks.json`:
```json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "flutter run",
            "type": "shell",
            "command": "flutter",
            "args": ["run"],
            "problemMatcher": []
        }
    ]
}
```

2. Press `Ctrl+Shift+P` → "Tasks: Run Task" → "flutter run"

---

## Still Having Issues?

1. **Check Flutter installation guide**: https://docs.flutter.dev/get-started/install/windows
2. **Verify system requirements**: Windows 10 or later, 64-bit
3. **Check antivirus**: Some antivirus software blocks Flutter
4. **Restart your computer** after adding Flutter to PATH

---

## Quick Test Commands

```powershell
# Test if Flutter is accessible
flutter --version

# Check Flutter installation
flutter doctor -v

# Get project dependencies
flutter pub get

# List available devices
flutter devices

# Run on connected device
flutter run
```

---

**Note**: The easiest solution is usually to use VS Code or Android Studio's built-in Flutter support, which handles PATH automatically.

