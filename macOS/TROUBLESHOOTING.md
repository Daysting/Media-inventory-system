# Troubleshooting Guide

## 🔍 Common Issues

### Build Errors

#### "Cannot find 'AppDelegate' in scope"
**Problem**: Swift file not added to build target

**Solution**:
1. Select `AppDelegate.swift`
2. Inspector → Target Membership
3. Check `MediaInventory` is selected

#### "Unexpected symbol in conditional compilation directive"
**Problem**: Swift syntax error in file

**Solution**:
```swift
// ✅ Correct
#if DEBUG
    print("Debug mode")
#endif

// ❌ Wrong
#if DEBUG {
    print("Debug mode")
}
```

#### "Module compiled with Swift X.X.X, but this file was compiled with X.X.X"
**Problem**: Swift version mismatch

**Solution**:
1. **Product** → **Clean Build Folder** (`Shift+Cmd+K`)
2. **File** → **Packages** → **Reset Package Caches**
3. Rebuild

#### "Could not find or create a git repository"
**Problem**: Xcode wants to initialize git

**Solution**: Skip by unchecking during project creation, or:
```bash
cd /path/to/project
git init
```

### Runtime Errors

#### App crashes on launch
**Problem**: Usually AppDelegate or main view initialization

**Solution**:
1. Open Xcode Console (`Cmd+Shift+C`)
2. Look for error messages
3. Check each view loads correctly in isolation:
   ```swift
   // Test ContentView
   struct ContentView_Previews: PreviewProvider {
       static var previews: some View {
           ContentView()
               .environmentObject(APIClient())
       }
   }
   ```

#### "Cannot convert value of type 'APIClient' to expected type 'EnvironmentObject'"
**Problem**: APIClient not conforming to ObservableObject

**Solution**: Verify in `APIClient.swift`:
```swift
class APIClient: ObservableObject {  // ← Required
    @Published var books: [Book] = []
    // ...
}
```

#### Fatal error: "wantsSynchronous not set. Did you forget to call delegate methods in the scene delegate?"
**Problem**: Missing SceneDelegate configuration

**Solution**: Check `MediaInventoryApp.swift`:
```swift
@main
struct MediaInventoryApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(APIClient())
        }
    }
}
```

### API Connection Issues

#### "Error: Cannot connect to 'localhost:5000'"
**Problem**: Flask backend not running or wrong URL

**Solution**:
```bash
# Terminal 1 - Start Flask
cd /Users/erickhofer/Media-inventory-system
source .venv/bin/activate
python -m flask run

# Terminal 2 - Check connection
curl http://localhost:5000/api/books

# In app console, check APIClient
print(APIClient().baseURL)  // Should print: http://localhost:5000/api
```

#### "SSL/TLS 'certificate_verify_failed'"
**Problem**: SSL certificate validation failure (common in development)

**Solution**: 
1. Use `http://` instead of `https://` for localhost
2. For production HTTPS, add to `APIClient.swift`:
   ```swift
   let config = URLSessionConfiguration.default
   config.waitsForConnectivity = true
   let session = URLSession(configuration: config)
   ```

#### Data not loading in app but works in browser
**Problem**: CORS or API response format issue

**Solution**:
1. Check API response format matches Model:
   ```bash
   curl http://localhost:5000/api/books | python -m json.tool
   ```
2. Compare with `Models.swift` - ensure CodingKey matches
3. Add CORS headers to Flask:
   ```python
   from flask_cors import CORS
   CORS(app)
   ```

#### "JSONDecoder Error: The data couldn't be read"
**Problem**: API returned unexpected format

**Solution**:
1. Print raw response in `APIClient.swift`:
   ```swift
   let string = String(data: data, encoding: .utf8) ?? "no data"
   print("Response: \(string)")
   ```
2. Compare with Model's CodingKey attributes
3. Verify API field names match exactly (case-sensitive)

### UI Issues

#### Views not showing
**Problem**: @State not initialized or view not in hierarchy

**Solution**:
```swift
// ✅ Correct
struct ContentView: View {
    @State private var selectedTab: Tab = .dashboard
    
    var body: some View {
        switch selectedTab {
            case .dashboard:
                DashboardView()
            case .books:
                BooksView()
        }
    }
}

// ❌ Wrong - missing @State
struct ContentView: View {
    var selectedTab: Tab = .dashboard  // ← No @State
}
```

#### Text fields not updating
**Problem**: @State variable not bound correctly

**Solution**:
```swift
// ✅ Correct
@State private var title = ""

TextField("Title", text: $title)

// ❌ Wrong - missing $
TextField("Title", text: title)
```

#### Images not loading
**Problem**: URL incorrect or Image model field missing

