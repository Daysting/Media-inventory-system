# Testing Guide for macOS App

## 🧪 Unit Testing Setup

### Create a Test Target

1. In Xcode: **File** → **New** → **Target**
2. Choose **macOS** → **Unit Testing Bundle**
3. Name it: `MediaInventoryTests`
4. Select your main target as the target to test

### Test Files Structure

```
MediaInventoryTests/
├── APIClientTests.swift
├── ModelsTests.swift
└── NotificationManagerTests.swift
```

## 🧪 Sample Tests

### APIClientTests.swift

```swift
import XCTest
@testable import MediaInventory

class APIClientTests: XCTestCase {
    var apiClient: APIClient!
    
    override func setUp() {
        super.setUp()
        apiClient = APIClient()
    }
    
    override func tearDown() {
        apiClient = nil
        super.tearDown()
    }
    
    func testFetchBooks() {
        let expectation = XCTestExpectation(description: "Fetch books")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.apiClient.fetchBooks()
            XCTAssertNotNil(self.apiClient.books)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5)
    }
    
    func testAddBook() {
        let book = Book(
            id: "test-id",
            title: "Test Book",
            author: "Test Author",
            yearPublished: 2024,
            publisher: "Test Publisher",
            fictionNonfiction: "Fiction",
            genre: "Science Fiction",
            description: "A test book",
            imageUrl: nil,
            status: "Available"
        )
        
        let expectation = XCTestExpectation(description: "Add book")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.apiClient.addBook(
                title: book.title,
                author: book.author,
                publisher: book.publisher,
                yearPublished: book.yearPublished,
                fictionNonfiction: book.fictionNonfiction,
                genre: book.genre,
                description: book.description,
                imageUrl: book.imageUrl
            )
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5)
    }
}
```

### ModelsTests.swift

```swift
import XCTest
@testable import MediaInventory

class ModelsTests: XCTestCase {
    
    func testBookCoding() throws {
        let json = """
        {
            "id": "1",
            "title": "The Great Gatsby",
            "author": "F. Scott Fitzgerald",
            "yearPublished": 1925,
            "publisher": "Scribner",
            "fictionNonfiction": "Fiction",
            "genre": "Classic",
            "description": "A novel about the Jazz Age",
            "imageUrl": "https://example.com/gatsby.jpg",
            "status": "Available"
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let book = try decoder.decode(Book.self, from: json)
        
        XCTAssertEqual(book.title, "The Great Gatsby")
        XCTAssertEqual(book.author, "F. Scott Fitzgerald")
        XCTAssertEqual(book.yearPublished, 1925)
    }
    
    func testBorrowerCoding() throws {
        let json = """
        {
            "id": "1",
            "firstName": "John",
            "lastName": "Doe",
            "email": "john@example.com",
            "phoneNumber": "555-1234",
            "address": "123 Main St"
        }
        """.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        let borrower = try decoder.decode(Borrower.self, from: json)
        
        XCTAssertEqual(borrower.fullName, "John Doe")
        XCTAssertEqual(borrower.email, "john@example.com")
    }
}
```

## 🧪 UI Testing

### Create UI Tests

1. **File** → **New** → **Target**
2. Choose **macOS** → **UI Testing Bundle**
3. Name it: `MediaInventoryUITests`

### Sample UI Tests

```swift
import XCTest

class MediaInventoryUITests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }
    
    func testAppLaunches() {
        let app = XCUIApplication()
        app.launch()
        
        // Check if Dashboard is visible
        let dashboardButton = app.toolbars.buttons["Dashboard"]
        XCTAssertTrue(dashboardButton.exists)
    }
    
    func testAddBookFlow() {
        let app = XCUIApplication()
        app.launch()
        
        // Click Books tab
        app.toolbars.buttons["Books"].click()
        
        // Click Add Book button
        app.buttons["Add Book"].click()
        
        // Fill form
        let titleField = app.textFields.matching(NSPredicate(format: "placeholder == %@", "Title")).element
        titleField.click()
        titleField.typeText("Test Book")
        
        // Submit
        app.buttons["Add"].click()
        
        // Verify book appears
        let bookCell = app.tables.rows.matching(NSPredicate(format: "label CONTAINS %@", "Test Book")).element
        XCTAssertTrue(bookCell.exists)
    }
}
```

