# Media Inventory macOS App

A native Swift/SwiftUI macOS application for the Media Inventory System with Mac App Store distribution support.

## Features

- 🎯 **Native macOS Interface** - Built with SwiftUI for optimal performance
- 📱 **Menu Bar Integration** - Quick access from the Dock and menu bar
- 🔔 **System Notifications** - Real-time alerts for checkouts, returns, and overdue items
- 🔍 **Spotlight Search** - Search your entire media library from Spotlight
- 🌙 **Dark Mode Support** - Full support for macOS light and dark themes
- 🔐 **Mac App Store Ready** - Pre-configured for App Store submission

## Requirements

- macOS 13.0 or later
- Xcode 14.0 or later
- Local SQLite database file (`media_inventory.db`)

## Project Structure

```
MediaInventory/
├── MediaInventory/
│   ├── App/
│   │   ├── MediaInventoryApp.swift      # Main app entry point
│   │   └── AppDelegate.swift            # App lifecycle & system features
│   ├── Models/
│   │   └── Models.swift                 # Data models (Book, Game, Movie, Borrower)
│   ├── Views/
│   │   ├── ContentView.swift            # Main UI container
│   │   ├── DashboardView.swift          # Dashboard/statistics
│   │   ├── BooksView.swift              # Books management
│   │   ├── GamesView.swift              # Video games management
│   │   ├── MoviesView.swift             # Movies management
│   │   ├── BorrowersView.swift          # Borrowers management
│   │   └── CheckoutView.swift           # Checkout/Return functionality
│   ├── Services/
│   │   ├── APIClient.swift              # API communication
│   │   ├── NotificationManager.swift    # System notifications
│   │   └── SearchIndexer.swift          # Spotlight indexing
│   ├── Resources/
│   │   ├── Assets.xcassets              # App icons & images
│   │   └── Localizable.strings          # Translations
│   ├── Info.plist                       # App configuration
│   └── MediaInventory.entitlements      # Sandbox & capabilities
└── MediaInventory.xcodeproj
```

## Getting Started

### 0. Quick Setup

From the repository root, run:

```bash
cd macOS/MediaInventory
open MediaInventory.xcodeproj
```

The app uses a local SQLite database at the repository root (`media_inventory.db`) and initializes required tables automatically at startup.

### 1. Development Setup

```bash
# Clone or download this project
cd macOS/MediaInventory

# Open in Xcode
open MediaInventory.xcodeproj
```

### 2. Configure Bundle Identifier

1. In Xcode, select the target "MediaInventory"
2. Go to "Signing & Capabilities"
3. Change the Bundle Identifier to match your app:
   - Example: `com.yourcompany.mediaInventory`

### 3. Data Configuration

`APIClient.swift` now reads and writes directly to SQLite. No HTTP backend process is required.

### 4. Build and Run

```bash
# Build for development
xcodebuild -scheme MediaInventory -configuration Debug

# Build for release
xcodebuild -scheme MediaInventory -configuration Release -arch arm64
```

Or simply press `Cmd+R` in Xcode to build and run.

## Create a Distributable DMG

From the `macOS` folder, run:

```bash
./build_dmg.sh
```

Optional custom version label:

```bash
./build_dmg.sh 1.5
```

Output:

- DMG file is written to `macOS/MediaInventory/build/distribution/MediaInventory-<version>.dmg`
- Includes the app bundle and an `Applications` shortcut for drag-and-drop install

### Distributing Without a Developer ID

You can still share the DMG before you have a Developer ID.

- Build the DMG normally with `./build_dmg.sh 1.5`
- The app will be unsigned for public distribution and not notarized
- On recipient Macs, Gatekeeper may block first launch; users can open via Finder context menu (`Open`) or in System Settings > Privacy & Security > Open Anyway

For internet distribution to non-technical users, add Developer ID signing and notarization later.

## Features Overview

### Dashboard
- Overview statistics (total books, games, movies, borrowers)
- Quick access to all media collections
- Visual statistics cards

### Books Management
- Add, edit, and delete books
- Track author, publisher, year, genre
- Search and filter functionality
- Status tracking (Available, Borrowed, Reserved)

### Video Games Management
- Manage game library
- Track platform, developer, release year
- Search by game title
- Organize by genre

### Movies Management
- Movie collection management
- Director, cast, and studio information
- Rating and runtime tracking
- Image support

