# Quick Start Guide

## 📋 What You Have

Your Media Inventory System now has a complete native macOS application ready to build. All Swift source files are in the `/macOS` folder.

## 🚀 Getting Started (5 minutes)

### Step 1: Open Xcode

```bash
open -a Xcode /Users/erickhofer/Media-inventory-system
```

### Step 2: Create a New Project

1. **File** → **New** → **Project** (or `Cmd+Shift+N`)
2. Select **macOS** → **App**
3. Configure:
   - **Product Name**: `MediaInventory`
   - **Team**: Your Apple Developer account
   - **Bundle Identifier**: `com.yourname.mediaInventory`
   - **Interface**: SwiftUI
   - **Language**: Swift
   - **Storage**: SwiftData (can uncheck if not needed)
4. Click **Next** and choose location (create elsewhere, we'll move files)

### Step 3: Add Swift Files

1. In Xcode, right-click the project folder
2. Select **Add Files to MediaInventory**
3. Navigate to `/Users/erickhofer/Media-inventory-system/macOS/`
4. Select all `.swift` files:
   - `MediaInventoryApp.swift`
   - `AppDelegate.swift`
   - `Models.swift`
   - `APIClient.swift`
   - `NotificationManager.swift`
   - `SearchIndexer.swift`
   - `ContentView.swift`
   - `DashboardView.swift`
   - `BooksView.swift`
   - `GamesView.swift`
   - `MoviesView.swift`
   - `BorrowersView.swift`
   - `CheckoutView.swift`
5. Check: ☑️ Copy items if needed
6. Select: ☑️ Create groups

### Step 4: Configure Build Settings

1. Select **Project** → **Build Settings**
2. Search for `Deployment Target`
3. Set to **macOS 13.0** (or higher)

### Step 5: Set Up Info.plist

1. Select **Project** → **Build Settings**
2. Search for `Info.plist`
3. Copy contents from `/macOS/Info.plist` into Xcode's Info.plist
4. Key additions:
   ```xml
   <key>NSSpotlightImportedAttributeDescriptions</key>
   <array>
       <dict>
           <key>CFBundleTypeIconFile</key>
           <string>AppIcon</string>
           <key>CFBundleTypeName</key>
           <string>Books</string>
           <key>CFBundleTypeRole</key>
           <string>Viewer</string>
           <key>LSHandlerRank</key>
           <string>Owner</string>
           <key>LSItemContentTypes</key>
           <array>
               <string>com.mediaInventory.book</string>
           </array>
       </dict>
   </array>
   ```

### Step 6: Configure Entitlements

1. Select **Project** → **Signing & Capabilities**
2. Click **+ Capability** and add:
   - **Network Extensions** (for API calls)
   - **Sandbox** (for Mac App Store)
3. Upload the `MediaInventory.entitlements` file

### Step 7: Test Run

1. **Product** → **Run** (or `Cmd+R`)
2. Start Flask backend in another terminal:
   ```bash
   cd /Users/erickhofer/Media-inventory-system
   python -m flask run
   ```
3. App should launch and connect to `http://localhost:5000/api`

## 🧪 Testing Checklist

- [ ] App launches without errors
- [ ] Dashboard shows menu bar icon
- [ ] Books tab displays (or empty if no data)
- [ ] Add book form opens and submits
- [ ] Books appear in list after adding
- [ ] Delete functionality works
- [ ] Search filters books correctly
- [ ] Same for Games, Movies, Borrowers
- [ ] Checkout/Return tab loads

## 🔄 File Organization

The app uses this structure:

```
MediaInventory/
├── App/
│   ├── MediaInventoryApp.swift      ← Main entry point
│   └── AppDelegate.swift             ← System integration
├── Models/
│   └── Models.swift                  ← Data structures
├── Services/
│   ├── APIClient.swift               ← Backend communication
│   ├── NotificationManager.swift     ← System notifications
│   └── SearchIndexer.swift           ← Spotlight search
└── Views/
    ├── ContentView.swift             ← Main UI container
    ├── DashboardView.swift           ← Statistics
    ├── BooksView.swift               ← Books management
    ├── GamesView.swift               ← Games management
    ├── MoviesView.swift              ← Movies management
    ├── BorrowersView.swift           ← Borrowers management
    └── CheckoutView.swift            ← Checkout/return
```

## 🛠️ Build Commands

### Development Build
```bash
xcodebuild -scheme MediaInventory \
  -configuration Debug \
  -arch arm64 \
  build
```

### Release Build
```bash
xcodebuild -scheme MediaInventory \
  -configuration Release \
  -arch arm64 \
  archive -archivePath ~/Desktop/MediaInventory.xcarchive
```

### Run Tests
```bash
xcodebuild test -scheme MediaInventory
```

## 📦 Distribution

### Create DMG (Direct Distribution)
```bash
# Archive
xcodebuild archive -scheme MediaInventory \
  -archivePath ~/Desktop/MediaInventory.xcarchive

# Export
xcodebuild -exportArchive \
  -archivePath ~/Desktop/MediaInventory.xcarchive \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath ~/Desktop/Export

# Create DMG
hdiutil create -volname "Media Inventory" \
  -srcfolder ~/Desktop/Export \
  -ov -format UDZO ~/Desktop/MediaInventory.dmg
```

### App Store Submission
Reference [DEVELOPMENT.md](DEVELOPMENT.md) for step-by-step App Store submission.

## 🔧 Troubleshooting

### App won't build
- Check Xcode version (14.0+ required)
- Clear derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData`
- Verify Swift version: `swift --version`

### API connection fails
- Ensure Flask is running: `python -m flask run`
- Check API URL in `APIClient.swift`: `http://localhost:5000/api`
- Look for errors in Xcode Console

### Spotlight search not working
- Add `com.apple.security.personal-information.search-index` capability
- Rebuild and reindex by relaunching app

### Notifications don't appear
- Grant notification permission in System Preferences
- Check: System Preferences → Notifications → Media Inventory

## 📚 Documentation

- **README.md** - Project overview and features
- **DEVELOPMENT.md** - Detailed development guide
- This file - Quick start instructions

## ✅ Done!

You're now ready to:
1. ✅ Build the macOS app
2. ✅ Test locally with Flask backend
3. ✅ Distribute via DMG
4. ✅ Submit to Mac App Store

See [DEVELOPMENT.md](DEVELOPMENT.md) for advanced topics like notarization and App Store submission.
