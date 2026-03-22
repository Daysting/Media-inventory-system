# macOS App Development Guide

## Quick Start

### 1. Create Xcode Project

If you don't have Xcode project yet set up:

```bash
cd /Users/erickhofer/Media-inventory-system

# Create the macOS directory structure
mkdir -p macOS/MediaInventory

# Open Xcode and create new project:
# File → New → Project
# Choose macOS → App
# Product Name: MediaInventory
# Team: (Your Apple ID)
# Bundle Identifier: com.yourname.mediaInventory
# Interface: SwiftUI
# Language: Swift
```

### 2. Project Configuration

```
Build Settings:
- Minimum Deployment Target: macOS 13.0
- Product Name: Media Inventory
- Team ID: (Your developer account)
- Signing: Automatically manage signing
- Capabilities: Add Camera, Network, CoreSpotlight
```

### 3. File Organization

Copy the Swift files into your Xcode project:

```
MediaInventory/
├── App/
│   ├── MediaInventoryApp.swift
│   └── AppDelegate.swift
├── Models/
│   └── Models.swift
├── Views/
│   ├── ContentView.swift
│   ├── DashboardView.swift
│   ├── BooksView.swift
│   ├── GamesView.swift
│   ├── MoviesView.swift
│   ├── BorrowersView.swift
│   └── CheckoutView.swift
├── Services/
│   ├── APIClient.swift
│   ├── NotificationManager.swift
│   └── SearchIndexer.swift
└── Resources/
    ├── Assets.xcassets
    ├── Localizable.strings
    ├── Info.plist
    └── MediaInventory.entitlements
```

### 4. Build and Run

```bash
# In Xcode, select scheme "MediaInventory"
# Select a Mac as target
# Press Cmd+R to build and run
```

## Testing Locally

### 1. Start Flask Backend

```bash
cd /Users/erickhofer/Media-inventory-system
python -m flask run
# Server running at http://localhost:5000
```

### 2. Run macOS App

- Press `Cmd+R` in Xcode
- App will connect to `http://localhost:5000/api`
- Try adding media and borrowers

### 3. Test Features

**Dashboard**
- Check stats load correctly
- Verify counts match database

**Books Management**
- Add a test book
- Verify it appears in the list
- Test delete functionality

**Notifications**
- Manually trigger a notification:
  ```swift
  let notificationManager = NotificationManager()
  notificationManager.sendSuccessNotification(
    title: "Test",
    message: "Notification test"
  )
  ```

**Spotlight Search**
- Add items to library
- Open Spotlight (Cmd+Space)
- Type item name
- Verify results appear

## Building for Distribution

### Create DMG Installer

```bash
# Archive the app
xcodebuild -scheme MediaInventory \
  -configuration Release \
  -arch arm64 \
  archive -archivePath ~/Desktop/MediaInventory.xcarchive

# Export to .app
xcodebuild -exportArchive \
  -archivePath ~/Desktop/MediaInventory.xcarchive \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath ~/Desktop/Export

# Create DMG
hdiutil create -volname "Media Inventory" \
  -srcfolder ~/Desktop/Export \
  -ov -format UDZO ~/Desktop/MediaInventory.dmg
```

### Sign the DMG

```bash
codesign -s "Developer ID Application: Your Name" \
  ~/Desktop/MediaInventory.dmg
```

### Notarize

```bash
# Step 1: Submit for notarization
xcrun notarytool submit ~/Desktop/MediaInventory.dmg \
  --keychain-profile "your-app-password" \
  --wait

# Step 2: Staple when approved
xcrun stapler staple ~/Desktop/MediaInventory.dmg
```

## App Store Submission

### 1. Create App Store Connect Record

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Sign in with your Apple ID
3. Click "My Apps" → "+"
4. Select "New app"
5. Fill in details:
   - Platform: macOS
   - Name: Media Inventory
   - Bundle ID: com.yourcompany.mediaInventory

### 2. Prepare Screenshots

