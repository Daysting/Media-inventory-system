# Media Inventory System - Reporting Features

## Overview
The Media Inventory System now includes comprehensive reporting functionality to help you analyze your media collection, borrower activity, and checkout patterns.

## Available Reports

### 1. Inventory Summary 📊
Provides an overview of your entire media inventory including:
- Total counts for books, video games, and movies
- Number of owned vs. total items
- Borrower statistics
- Current checkout status

### 2. Borrower Activity Report 👥
Shows detailed information about borrower engagement:
- List of all borrowers with their activity levels
- Currently checked out items per borrower
- Total items returned historically
- Last activity date

### 3. Checkout History Report 📅
Complete history of all checkouts and returns:
- Filterable by date range (start/end dates)
- Shows borrower names, media details, checkout/return dates
- Status tracking (checked out vs. returned)

### 4. Genre Distribution 🎭
Breakdown of your collection by genre:
- Separate tables for books, video games, and movies
- Count of items per genre
- Helps identify collection strengths and gaps

### 5. Overdue Items Report ⚠️
Identifies potentially overdue items:
- Items checked out for more than 30 days
- Shows borrower information and checkout dates
- Helps with collection management

## API Endpoints

All reports are available via REST API endpoints:

- `GET /api/reports/inventory-summary` - Inventory statistics
- `GET /api/reports/borrower-activity` - Borrower engagement data
- `GET /api/reports/checkout-history?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD` - Checkout history with optional date filtering
- `GET /api/reports/genre-distribution` - Genre breakdown
- `GET /api/reports/overdue-items` - Potentially overdue items

## Usage

1. Start the Flask application: `python3 app.py`
2. Open your browser to `http://localhost:5000`
3. Click on the "Reports" tab
4. Click any report button to load and view the data
5. For checkout history, use the date filters to narrow down results

## Data Export

Reports are displayed in HTML tables. For data export functionality, you can:
- Copy data from browser tables
- Use browser developer tools to extract JSON from API responses
- Implement custom export features as needed

## Future Enhancements

Potential additions to the reporting system:
- CSV/Excel export functionality
- Chart/visualization integration
- Email report scheduling
- Advanced filtering options
- Custom report builder</content>
<parameter name="filePath">/Users/erickhofer/Media-inventory-system/REPORTS_README.md