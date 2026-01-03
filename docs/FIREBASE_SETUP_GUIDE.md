# Firebase Setup Guide

## Package Name
Your Android package name is: `com.example.kantin_app`

## Step-by-Step Firebase Setup

### 1. Create Firebase Project
1. Go to https://console.firebase.google.com
2. Click "Add project" or "Create a project"
3. Enter project name (e.g., "Kantin App")
4. Accept terms and click "Continue"
5. (Optional) Enable Google Analytics
6. Click "Create project"

### 2. Add Android App to Firebase
1. In Firebase Console, click the Android icon to add Android app
2. **Android package name**: `com.example.kantin_app` (IMPORTANT: Copy this exactly!)
3. **App nickname** (optional): Kantin App
4. **Debug signing certificate SHA-1** (optional for now): Leave blank
5. Click "Register app"

### 3. Download google-services.json
1. Click "Download google-services.json"
2. **IMPORTANT**: Place this file in `c:\PML_7-1\android\app\` directory
3. Do NOT rename the file
4. Click "Next"

### 4. Add Firebase SDK (Already Done!)
✅ Dependencies already added to `pubspec.yaml`
✅ Google Services plugin already added to `android/app/build.gradle.kts`
✅ Plugin version already added to `android/settings.gradle.kts`

### 5. Verification
1. Place `google-services.json` in `android/app/` folder
2. Run `flutter clean`
3. Run `flutter pub get`
4. Try running the app

## What's Next?
After you place `google-services.json` file, I will continue implementing:
- FCM Service layer
- Notification handlers
- User model updates
- UI components

## Need Help?
If you have trouble with Firebase setup, let me know which step you're stuck on!
