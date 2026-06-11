# CanakinRota - Standalone Rota Management App

A standalone iOS app for rota (shift scheduling) management, extracted from CanakinCafe.

## ✅ Setup Complete!

**All files have been automatically copied!** 82 Swift files are ready to use.

## Quick Start (3 Steps)

### Step 1: Create Xcode Project

1. Open Xcode
2. **File → New → Project**
3. Choose **iOS → App**
4. Name: `CanakinRota`, Interface: **SwiftUI**
5. Save in: `/Users/lee/Documents/XCODE/Projects/CanakinRota`

### Step 2: Add Files

1. Right-click project → **Add Files to "CanakinRota"...**
2. Select the `CanakinRota` folder
3. **UNCHECK** "Copy items if needed"
4. Click **Add**

### Step 3: Add Firebase & Build

1. **File → Add Package Dependencies...**
2. URL: `https://github.com/firebase/firebase-ios-sdk`
3. Add: FirebaseAuth, FirebaseCore, FirebaseFirestore
4. Replace auto-generated `CanakinRotaApp.swift` with the one in the folder
5. Delete auto-generated `ContentView.swift`
6. Build (⌘B) and Run (⌘R)!

## What's Included

✅ **Complete Rota System:**
- View and edit rota/schedules
- Create and manage shifts
- Generate rota automatically
- Shift validation and reporting
- Time off requests
- Clock in/out tracking
- User and role management

✅ **All Required Components:**
- Models (User, Role, Company, Shift, etc.)
- Views (Rota, Shifts, Authentication, etc.)
- Firebase integration (shared database)
- Helpers and utilities

## Firebase Integration

- Uses the **same Firebase database** as CanakinCafe
- Users and companies are **shared** between apps
- Real-time sync between apps
- Authentication works with existing accounts

## File Structure

```
CanakinRota/
├── CanakinRotaApp.swift       # App entry point
├── MainRotaAppView.swift      # Main view (simplified)
├── Models/                    # Data models
├── Views/                     # UI views
├── Firebase/                  # Firebase managers
├── Helpers/                   # Utility helpers
└── GoogleService-Info.plist  # Firebase config
```

## Notes

- The `MainRotaAppView.swift` is simplified. For full auth logic, you can use the copied `Views/Authentication/MainAppView.swift` instead
- All files are ready - just create the Xcode project and add them!
- The app focuses solely on rota management (no ingredients, recipes, etc.)

## Support

For issues, check:
- `QUICK_START.md` - Detailed setup steps
- `SUMMARY.md` - What was copied and status
- `SETUP_GUIDE.md` - Complete setup guide


