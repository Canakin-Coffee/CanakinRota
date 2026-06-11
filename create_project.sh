#!/bin/bash

# CanakinRota Project Setup Script
# Run this from the CanakinRota directory

set -e

SOURCE_DIR="../CanakinCafe/CanakinCafe"
TARGET_DIR="CanakinRota"

echo "🚀 Setting up CanakinRota standalone app..."
echo "Source: $SOURCE_DIR"
echo "Target: $TARGET_DIR"
echo ""

# Create directory structure
echo "📁 Creating directory structure..."
mkdir -p "$TARGET_DIR/Models/Company"
mkdir -p "$TARGET_DIR/Models/Staff/Core"
mkdir -p "$TARGET_DIR/Models/Staff/Rota"
mkdir -p "$TARGET_DIR/Models/Staff/Shifts"
mkdir -p "$TARGET_DIR/Models/Staff/TimeOff"
mkdir -p "$TARGET_DIR/Models/Staff/Payroll"
mkdir -p "$TARGET_DIR/Models/Staff/Utilities"
mkdir -p "$TARGET_DIR/Views/Authentication"
mkdir -p "$TARGET_DIR/Views/Staff/Rota"
mkdir -p "$TARGET_DIR/Views/Staff/Shifts"
mkdir -p "$TARGET_DIR/Views/Staff/User"
mkdir -p "$TARGET_DIR/Views/Staff/TimeOff"
mkdir -p "$TARGET_DIR/Views/Staff/TimeTracking"
mkdir -p "$TARGET_DIR/Firebase"
mkdir -p "$TARGET_DIR/Helpers"
mkdir -p "$TARGET_DIR/Utilities"

echo "✅ Directories created"
echo ""