**Solution**:
1. Check URL is absolute: `https://example.com/image.jpg` (not `image.jpg`)
2. Add AsyncImage for URL loading:
   ```swift
   if let imageUrl = book.imageUrl, let url = URL(string: imageUrl) {
       AsyncImage(url: url)
           .frame(width: 80, height: 100)
   }
   ```

#### Menu bar icon not appearing
**Problem**: AppDelegate setupMenuBar() not called

**Solution**:
1. Verify in `MediaInventoryApp.swift`:
   ```swift
   @NSApplicationDelegateAdaptor(AppDelegate.self) var delegate
   ```
2. Check `AppDelegate.applicationDidFinishLaunching()` calls:
   ```swift
   func applicationDidFinishLaunching(_ notification: Notification) {
       setupMenuBar()  // ← Must be called
   }
   ```

### System Integration Issues

#### Notifications not appearing
**Problem**: Permission not granted or manager not initialized

**Solution**:
```bash
# Check notification settings:
# System Preferences → Notifications → Media Inventory

# Ensure NotificationManager requests permission first:
UNUserNotificationCenter.current()
    .requestAuthorization(options: [.alert, .sound]) { granted, error in
        // Check granted is true
    }
```

#### Spotlight search not indexing
**Problem**: CoreSpotlight not configured properly

**Solution**:
1. Check `Info.plist` has Spotlight descriptors:
   ```xml
   <key>NSSpotlightImportedAttributeDescriptions</key>
   <array>...</array>
   ```
2. Verify `SearchIndexer.swift` called in `AppDelegate`
3. Reindex manually:
   ```bash
   mdimport -d com.mediaInventory.book .
   ```

### Performance Issues

#### App freezes when loading data
**Problem**: Network call on main thread

**Solution**: Ensure all API calls use background queue:
```swift
// ✅ Correct
DispatchQueue.main.async {
    self.books = books
}

// ❌ Wrong - blocking main thread
let books = fetchBooksSync()  // Don't do sync on main thread
```

#### High memory usage
**Problem**: Large image arrays not being released

**Solution**:
1. Use `@StateObject` instead of `@State` for complex objects:
   ```swift
   @StateObject private var apiClient = APIClient()
   ```
2. Implement cleanup:
   ```swift
   .onDisappear {
       apiClient.books.removeAll()
   }
   ```

#### Slow table scrolling
**Problem**: Complex row views or too many items

**Solution**:
1. Use `.id()` modifier for list items
2. Lazy load images
3. Consider pagination for large lists

## 🛠️ Advanced Debugging

### Enable Verbose Logging

In `AppDelegate.swift`:

```swift
import os.log

let appLog = OSLog(subsystem: "com.mediaInventory", category: "app")

func debugLog(_ message: String) {
    #if DEBUG
    os_log("%{public}@", log: appLog, type: .debug, message)
    #endif
}
```

### Check Swift Compilation

```bash
# Verbose build
xcodebuild -verbose build -scheme MediaInventory

# Check specific file
swiftc -typecheck /path/to/file.swift
```

### Monitor Network with Charles

1. Download [Charles Proxy](https://www.charlesproxy.com/)
2. Configure in `APIClient.swift`:
   ```swift
   let config = URLSessionConfiguration.default
   config.connectionProxyDictionary = [
       kCFNetworkProxiesHTTPEnable: true,
       kCFNetworkProxiesHTTPProxy: "127.0.0.1",
       kCFNetworkProxiesHTTPPort: 8888
   ] as [String: Any]
   ```
3. View all API calls in Charles

### Use lldb Debugger

```bash
# Set breakpoint in Xcode and inspect variables:
(lldb) po apiClient.books
(lldb) po apiClient.errorMessage
(lldb) expression let x = 5 + 3
```

## 📋 Diagnostic Checklist

Before reporting bugs:

- [ ] Swift version matches (`swift --version`)
- [ ] Xcode version is current
- [ ] Minimum deployment target is 13.0+
- [ ] All files added to build target
- [ ] No compilation warnings
- [ ] Console has no error messages
- [ ] Flask backend running and accessible
- [ ] API endpoint returns valid JSON
- [ ] App tested on actual macOS (not just simulator)
- [ ] All permissions granted (notifications, network)

## 📞 Getting Help

1. **Xcode Build Error**: Copy full error message from build log
2. **Runtime Crash**: Share console output with full backtrace
3. **API Issue**: Show curl response: `curl -v http://localhost:5000/api/books`
4. **UI Problem**: Share screenshot showing issue
5. **Performance**: Share Activity Monitor output during the issue

## 🔗 Useful Resources

- [Apple SwiftUI Documentation](https://developer.apple.com/xcode/swiftui/)
- [URLSession Documentation](https://developer.apple.com/documentation/foundation/urlsession)
- [AppKit Documentation](https://developer.apple.com/documentation/appkit)
- [Xcode Help](https://help.apple.com/xcode)
- [Swift Language Guide](https://docs.swift.org/swift-book)