## 🧪 Manual Testing Checklist

### Dashboard Tests
- [ ] App launches without crashes
- [ ] Menu bar icon appears
- [ ] Statistics show correct counts
- [ ] Numbers match database
- [ ] Dashboard updates after adding items

### Books Management
- [ ] Books list loads
- [ ] Add book form opens
- [ ] Can enter all fields
- [ ] Book added to list after submit
- [ ] Search filters books by title
- [ ] Search filters books by author
- [ ] Delete removes book from list
- [ ] Delete confirmation appears

### Games Management
- [ ] Games list loads
- [ ] Add game form works
- [ ] All game fields accessible
- [ ] Search by title works
- [ ] Delete functionality works

### Movies Management
- [ ] Movies list loads
- [ ] Add movie form works
- [ ] Runtime field accepts numbers
- [ ] Search by director works
- [ ] Delete functionality works

### Borrowers Management
- [ ] Borrowers list loads
- [ ] Add borrower form works
- [ ] Email validation works
- [ ] Phone number formatting works
- [ ] Full name display correct
- [ ] Search works
- [ ] Delete works

### Checkout/Return
- [ ] Checkout form displays
- [ ] Return form displays
- [ ] Borrower dropdown populates
- [ ] Item type picker works
- [ ] Item ID lookup works
- [ ] Checkout/Return buttons functional

### System Integration
- [ ] Menu bar icon responds to clicks
- [ ] Notification permission requested
- [ ] Notifications appear for checkouts
- [ ] Spotlight search indexing works
- [ ] Spotlight search finds items
- [ ] Dark mode support functions

### API Integration
- [ ] Backend connection established
- [ ] Console shows no network errors
- [ ] Data persists to database
- [ ] Updates reflected in app

## 🧪 Performance Testing

### Memory Profiling

1. **Product** → **Profile** (or `Cmd+I`)
2. Select **Leaks** instrument
3. Browse the app and interact with all features
4. Check for memory warnings or leaks

### Energy Impact

1. **Product** → **Profile**
2. Select **Energy Impact** instrument
3. Run through app scenarios
4. Look for high energy consumption

## 🧪 Continuous Integration

### GitHub Actions Example

Create `.github/workflows/test.yml`:

```yaml
name: macOS Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: macos-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Build and Test
      run: |
        xcodebuild test \
          -scheme MediaInventory \
          -configuration Debug \
          -arch arm64
```

## 🐛 Debugging Tips

### Enable Console Logging

Add to `AppDelegate.swift`:

```swift
func applicationDidFinishLaunching(_ aNotification: Notification) {
    #if DEBUG
    print("🚀 App launched in DEBUG mode")
    print("📍 Environment: \(NSHomeDirectory())")
    #endif
}
```

### Log API Calls

In `APIClient.swift`:

```swift
private func logRequest(_ method: String, url: String) {
    #if DEBUG
    print("📡 [\(method)] \(url)")
    #endif
}
```

### Check Network with Console

Open System Console and filter by app name:

```bash
log stream --predicate 'eventMessage contains[cd] "mediaInventory"'
```

### Test API Directly

```bash
# Get books
curl http://localhost:5000/api/books

# Add book
curl -X POST http://localhost:5000/api/books \
  -H "Content-Type: application/json" \
  -d '{
    "title": "Test",
    "author": "Author",
    "yearPublished": 2024,
    "status": "Available"
  }'
```

## ✅ Release Testing

Before submitting to App Store:

- [ ] All unit tests pass
- [ ] All UI tests pass
- [ ] No memory leaks
- [ ] No console errors
- [ ] App notarization succeeds
- [ ] DMG downloads and launches correctly
- [ ] All features work as intended
- [ ] Performance acceptable
- [ ] Dark mode looks good
- [ ] Universal (arm64) architecture

## 📊 Performance Targets

- **App Launch**: < 2 seconds
- **Database Query**: < 500ms
- **UI Responsiveness**: 60fps
- **Memory Usage**: < 100MB
- **CPU Usage**: < 20% idle

See [DEVELOPMENT.md](DEVELOPMENT.md) for distribution testing.