### Borrowers Management
- Add and manage borrowers
- Track contact information
- Search borrowers
- Quick access to checkout history

### Checkout & Return
- Check out media to borrowers
- Process returns
- View currently checked out items
- Due date tracking

## Mac App Store Submission

### Prerequisites

1. Apple Developer Account ($99/year)
2. Generated Certificates:
   - Mac App Development Certificate
   - Mac App Distribution Certificate
   - Mac Installer Distribution Certificate

### Step-by-Step Submission

#### 1. Prepare the App

```bash
# Archive for distribution
xcodebuild -scheme MediaInventory -configuration Release -arch arm64 archive

# Export signed app
xcodebuild -exportArchive -archivePath MediaInventory.xcarchive \
  -exportOptionsPlist ExportOptions.plist -exportPath ./exports
```

#### 2. Create App Store Entry

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click "My Apps" → "+"
3. Select "New App"
4. Fill in app information:
   - App Name: "Media Inventory"
   - Bundle ID: `com.yourcompany.mediaInventory`
   - SKU: unique identifier
   - Platform: macOS

#### 3. Prepare App Information

- **Description**: "A comprehensive media inventory management system for macOS"
- **Category**: Productivity
- **Keywords**: media, inventory, library, management, books, games, movies
- **Support URL**: Your support website
- **Privacy Policy**: Your privacy policy

#### 4. Upload Build

1. In App Store Connect, go to "TestFlight" → "macOS"
2. Click "+" to create a new build
3. Upload the `.xcarchive` file
4. Wait for processing and testing
5. Accept agreements and submit for review

#### 5. Submission Checklist

- [ ] App icons (1024x1024 required)
- [ ] Screenshots for App Store
- [ ] Description and keywords
- [ ] Support and privacy URLs
- [ ] Pricing tier selected
- [ ] Review notes explaining the app
- [ ] All required fields filled
- [ ] Entitlements appropriate for sandbox

### App Store Guidelines

Ensure compliance with [Apple's App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/):

- ✅ Functional completeness
- ✅ No hard-coded credentials
- ✅ Proper error handling
- ✅ Privacy policy required
- ✅ Network usage disclosure
- ✅ Crash-free app

## Signing and Notarization (for Direct Distribution)

If distributing outside the App Store:

```bash
# Notarize the app
xcrun altool --notarize-app --file MediaInventory.dmg \
  --primary-bundle-id com.yaourcompany.mediaInventory \
  -u your-apple-id@example.com -p @keychain:altool-password

# Staple the notarization ticket
xcrun stapler staple MediaInventory.dmg
```

## Development Notes

### Adding Features

1. Create new views in `Views/` folder
2. Add API methods to `APIClient.swift`
3. Update `ContentView.swift` if adding new tabs
4. Add menu items in `AppDelegate.swift`

### Connecting to Data

The app communicates directly with SQLite. Ensure:

- `media_inventory.db` exists (or let the app create it on first run)
- App has filesystem permissions for the database path
- Existing tables match the expected schema

### Testing Notifications

```swift
let notificationManager = NotificationManager()
notificationManager.sendCheckoutReminder(media: "Test Book", dueDate: Date())
```

### Testing Spotlight Search

1. Add items to library
2. Open Spotlight (Cmd+Space)
3. Search for items by title, author, etc.
4. Results should appear with thumbnails

## Troubleshooting

### Build Issues

- Ensure iOS Deployment Target is 13.0 or higher
- Check that all dependencies are installed
- Clear build folder: `Cmd+Shift+K`

### Connection Issues

- Verify the database path exists and is readable
- Confirm the `media_inventory.db` file is valid SQLite
- Review app error panel for SQLite errors

### Submission Issues

- Verify bundle identifier matches App Store Connect
- Check entitlements match signing provisions
- Review App Store review guidelines

## Support

For issues or questions:
1. Check the main Media Inventory documentation
2. Review Apple's macOS development guides
3. Contact support@mediaInventory.com

## License

This macOS app is part of the Media Inventory System.
See LICENSE file for details.

## Version History

### v1.0 (Initial Release)
- Native macOS UI with SwiftUI
- Full media management (Books, Games, Movies)
- Borrower tracking and checkout system
- Mac App Store ready
- Spotlight search integration
- System notifications
- Dark mode support