Create screenshots for each resolution:
- 1280x800 (required)
- Additional sizes optional

Screenshots should show:
- Dashboard overview
- Books/Games/Movies management
- Borrowers interface
- Excellent design and functionality

### 3. Fill in App Information

**Description** (max 4000 chars):
```
Media Inventory is a comprehensive macOS application for managing your 
personal media collection. Organize books, video games, and movies. Track 
borrowers, manage checkouts, and get notifications for due dates.

Features:
• Full media library management
• Borrower tracking and checkout system
• Spotlight search integration
• System notifications for important events
• Beautiful native macOS interface
• Dark mode support
```

**Keywords**:
media, inventory, library, management, books, games, movies, collection, tracker

**Support URL**: https://yourdomain.com/support
**Privacy Policy**: https://yourdomain.com/privacy

### 4. Set Pricing

- Select appropriate tier (e.g., $4.99)
- Configure pricing for all regions

### 5. Prepare Build

```bash
# Final release build
xcodebuild -scheme MediaInventory \
  -configuration Release \
  -arch arm64 \
  archive -archivePath ~/Desktop/MediaInventory-Release.xcarchive

# Export for App Store
xcodebuild -exportArchive \
  -archivePath ~/Desktop/MediaInventory-Release.xcarchive \
  -exportOptionsPlist ExportOptions-AppStore.plist \
  -exportPath ~/Desktop/AppStoreExport
```

### ExportOptions-AppStore.plist

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>mac-appstore</string>
	<key>signingStyle</key>
	<string>automatic</string>
	<key>stripSwiftSymbols</key>
	<true/>
	<key>teamID</key>
	<string>YOUR_TEAM_ID</string>
	<key>uploadBitcode</key>
	<false/>
</dict>
</plist>
```

### 6. Submit via App Store Connect

1. Go to App Store Connect
2. Select your app
3. Go to "TestFlight" or "Releases"
4. Click "+" to add new build
5. Upload the build (usually automatic after export)
6. Wait for processing (5-15 minutes)
7. Fill in "App Review Information"
8. Click "Submit for Review"

### 7. App Store Review

Apple will review your app (typically 1-3 days):
- ✅ Functionality test
- ✅ Security review
- ✅ Content appropriateness
- ✅ Compliance check

## Common Issues & Solutions

### Issue: "Code Signing" errors

**Solution**: 
- Ensure Xcode automatic signing is enabled
- Check bundle identifier matches provisioning profile
- Try clearing ~/Library/Developer/Xcode/DerivedData

### Issue: API connection fails

**Solution**:
- Verify Flask server running: `curl http://localhost:5000/api/books`
- Check `APIClient.baseURL` is correct
- Look for network errors in Console

### Issue: Spotlight search not working

**Solution**:
- Verify CoreSpotlight capability is enabled
- Check SearchIndexer is called in AppDelegate
- Try reindexing apps in System Preferences

### Issue: Notifications not appearing

**Solution**:
- Grant notification permissions in System Preferences
- Check notification settings for app
- Verify NotificationManager is properly initialized

## Performance Optimization

### 1. Lazy Loading

```swift
@State private var isLoading = false
@State private var items: [Item] = []

// Load data only when view appears
.onAppear {
    if items.isEmpty {
        loadItems()
    }
}
```

### 2. Efficient Filtering

```swift
var filteredItems: [Item] {
    if searchText.isEmpty {
        return items
    }
    return items.filter { item in
        item.title.localizedCaseInsensitiveContains(searchText)
    }
}
```

### 3. Image Caching

```swift
// Consider using URLImageStore for caching
// Or implement your own NSCache-based solution
```

## Next Steps

1. ✅ Set up Xcode project
2. ✅ Add all Swift files
3. ✅ Configure bundle identifier
4. ✅ Test with local Flask backend
5. ✅ Create app icons (1024x1024)
6. ✅ Write app description
7. ✅ Take screenshots
8. ✅ Submit to App Store

For detailed App Store submission, see the main README.md file.
