# CanakinRota - Quick Start Guide

✅ **All files have been copied!** The setup script has automatically copied all necessary files from CanakinCafe.

## Next Steps (Just 3 simple steps!)

### Step 1: Create Xcode Project

1. Open **Xcode**
2. **File** → **New** → **Project**
3. Choose **iOS** → **App**
4. Configure:
   - **Product Name**: `CanakinRota`
   - **Interface**: **SwiftUI**
   - **Language**: **Swift**
   - **Storage**: **None** (we use SwiftData manually)
5. **Save location**: `/Users/lee/Documents/XCODE/Projects/CanakinRota`
   - ⚠️ **Important**: Choose "Create" (don't replace the existing CanakinRota folder)

### Step 2: Add Files to Project

1. In Xcode, **right-click** on the project (blue icon at top)
2. Select **Add Files to "CanakinRota"...**
3. Navigate to and select the **`CanakinRota` folder** (the one with all the copied files)
4. **IMPORTANT**: 
   - ✅ Check "Create groups"
   - ❌ **UNCHECK** "Copy items if needed" (files are already here!)
   - ✅ Check "CanakinRota" target
5. Click **Add**

### Step 3: Add Firebase Package & Build

1. **File** → **Add Package Dependencies...**
2. Enter: `https://github.com/firebase/firebase-ios-sdk`
3. Click **Add Package**
4. Select these products:
   - ✅ FirebaseAuth
   - ✅ FirebaseCore  
   - ✅ FirebaseFirestore
5. Click **Add Package**
6. **Replace** the auto-generated `CanakinRotaApp.swift` with the one in the `CanakinRota` folder
7. **Delete** the auto-generated `ContentView.swift` (we use `MainRotaAppView.swift` instead)
8. **Build** (⌘B) and fix any import errors
9. **Run** (⌘R)!

## That's It! 🎉

The app should now work with all rota functionality. It uses the same Firebase database as CanakinCafe, so you'll see the same users, companies, and shifts.

## Troubleshooting

- **Build errors**: Make sure all files were added to the target
- **Firebase errors**: Verify `GoogleService-Info.plist` is in the bundle
- **Missing files**: Re-run `./create_project.sh` to copy files again


