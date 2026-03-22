#!/bin/bash
# setup_xcode_project.sh
# This script helps set up the Media Inventory macOS app in Xcode

set -e

echo "🍎 Media Inventory - macOS App Setup"
echo "======================================"
echo ""

# Check if Xcode is installed
if ! command -v xcode-select &> /dev/null; then
    echo "❌ Xcode not found. Please install Xcode from the App Store."
    exit 1
fi

echo "✅ Xcode found"
echo ""

# Get the workspace directory
WORKSPACE_DIR="$PWD"
MAC_APP_DIR="$WORKSPACE_DIR/macOS"
PROJECT_DIR="$MAC_APP_DIR/MediaInventory"

echo "📁 Setting up project structure..."
echo "Workspace: $WORKSPACE_DIR"
echo "Project: $PROJECT_DIR"
echo ""

# Create directory structure if it doesn't exist
mkdir -p "$PROJECT_DIR"/{App,Models,Views,Services,Resources/Assets.xcassets}

echo "✅ Directory structure created"
echo ""

# Check for Swift files
SWIFT_FILES=(
    "MediaInventoryApp.swift"
    "AppDelegate.swift"
    "Models.swift"
    "APIClient.swift"
    "NotificationManager.swift"
    "SearchIndexer.swift"
    "ContentView.swift"
    "DashboardView.swift"
    "BooksView.swift"
    "GamesView.swift"
    "MoviesView.swift"
    "BorrowersView.swift"
    "CheckoutView.swift"
)

echo "📝 Checking for Swift source files..."
for file in "${SWIFT_FILES[@]}"; do
    if [ -f "$MAC_APP_DIR/$file" ]; then
        echo "  ✅ $file"
    else
        echo "  ⚠️  $file (not found)"
    fi
done
echo ""

# Check for configuration files
echo "⚙️  Checking for configuration files..."
if [ -f "$MAC_APP_DIR/Info.plist" ]; then
    echo "  ✅ Info.plist"
else
    echo "  ⚠️  Info.plist (not found)"
fi

if [ -f "$MAC_APP_DIR/MediaInventory.entitlements" ]; then
    echo "  ✅ MediaInventory.entitlements"
else
    echo "  ⚠️  MediaInventory.entitlements (not found)"
fi
echo ""

echo "📋 Next Steps:"
echo "=============="
echo ""
echo "1. Open Xcode and create a NEW project:"
echo "   - File → New → Project (or Cmd+Shift+N)"
echo "   - macOS → App"
echo "   - Product Name: MediaInventory"
echo "   - Team: Select your Apple ID"
echo "   - Bundle Identifier: com.yourname.mediainventory"
echo "   - Interface: SwiftUI"
echo "   - Language: Swift"
echo ""
echo "2. Add the Swift files to your project:"
echo "   - Drag files from $MAC_APP_DIR into Xcode"
echo "   - Check 'Copy items if needed'"
echo "   - Select 'Create folder references'"
echo ""
echo "3. Configure project settings:"
echo "   - Minimum Deployment Target: macOS 13.0"
echo "   - Select Project → Build Settings"
echo "   - Search for 'Deployment Target'"
echo "   - Change to 13.0 or higher"
echo ""
echo "4. Add capabilities:"
echo "   - Select Project → Signing & Capabilities"
echo "   - Click '+ Capability'"
echo "   - Add: Network Extension (for API calls)"
echo "   - Add: FileProvider (for file access)"
echo ""
echo "5. Build and run:"
echo "   - Press Cmd+R or Product → Run"
echo "   - Ensure Flask backend is running:"
echo "     cd $WORKSPACE_DIR && python -m flask run"
echo ""
echo "6. Test in Xcode:"
echo "   - Use the macOS Simulator or your Mac"
echo "   - Verify backend connection in Console"
echo ""
echo "For detailed instructions, see:"
echo "   $MAC_APP_DIR/README.md"
echo "   $MAC_APP_DIR/DEVELOPMENT.md"
echo ""