# Copy Models
echo "📦 Copying Models..."
if [ -d "$SOURCE_DIR/Models/Company" ]; then
    cp -r "$SOURCE_DIR/Models/Company"/* "$TARGET_DIR/Models/Company/" 2>/dev/null || true
    echo "  ✓ Company models"
fi

if [ -d "$SOURCE_DIR/Models/Staff/Core" ]; then
    cp -r "$SOURCE_DIR/Models/Staff/Core"/* "$TARGET_DIR/Models/Staff/Core/" 2>/dev/null || true
    echo "  ✓ Staff Core models"
fi

if [ -d "$SOURCE_DIR/Models/Staff/Rota" ]; then
    cp -r "$SOURCE_DIR/Models/Staff/Rota"/* "$TARGET_DIR/Models/Staff/Rota/" 2>/dev/null || true
    echo "  ✓ Rota models"
fi

if [ -d "$SOURCE_DIR/Models/Staff/Shifts" ]; then
    cp -r "$SOURCE_DIR/Models/Staff/Shifts"/* "$TARGET_DIR/Models/Staff/Shifts/" 2>/dev/null || true
    echo "  ✓ Shift models"
fi

if [ -d "$SOURCE_DIR/Models/Staff/TimeOff" ]; then
    cp -r "$SOURCE_DIR/Models/Staff/TimeOff"/* "$TARGET_DIR/Models/Staff/TimeOff/" 2>/dev/null || true
    echo "  ✓ TimeOff models"
fi

if [ -f "$SOURCE_DIR/Models/Staff/Payroll/UserRolePriority.swift" ]; then
    cp "$SOURCE_DIR/Models/Staff/Payroll/UserRolePriority.swift" "$TARGET_DIR/Models/Staff/Payroll/" 2>/dev/null || true
    echo "  ✓ UserRolePriority"
fi

if [ -d "$SOURCE_DIR/Models/Staff/Utilities" ]; then
    cp "$SOURCE_DIR/Models/Staff/Utilities/AuthorityLevelPermission.swift" "$TARGET_DIR/Models/Staff/Utilities/" 2>/dev/null || true
    cp "$SOURCE_DIR/Models/Staff/Utilities/AuthorityPermissionsCache.swift" "$TARGET_DIR/Models/Staff/Utilities/" 2>/dev/null || true
    cp "$SOURCE_DIR/Models/Staff/Utilities/CustomColor.swift" "$TARGET_DIR/Models/Staff/Utilities/" 2>/dev/null || true
    echo "  ✓ Utility models"
fi

echo "✅ Models copied"
echo ""

# Copy Views
echo "📱 Copying Views..."
if [ -d "$SOURCE_DIR/Views/Authentication" ]; then
    cp -r "$SOURCE_DIR/Views/Authentication"/* "$TARGET_DIR/Views/Authentication/" 2>/dev/null || true
    echo "  ✓ Authentication views"
fi

if [ -d "$SOURCE_DIR/Views/Staff/Rota" ]; then
    cp -r "$SOURCE_DIR/Views/Staff/Rota"/* "$TARGET_DIR/Views/Staff/Rota/" 2>/dev/null || true
    echo "  ✓ Rota views"
fi

if [ -d "$SOURCE_DIR/Views/Staff/Shifts" ]; then
    cp -r "$SOURCE_DIR/Views/Staff/Shifts"/* "$TARGET_DIR/Views/Staff/Shifts/" 2>/dev/null || true
    echo "  ✓ Shift views"
fi

if [ -d "$SOURCE_DIR/Views/Staff/User" ]; then
    cp -r "$SOURCE_DIR/Views/Staff/User"/* "$TARGET_DIR/Views/Staff/User/" 2>/dev/null || true
    echo "  ✓ User views"
fi

if [ -d "$SOURCE_DIR/Views/Staff/TimeOff" ]; then
    cp -r "$SOURCE_DIR/Views/Staff/TimeOff"/* "$TARGET_DIR/Views/Staff/TimeOff/" 2>/dev/null || true
    echo "  ✓ TimeOff views"
fi

if [ -d "$SOURCE_DIR/Views/Staff/TimeTracking" ]; then
    cp -r "$SOURCE_DIR/Views/Staff/TimeTracking"/* "$TARGET_DIR/Views/Staff/TimeTracking/" 2>/dev/null || true
    echo "  ✓ TimeTracking views"
fi

echo "✅ Views copied"
echo ""

# Copy Firebase
echo "🔥 Copying Firebase Managers..."
for file in FirebaseManager.swift FirestoreManager.swift FirestoreShiftManager.swift FirestoreUserManager.swift FirestoreRoleManager.swift; do
    if [ -f "$SOURCE_DIR/Firebase/$file" ]; then
        cp "$SOURCE_DIR/Firebase/$file" "$TARGET_DIR/Firebase/" 2>/dev/null || true
        echo "  ✓ $file"
    fi
done
echo "✅ Firebase Managers copied"
echo ""

# Copy Helpers
echo "🛠️  Copying Helpers..."
for file in AlertManager.swift Formatters.swift DateRangePicker.swift TimeRangePicker.swift LabeledTextField.swift SyncManager.swift SyncStatusManager.swift UUIDExtensions.swift; do
    if [ -f "$SOURCE_DIR/Helpers/$file" ]; then
        cp "$SOURCE_DIR/Helpers/$file" "$TARGET_DIR/Helpers/" 2>/dev/null || true
        echo "  ✓ $file"
    fi
done
echo "✅ Helpers copied"
echo ""

# Copy Config Files
echo "⚙️  Copying Configuration..."
if [ -f "$SOURCE_DIR/GoogleService-Info.plist" ]; then
    cp "$SOURCE_DIR/GoogleService-Info.plist" "$TARGET_DIR/" 2>/dev/null || true
    echo "  ✓ GoogleService-Info.plist"
fi
if [ -f "$SOURCE_DIR/GoogleService-Info-mac.plist" ]; then
    cp "$SOURCE_DIR/GoogleService-Info-mac.plist" "$TARGET_DIR/" 2>/dev/null || true
    echo "  ✓ GoogleService-Info-mac.plist"
fi
echo "✅ Configuration copied"
echo ""

echo "🎉 File copying complete!"
echo ""
echo "📋 Next Steps:"
echo "1. Open Xcode"
echo "2. File → New → Project → iOS → App"
echo "3. Name: CanakinRota, Interface: SwiftUI"
echo "4. Save in: $(pwd)"
echo "5. Delete auto-generated files: ContentView.swift, CanakinRotaApp.swift"
echo "6. Right-click project → Add Files to 'CanakinRota' → Select 'CanakinRota' folder"
echo "7. UNCHECK 'Copy items if needed' (files are already here)"
echo "8. Add Firebase: File → Add Package → https://github.com/firebase/firebase-ios-sdk"
echo "9. Select: FirebaseAuth, FirebaseCore, FirebaseFirestore"
echo "10. Build and run!"
echo ""


