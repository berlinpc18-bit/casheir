# How to Run the Flutter App

This guide explains how to run the **Berlin Gaming Cashier** Flutter application on different platforms and environments.

## Table of Contents
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Running on Different Platforms](#running-on-different-platforms)
- [Troubleshooting](#troubleshooting)

---

## Prerequisites

Before running the app, ensure you have the following installed:

### 1. **Flutter SDK**
   - Download from: https://flutter.dev/docs/get-started/install
   - Add Flutter to your system PATH
   - Verify installation:
     ```bash
     flutter --version
     dart --version
     ```

### 2. **Git** (Optional, for version control)
   - Download from: https://git-scm.com/

### 3. **Platform-Specific Requirements**

#### For Windows Desktop:
- Visual Studio Community 2019+ or Visual Studio Build Tools
- Windows SDK

#### For Android:
- Android SDK (API level 21+)
- Android Virtual Device (AVD) or connected Android phone
- `adb` (Android Debug Bridge) installed

#### For iOS:
- Mac with macOS 10.15+
- Xcode 13.0+
- CocoaPods

#### For Web:
- No additional requirements (runs in any modern browser)

#### For Linux:
- GTK 3.0+, pkg-config

---

## Quick Start

### 1. **Navigate to the Project Directory**
```bash
cd c:\Users\HMa\cashier_app
```

### 2. **Get Dependencies**
```bash
flutter pub get
```

### 3. **Run the App**

**Default (Windows Desktop):**
```bash
flutter run
```

**Or use the provided batch files:**
```bash
تشغيل_التطبيق.bat
```

---

## Running on Different Platforms

### **Windows Desktop** (Recommended for Development)

#### Option 1: Using VS Code
1. Open the project in VS Code
2. Press `F5` to start debugging
3. Or press `Ctrl+F5` to run without debugging

#### Option 2: Using Terminal
```bash
flutter run -d windows
```

#### Option 3: Using the Provided Batch Script
```bash
تشغيل_التطبيق.bat
```

**Output:** The app will launch in a window showing the cashier interface.

---

### **Android**

#### Setup (One-time)
```bash
# Check connected devices
flutter devices

# Or create an Android Virtual Device (AVD) in Android Studio
```

#### Run on Device
```bash
flutter run -d android
```

#### Run in Release Mode (for distribution)
```bash
flutter build apk --release
```

Or use the prepared batch file:
```bash
build_smart_sync.bat
```

---

### **iOS** (macOS only)

#### Setup (One-time)
```bash
# Install pod dependencies
cd ios
pod install
cd ..
```

#### Run on Device/Simulator
```bash
flutter run -d ios
```

#### Build for Release
```bash
flutter build ios --release
```

---

### **Web**

#### Run in Debug Mode
```bash
flutter run -d chrome
```

#### Build for Production
```bash
flutter build web --release
```

The web app will be available in the `build/web/` directory.

---

### **Linux Desktop**

#### Run on Linux
```bash
flutter run -d linux
```

#### Build for Release
```bash
flutter build linux --release
```

---

## Useful Commands

### View Connected Devices
```bash
flutter devices
```

### Run in Debug Mode
```bash
flutter run
```

### Run in Release Mode (faster, no debugging)
```bash
flutter run --release
```

### Hot Reload During Development
Press `r` in the terminal while the app is running to reload changes instantly.

### Hot Restart
Press `R` in the terminal to restart the app (clears app state).

### Run with Specific Device
```bash
flutter run -d <device_id>
```

Example:
```bash
flutter run -d windows
flutter run -d android
```

### Clean Build (if experiencing issues)
```bash
flutter clean
flutter pub get
flutter run
```

### Build APK for Android
```bash
flutter build apk --release
```

### Analyze Code for Issues
```bash
flutter analyze
```

### Format Code
```bash
dart format .
```

---

## Troubleshooting

### Issue: "Flutter command not found"
**Solution:** Add Flutter to your system PATH
```bash
# Windows
set PATH=%PATH%;C:\path\to\flutter\bin
```

### Issue: "No connected devices"
**Solution:** 
- For Android: Enable USB Debugging on your phone and connect via USB
- For iOS: Connect an iPhone and trust the computer
- For Windows/Web: Should work automatically

### Issue: "Gradle build failed"
**Solution:**
```bash
flutter clean
flutter pub get
flutter run
```

### Issue: "Unable to locate Android SDK"
**Solution:** Set ANDROID_SDK_ROOT environment variable
```bash
set ANDROID_SDK_ROOT=C:\path\to\android\sdk
```

### Issue: "Dependency resolution failed"
**Solution:**
```bash
flutter pub get --offline
flutter pub cache repair
flutter pub get
```

### Issue: App crashes on startup
**Solution:** Check logs
```bash
flutter logs
```

---

## Development Workflow

### Using VS Code (Recommended)

1. **Install Flutter and Dart Extensions**
   - Search for "Flutter" and "Dart" in VS Code Extensions

2. **Open Project in VS Code**
   ```bash
   code c:\Users\HMa\cashier_app
   ```

3. **Start Debugging**
   - Press `F5` or go to Run > Start Debugging
   - Select your device/platform

4. **Edit Code**
   - Make changes to Dart files in the `lib/` directory

5. **Hot Reload**
   - Press `r` in terminal or use the reload button

---

## Performance Tips

1. **Use Release Mode for Testing Performance**
   ```bash
   flutter run --release
   ```

2. **Profile Your App**
   ```bash
   flutter run --profile
   ```

3. **Generate APK for Final Distribution**
   ```bash
   flutter build apk --release --split-per-abi
   ```

---

## Additional Resources

- **Official Flutter Docs:** https://flutter.dev/docs
- **Dart Language:** https://dart.dev/guides
- **Widget Gallery:** https://flutter.github.io/samples/

---

## Next Steps

After running the app successfully:

1. Explore the `lib/` directory to understand the app structure
2. Check the `SMART_SYNC_DOCUMENTATION.md` for feature details
3. Review `TECHNICAL_DOCUMENTATION.md` for architecture
4. See `SMART_SYNC_USER_GUIDE.md` for user features

---

**Last Updated:** February 2, 2026

**App Name:** Berlin Gaming Cashier (Cashier App)

**Version:** 1.0.0
