# Media Inventory System - Web UI

This is a comprehensive HTML/CSS/JavaScript web interface for the Media Inventory System.

## Features

- **Dashboard**: Quick overview of all inventory and statistics
- **Books Management**: Add, edit, delete, and search books
- **Video Games Management**: Add, edit, delete, and search video games
- **Movies Management**: Add, edit, delete, and search movies
- **Borrowers Management**: Add, edit, delete, and search borrowers
- **Checkout/Return**: Manage media checkouts and returns
- **Borrower History**: View complete checkout history for each borrower
- **Tools & Diagnostics**: Run database integrity checks and repairs
- **Responsive Design**: Works on desktop, tablet, and mobile devices
- **Real-time Search**: Filter items by typing in search boxes
- **Customizable UI**: Easy to modify colors, fonts, and styling

## Getting Started

### Prerequisites
- Python 3.6+
- Flask

### Installation

1. Install Flask (if not already installed):
```bash
pip3 install flask
```

2. Navigate to the project directory:
```bash
cd /Users/erickhofer/Media-inventory-system
```

### Running the Web Server

Start the Flask development server:
```bash
python3 app.py
```

The server will start on `http://localhost:5000`

Open your web browser and navigate to: **http://localhost:5000**

## Customization

### Color Scheme

The interface uses CSS custom properties (variables) for easy color customization. Edit the `:root` section in `templates/index.html`:

```css
:root {
    --primary-color: #2c3e50;      /* Header and primary elements */
    --secondary-color: #3498db;    /* Buttons and links */
    --accent-color: #e74c3c;       /* Danger/delete buttons */
    --success-color: #27ae60;      /* Success messages */
    --background-color: #ecf0f1;   /* Page background */
    --text-color: #2c3e50;         /* Text color */
    --border-color: #bdc3c7;       /* Borders */
    --light-bg: #ffffff;           /* Card backgrounds */
}
```

### Font and Typography

Modify the `body` font-family in the CSS:
```css
body {
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
}
```

### Layout Changes

The interface uses CSS Grid and Flexbox for responsive layouts. Key sections:
- `tabs`: Navigation tab styling
- `container`: Main content container (max-width: 1400px)
- `form-row`: Form input grid layout
- `stats-grid`: Dashboard statistics grid

## API Endpoints

The web interface communicates with these REST API endpoints:

### Books
- `GET /api/books` - Get all books
- `POST /api/books` - Add new book
- `PUT /api/books/<id>` - Update book
- `DELETE /api/books/<id>` - Delete book

### Video Games
- `GET /api/video_games` - Get all games
- `POST /api/video_games` - Add new game
- `PUT /api/video_games/<id>` - Update game
- `DELETE /api/video_games/<id>` - Delete game

### Movies
- `GET /api/movies` - Get all movies
- `POST /api/movies` - Add new movie
- `PUT /api/movies/<id>` - Update movie
- `DELETE /api/movies/<id>` - Delete movie

### Borrowers
- `GET /api/borrowers` - Get all borrowers
- `POST /api/borrowers` - Add new borrower
- `PUT /api/borrowers/<id>` - Update borrower
- `DELETE /api/borrowers/<id>` - Delete borrower
- `GET /api/borrowers/<id>/history` - Get borrower's checkout history

### Checkout/Return
- `POST /api/checkout` - Checkout media
- `POST /api/return` - Return media

### Diagnostics
- `GET /api/diagnostics` - Get system statistics
- `GET /api/check-integrity` - Check database integrity
- `POST /api/repair` - Repair database

## File Structure

```
Media-inventory-system/
├── app.py                 # Flask web server and API endpoints
├── system.py              # Core database and business logic
├── media_inventory.db     # SQLite database
├── templates/
│   └── index.html        # Main web interface (HTML/CSS/JS)
├── test_*.py             # Test scripts
└── README.md             # This file
```

## Browser Compatibility

- Chrome/Edge (latest)
- Firefox (latest)
- Safari (latest)
- Mobile browsers

## Tips for Customization

1. **Change Colors**: Edit the CSS variables in `templates/index.html`
2. **Add Fields**: Modify both the HTML form and the Flask API endpoint
3. **Change Layout**: Adjust grid columns with `grid-template-columns`
4. **Add Tab**: Duplicate a tab section and register in JavaScript
5. **Custom Styling**: Add CSS classes to any element

## Troubleshooting

### Port Already in Use
If port 5000 is in use, modify `app.py`:
```python
if __name__ == '__main__':
    app.run(debug=True, port=5001)  # Change to different port
```

### Database Not Found
Ensure `system.py` and `media_inventory.db` are in the same directory as `app.py`

### Styling Issues
Clear browser cache (Ctrl+Shift+Delete or Cmd+Shift+Delete)

## License

This project is open source and available for personal and commercial use.
