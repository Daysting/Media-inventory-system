import sqlite3
import urllib.parse

# Optional dependency used for web scraping Google Images when requested.
try:
    import requests
    from bs4 import BeautifulSoup
except ImportError:
    requests = None
    BeautifulSoup = None


def create_database():
    # Connect to SQLite database (creates file if it doesn't exist)
    conn = sqlite3.connect('media_inventory.db')
    cursor = conn.cursor()

    # Drop tables if they exist to recreate with new schema
    cursor.execute('DROP TABLE IF EXISTS books')
    cursor.execute('DROP TABLE IF EXISTS video_games')
    cursor.execute('DROP TABLE IF EXISTS movies')
    cursor.execute('DROP TABLE IF EXISTS borrowers')
    cursor.execute('DROP TABLE IF EXISTS checkout_history')

    # Create books table with TEXT id
    cursor.execute('''
        CREATE TABLE books (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            author TEXT,
            year_published INTEGER,
            publisher TEXT,
            fiction_nonfiction TEXT,
            genre TEXT,
            description TEXT,
            image_url TEXT,
            status TEXT DEFAULT 'owned'
        )
    ''')

    # Create video_games table with TEXT id
    cursor.execute('''
        CREATE TABLE video_games (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            game_system TEXT,
            genre TEXT,
            year_released INTEGER,
            image_url TEXT,
            status TEXT DEFAULT 'owned'
        )
    ''')

    # Create movies table with TEXT id
    cursor.execute('''
        CREATE TABLE movies (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            director TEXT,
            cast TEXT,
            year_released INTEGER,
            studio TEXT,
            genre TEXT,
            format TEXT,
            image_url TEXT,
            status TEXT DEFAULT 'owned'
        )
    ''')

    # Create borrowers table with TEXT id
    cursor.execute('''
        CREATE TABLE borrowers (
            id TEXT PRIMARY KEY,
            first_name TEXT NOT NULL,
            last_name TEXT NOT NULL,
            address TEXT,
            phone_number TEXT
        )
    ''')

    # Create checkout_history table
    cursor.execute('''
        CREATE TABLE checkout_history (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            borrower_id TEXT NOT NULL,
            media_id TEXT NOT NULL,
            media_type TEXT NOT NULL,
            checkout_date TEXT NOT NULL,
            return_date TEXT,
            status TEXT DEFAULT 'checked_out',
            FOREIGN KEY (borrower_id) REFERENCES borrowers(id)
        )
    ''')

    # Commit changes and close connection
    conn.commit()
    conn.close()
    print("Database and tables created successfully!")

def connect_to_database():
    # Connect to existing database
    conn = sqlite3.connect('media_inventory.db')
    return conn

def generate_media_id(category):
    """
    Generate a 14-digit media ID with category-specific prefixes.
    Books: 319721XXXXXXXXX
    Video Games: 319722XXXXXXXXX
    Movies: 319723XXXXXXXXX
    """


def search_google_image(query):
    """Search Google Images and provide the first image URL result."""
    if requests is None or BeautifulSoup is None:
        raise RuntimeError(
            "requests and beautifulsoup4 are required for search_google_image. "
            "Install with: pip install requests beautifulsoup4"
        )

    if not query or not query.strip():
        raise ValueError('Query must be non-empty')

    headers = {
        'User-Agent': (
            'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36'
        )
    }
    query_encoded = urllib.parse.quote_plus(query)
    url = f'https://www.google.com/search?tbm=isch&q={query_encoded}'

    response = requests.get(url, headers=headers, timeout=15)
    response.raise_for_status()

    soup = BeautifulSoup(response.text, 'html.parser')

    # Prefer data-src if available, else src
    for img in soup.find_all('img'):
        src = img.get('data-src') or img.get('src')
        if src and src.startswith('http'):
            return src

    raise RuntimeError('No image URL could be extracted from Google image search response.')


# Reporting Functions
def get_inventory_summary():
    """Get summary statistics for all media inventory."""
    conn = connect_to_database()
    cursor = conn.cursor()

    # Books summary
    cursor.execute("SELECT COUNT(*), SUM(CASE WHEN status = 'owned' THEN 1 ELSE 0 END) FROM books")
    books_total, books_owned = cursor.fetchone()

    # Video games summary
    cursor.execute("SELECT COUNT(*), SUM(CASE WHEN status = 'owned' THEN 1 ELSE 0 END) FROM video_games")
    games_total, games_owned = cursor.fetchone()

    # Movies summary
    cursor.execute("SELECT COUNT(*), SUM(CASE WHEN status = 'owned' THEN 1 ELSE 0 END) FROM movies")
    movies_total, movies_owned = cursor.fetchone()

    # Borrowers summary
    cursor.execute("SELECT COUNT(*) FROM borrowers")
    borrowers_total = cursor.fetchone()[0]

    # Checkout summary
    cursor.execute("SELECT COUNT(*) FROM checkout_history WHERE status = 'checked_out'")
    currently_checked_out = cursor.fetchone()[0]

    cursor.execute("SELECT COUNT(*) FROM checkout_history WHERE status = 'returned'")
    total_checkouts = cursor.fetchone()[0]

    conn.close()

    return {
        'books': {'total': books_total, 'owned': books_owned or 0},
        'video_games': {'total': games_total, 'owned': games_owned or 0},
        'movies': {'total': movies_total, 'owned': movies_owned or 0},
        'borrowers': {'total': borrowers_total},
        'checkouts': {'currently_checked_out': currently_checked_out, 'total_history': total_checkouts}
    }


def get_borrower_activity_report():
    """Get detailed borrower activity report."""
    conn = connect_to_database()
    cursor = conn.cursor()

    cursor.execute('''
        SELECT
            b.id,
            b.first_name,
            b.last_name,
            COUNT(CASE WHEN ch.status = 'checked_out' THEN 1 END) as currently_checked_out,
            COUNT(CASE WHEN ch.status = 'returned' THEN 1 END) as total_returned,
            MAX(ch.checkout_date) as last_activity
        FROM borrowers b
        LEFT JOIN checkout_history ch ON b.id = ch.borrower_id
        GROUP BY b.id, b.first_name, b.last_name
        ORDER BY total_returned DESC, currently_checked_out DESC
    ''')

    borrowers = cursor.fetchall()
    conn.close()

    return [
        {
            'id': b[0],
            'name': f"{b[1]} {b[2]}",
            'currently_checked_out': b[3],
            'total_returned': b[4],
            'last_activity': b[5]
        }
        for b in borrowers
    ]


def get_checkout_history_report(start_date=None, end_date=None):
    """Get checkout history report with optional date filtering."""
    conn = connect_to_database()
    cursor = conn.cursor()

    query = '''
        SELECT
            ch.id,
            ch.borrower_id,
            b.first_name,
            b.last_name,
            ch.media_id,
            ch.media_type,
            CASE
                WHEN ch.media_type = 'books' THEN bk.title
                WHEN ch.media_type = 'video_games' THEN vg.title
                WHEN ch.media_type = 'movies' THEN mv.title
            END as media_title,
            ch.checkout_date,
            ch.return_date,
            ch.status
        FROM checkout_history ch
        JOIN borrowers b ON ch.borrower_id = b.id
        LEFT JOIN books bk ON ch.media_type = 'books' AND ch.media_id = bk.id
        LEFT JOIN video_games vg ON ch.media_type = 'video_games' AND ch.media_id = vg.id
        LEFT JOIN movies mv ON ch.media_type = 'movies' AND ch.media_id = mv.id
    '''

    params = []
    if start_date or end_date:
        conditions = []
        if start_date:
            conditions.append("ch.checkout_date >= ?")
            params.append(start_date)
        if end_date:
            conditions.append("ch.checkout_date <= ?")
            params.append(end_date)
        query += " WHERE " + " AND ".join(conditions)

    query += " ORDER BY ch.checkout_date DESC"

    cursor.execute(query, params)
    history = cursor.fetchall()
    conn.close()

    return [
        {
            'id': h[0],
            'borrower_id': h[1],
            'borrower_name': f"{h[2]} {h[3]}",
            'media_id': h[4],
            'media_type': h[5],
            'media_title': h[6],
            'checkout_date': h[7],
            'return_date': h[8],
            'status': h[9]
        }
        for h in history
    ]


def get_genre_distribution():
    """Get distribution of media by genre."""
    conn = connect_to_database()
    cursor = conn.cursor()

    # Books by genre
    cursor.execute('''
        SELECT genre, COUNT(*) as count
        FROM books
        WHERE genre IS NOT NULL AND genre != ''
        GROUP BY genre
        ORDER BY count DESC
    ''')
    books_genres = cursor.fetchall()

    # Video games by genre
    cursor.execute('''
        SELECT genre, COUNT(*) as count
        FROM video_games
        WHERE genre IS NOT NULL AND genre != ''
        GROUP BY genre
        ORDER BY count DESC
    ''')
    games_genres = cursor.fetchall()

    # Movies by genre
    cursor.execute('''
        SELECT genre, COUNT(*) as count
        FROM movies
        WHERE genre IS NOT NULL AND genre != ''
        GROUP BY genre
        ORDER BY count DESC
    ''')
    movies_genres = cursor.fetchall()

    conn.close()

    return {
        'books': [{'genre': g[0], 'count': g[1]} for g in books_genres],
        'video_games': [{'genre': g[0], 'count': g[1]} for g in games_genres],
        'movies': [{'genre': g[0], 'count': g[1]} for g in movies_genres]
    }


def get_overdue_items():
    """Get items that are currently checked out (simplified overdue check)."""
    from datetime import datetime, timedelta

    conn = connect_to_database()
    cursor = conn.cursor()

    # For simplicity, consider items checked out for more than 30 days as "potentially overdue"
    thirty_days_ago = (datetime.now() - timedelta(days=30)).strftime('%Y-%m-%d %H:%M:%S')

    cursor.execute('''
        SELECT
            ch.media_id,
            ch.media_type,
            CASE
                WHEN ch.media_type = 'books' THEN bk.title
                WHEN ch.media_type = 'video_games' THEN vg.title
                WHEN ch.media_type = 'movies' THEN mv.title
            END as media_title,
            b.first_name,
            b.last_name,
            ch.checkout_date
        FROM checkout_history ch
        JOIN borrowers b ON ch.borrower_id = b.id
        LEFT JOIN books bk ON ch.media_type = 'books' AND ch.media_id = bk.id
        LEFT JOIN video_games vg ON ch.media_type = 'video_games' AND ch.media_id = vg.id
        LEFT JOIN movies mv ON ch.media_type = 'movies' AND ch.media_id = mv.id
        WHERE ch.status = 'checked_out' AND ch.checkout_date < ?
        ORDER BY ch.checkout_date ASC
    ''', (thirty_days_ago,))

    overdue = cursor.fetchall()
    conn.close()

    return [
        {
            'media_id': o[0],
            'media_type': o[1],
            'media_title': o[2],
            'borrower_name': f"{o[3]} {o[4]}",
            'checkout_date': o[5]
        }
        for o in overdue
    ]
    prefixes = {
        'books': '319721',
        'video_games': '319722',
        'movies': '319723'
    }

    if category not in prefixes:
        raise ValueError("Invalid category. Must be 'books', 'video_games', or 'movies'")

    prefix = prefixes[category]
    conn = connect_to_database()
    cursor = conn.cursor()

    table_map = {
        'books': 'books',
        'video_games': 'video_games',
        'movies': 'movies'
    }

    table = table_map[category]

    # Get the maximum existing ID number for this category
    cursor.execute(f"SELECT id FROM {table} WHERE id LIKE '{prefix}%' ORDER BY id DESC LIMIT 1")
    result = cursor.fetchone()

    if result:
        # Extract the numeric part after prefix
        existing_id = result[0]
        if len(existing_id) == 14 and existing_id.startswith(prefix):
            current_num = int(existing_id[6:])  # After 319721 (6 chars)
            next_num = current_num + 1
        else:
            next_num = 1
    else:
        next_num = 1

    # Generate new ID: prefix + 8 digits (since prefix is 6 chars, total 14)
    # 319721 is 6 chars, need 8 more digits to make 14 total
    new_id = f"{prefix}{next_num:08d}"

    conn.close()
    return new_id

def add_book(title, author=None, year_published=None, publisher=None, fiction_nonfiction=None, genre=None, description=None, image_url=None, status='owned'):
    """Add a new book to the inventory."""
    conn = connect_to_database()
    cursor = conn.cursor()

    media_id = generate_media_id('books')

    cursor.execute('''
        INSERT INTO books (id, title, author, year_published, publisher, fiction_nonfiction, genre, description, image_url, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', (media_id, title, author, year_published, publisher, fiction_nonfiction, genre, description, image_url, status))

    conn.commit()
    conn.close()
    return media_id

def add_video_game(title, game_system=None, genre=None, year_released=None, image_url=None, status='owned'):
    """Add a new video game to the inventory."""
    conn = connect_to_database()
    cursor = conn.cursor()

    media_id = generate_media_id('video_games')

    cursor.execute('''
        INSERT INTO video_games (id, title, game_system, genre, year_released, image_url, status)
        VALUES (?, ?, ?, ?, ?, ?, ?)
    ''', (media_id, title, game_system, genre, year_released, image_url, status))

    conn.commit()
    conn.close()
    return media_id

def add_movie(title, director=None, cast=None, year_released=None, studio=None, genre=None, format=None, image_url=None, status='owned'):
    """Add a new movie to the inventory."""
    conn = connect_to_database()
    cursor = conn.cursor()

    media_id = generate_media_id('movies')

    cursor.execute('''
        INSERT INTO movies (id, title, director, cast, year_released, studio, genre, format, image_url, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', (media_id, title, director, cast, year_released, studio, genre, format, image_url, status))

    conn.commit()
    conn.close()
    return media_id

def generate_borrower_id():
    """
    Generate a 14-digit borrower ID starting with 21972.
    Format: 21972XXXXXXXX where X are digits.
    """
    prefix = "21972"
    conn = connect_to_database()
    cursor = conn.cursor()

    # Get the maximum existing borrower ID
    cursor.execute(f"SELECT id FROM borrowers WHERE id LIKE '{prefix}%' ORDER BY id DESC LIMIT 1")
    result = cursor.fetchone()

    if result:
        # Extract the numeric part after prefix
        existing_id = result[0]
        if len(existing_id) == 14 and existing_id.startswith(prefix):
            current_num = int(existing_id[5:])  # After 21972 (5 chars)
            next_num = current_num + 1
        else:
            next_num = 1
    else:
        next_num = 1

    # Generate new ID: prefix + 9 digits (since prefix is 5 chars, total 14)
    new_id = f"{prefix}{next_num:09d}"

    conn.close()
    return new_id

def add_borrower(first_name, last_name, address=None, phone_number=None):
    """Add a new borrower to the system."""
    conn = connect_to_database()
    cursor = conn.cursor()

    borrower_id = generate_borrower_id()

    cursor.execute('''
        INSERT INTO borrowers (id, first_name, last_name, address, phone_number)
        VALUES (?, ?, ?, ?, ?)
    ''', (borrower_id, first_name, last_name, address, phone_number))

    conn.commit()
    conn.close()
    return borrower_id

def checkout_media(borrower_id, media_id, media_type, checkout_date=None):
    """Record a media checkout for a borrower."""
    from datetime import datetime
    
    if checkout_date is None:
        checkout_date = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    
    if media_type not in ['books', 'video_games', 'movies']:
        raise ValueError("Invalid media_type. Must be 'books', 'video_games', or 'movies'")
    
    conn = connect_to_database()
    cursor = conn.cursor()

    cursor.execute('''
        INSERT INTO checkout_history (borrower_id, media_id, media_type, checkout_date, status)
        VALUES (?, ?, ?, ?, 'checked_out')
    ''', (borrower_id, media_id, media_type, checkout_date))

    conn.commit()
    conn.close()

def return_media(borrower_id, media_id, return_date=None):
    """Record a media return for a borrower."""
    from datetime import datetime
    
    if return_date is None:
        return_date = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    
    conn = connect_to_database()
    cursor = conn.cursor()

    # Find the most recent checkout record for this borrower and media that hasn't been returned
    cursor.execute('''
        UPDATE checkout_history
        SET return_date = ?, status = 'returned'
        WHERE borrower_id = ? AND media_id = ? AND status = 'checked_out'
        ORDER BY checkout_date DESC
        LIMIT 1
    ''', (return_date, borrower_id, media_id))

    conn.commit()
    conn.close()

def get_borrower_history(borrower_id):
    """Get all checkout history for a borrower."""
    conn = connect_to_database()
    cursor = conn.cursor()

    cursor.execute('''
        SELECT id, media_id, media_type, checkout_date, return_date, status
        FROM checkout_history
        WHERE borrower_id = ?
        ORDER BY checkout_date DESC
    ''', (borrower_id,))

    history = cursor.fetchall()
    conn.close()
    return history

def get_borrower_media_checkout_count(borrower_id, media_id):
    """Get how many times a borrower has checked out a specific piece of media."""
    conn = connect_to_database()
    cursor = conn.cursor()

    cursor.execute('''
        SELECT COUNT(*) FROM checkout_history
        WHERE borrower_id = ? AND media_id = ? AND status = 'returned'
    ''', (borrower_id, media_id))

    count = cursor.fetchone()[0]
    conn.close()
    return count

def get_borrower_info(borrower_id):
    """Get complete borrower information with checkout statistics."""
    conn = connect_to_database()
    cursor = conn.cursor()

    # Get borrower info
    cursor.execute('SELECT * FROM borrowers WHERE id = ?', (borrower_id,))
    borrower = cursor.fetchone()

    if not borrower:
        conn.close()
        return None

    # Get checkout history
    cursor.execute('''
        SELECT COUNT(*) FROM checkout_history WHERE borrower_id = ? AND status = 'returned'
    ''', (borrower_id,))
    total_returns = cursor.fetchone()[0]

    # Get currently checked out items
    cursor.execute('''
        SELECT COUNT(*) FROM checkout_history WHERE borrower_id = ? AND status = 'checked_out'
    ''', (borrower_id,))
    currently_checked_out = cursor.fetchone()[0]

    conn.close()

    return {
        'id': borrower[0],
        'first_name': borrower[1],
        'last_name': borrower[2],
        'address': borrower[3],
        'phone_number': borrower[4],
        'total_items_returned': total_returns,
        'currently_checked_out': currently_checked_out
    }

def delete_borrower(borrower_id):
    """Delete a borrower and their checkout history from the system."""
    conn = connect_to_database()
    cursor = conn.cursor()

    # Delete checkout history for this borrower
    cursor.execute('DELETE FROM checkout_history WHERE borrower_id = ?', (borrower_id,))
    
    # Delete the borrower
    cursor.execute('DELETE FROM borrowers WHERE id = ?', (borrower_id,))

    conn.commit()
    conn.close()
    print(f"Borrower {borrower_id} and their checkout history have been deleted.")

def delete_book(book_id):
    """Delete a book from the inventory."""
    conn = connect_to_database()
    cursor = conn.cursor()

    # Delete checkout history associated with this book
    cursor.execute('DELETE FROM checkout_history WHERE media_id = ? AND media_type = ?', (book_id, 'books'))
    
    # Delete the book
    cursor.execute('DELETE FROM books WHERE id = ?', (book_id,))

    conn.commit()
    conn.close()
    print(f"Book {book_id} and its checkout history have been deleted.")

def delete_video_game(game_id):
    """Delete a video game from the inventory."""
    conn = connect_to_database()
    cursor = conn.cursor()

    # Delete checkout history associated with this game
    cursor.execute('DELETE FROM checkout_history WHERE media_id = ? AND media_type = ?', (game_id, 'video_games'))
    
    # Delete the video game
    cursor.execute('DELETE FROM video_games WHERE id = ?', (game_id,))

    conn.commit()
    conn.close()
    print(f"Video game {game_id} and its checkout history have been deleted.")

def delete_movie(movie_id):
    """Delete a movie from the inventory."""
    conn = connect_to_database()
    cursor = conn.cursor()

    # Delete checkout history associated with this movie
    cursor.execute('DELETE FROM checkout_history WHERE media_id = ? AND media_type = ?', (movie_id, 'movies'))
    
    # Delete the movie
    cursor.execute('DELETE FROM movies WHERE id = ?', (movie_id,))

    conn.commit()
    conn.close()
    print(f"Movie {movie_id} and its checkout history have been deleted.")

def update_borrower(borrower_id, first_name=None, last_name=None, address=None, phone_number=None):
    """Update borrower information."""
    conn = connect_to_database()
    cursor = conn.cursor()

    # Get current borrower data
    cursor.execute('SELECT * FROM borrowers WHERE id = ?', (borrower_id,))
    borrower = cursor.fetchone()

    if not borrower:
        conn.close()
        print(f"Borrower {borrower_id} not found.")
        return False

    # Use new values or keep existing ones
    first_name = first_name if first_name is not None else borrower[1]
    last_name = last_name if last_name is not None else borrower[2]
    address = address if address is not None else borrower[3]
    phone_number = phone_number if phone_number is not None else borrower[4]

    cursor.execute('''
        UPDATE borrowers
        SET first_name = ?, last_name = ?, address = ?, phone_number = ?
        WHERE id = ?
    ''', (first_name, last_name, address, phone_number, borrower_id))

    conn.commit()
    conn.close()
    print(f"Borrower {borrower_id} has been updated.")
    return True

def update_book(book_id, title=None, author=None, year_published=None, publisher=None, fiction_nonfiction=None, genre=None, description=None, image_url=None):
    """Update book information."""
    conn = connect_to_database()
    cursor = conn.cursor()

    # Get current book data
    cursor.execute('SELECT * FROM books WHERE id = ?', (book_id,))
    book = cursor.fetchone()

    if not book:
        conn.close()
        print(f"Book {book_id} not found.")
        return False

    # Use new values or keep existing ones
    title = title if title is not None else book[1]
    author = author if author is not None else book[2]
    year_published = year_published if year_published is not None else book[3]
    publisher = publisher if publisher is not None else book[4]
    fiction_nonfiction = fiction_nonfiction if fiction_nonfiction is not None else book[5]
    genre = genre if genre is not None else book[6]
    description = description if description is not None else book[7]
    image_url = image_url if image_url is not None else book[8]

    cursor.execute('''
        UPDATE books
        SET title = ?, author = ?, year_published = ?, publisher = ?, fiction_nonfiction = ?, genre = ?, description = ?, image_url = ?
        WHERE id = ?
    ''', (title, author, year_published, publisher, fiction_nonfiction, genre, description, image_url, book_id))

    conn.commit()
    conn.close()
    print(f"Book {book_id} has been updated.")
    return True

def update_video_game(game_id, title=None, game_system=None, genre=None, year_released=None, image_url=None):
    """Update video game information."""
    conn = connect_to_database()
    cursor = conn.cursor()

    # Get current game data
    cursor.execute('SELECT * FROM video_games WHERE id = ?', (game_id,))
    game = cursor.fetchone()

    if not game:
        conn.close()
        print(f"Video game {game_id} not found.")
        return False

    # Use new values or keep existing ones
    title = title if title is not None else game[1]
    game_system = game_system if game_system is not None else game[2]
    genre = genre if genre is not None else game[3]
    year_released = year_released if year_released is not None else game[4]
    image_url = image_url if image_url is not None else game[5]

    cursor.execute('''
        UPDATE video_games
        SET title = ?, game_system = ?, genre = ?, year_released = ?, image_url = ?
        WHERE id = ?
    ''', (title, game_system, genre, year_released, image_url, game_id))

    conn.commit()
    conn.close()
    print(f"Video game {game_id} has been updated.")
    return True

def update_movie(movie_id, title=None, director=None, cast=None, year_released=None, studio=None, genre=None, format=None, image_url=None):
    """Update movie information."""
    conn = connect_to_database()
    cursor = conn.cursor()

    # Get current movie data
    cursor.execute('SELECT * FROM movies WHERE id = ?', (movie_id,))
    movie = cursor.fetchone()

    if not movie:
        conn.close()
        print(f"Movie {movie_id} not found.")
        return False

    # Use new values or keep existing ones
    title = title if title is not None else movie[1]
    director = director if director is not None else movie[2]
    cast = cast if cast is not None else movie[3]
    year_released = year_released if year_released is not None else movie[4]
    studio = studio if studio is not None else movie[5]
    genre = genre if genre is not None else movie[6]
    format = format if format is not None else movie[7]
    image_url = image_url if image_url is not None else movie[8]

    cursor.execute('''
        UPDATE movies
        SET title = ?, director = ?, cast = ?, year_released = ?, studio = ?, genre = ?, format = ?, image_url = ?
        WHERE id = ?
    ''', (title, director, cast, year_released, studio, genre, format, image_url, movie_id))

    conn.commit()
    conn.close()
    print(f"Movie {movie_id} has been updated.")
    return True

def check_database_integrity():
    """Run comprehensive database integrity checks."""
    print("=" * 60)
    print("DATABASE INTEGRITY CHECK")
    print("=" * 60)
    
    conn = connect_to_database()
    cursor = conn.cursor()
    issues_found = 0
    
    # Check 1: Verify all tables exist
    print("\n[1] Checking table existence...")
    required_tables = ['books', 'video_games', 'movies', 'borrowers', 'checkout_history']
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
    existing_tables = [row[0] for row in cursor.fetchall()]
    
    for table in required_tables:
        if table in existing_tables:
            print(f"  ✓ Table '{table}' exists")
        else:
            print(f"  ✗ Table '{table}' MISSING")
            issues_found += 1
    
    # Check 2: Verify data counts
    print("\n[2] Checking record counts...")
    counts = {}
    for table in required_tables:
        cursor.execute(f"SELECT COUNT(*) FROM {table}")
        count = cursor.fetchone()[0]
        counts[table] = count
        print(f"  - {table}: {count} records")
    
    # Check 3: Verify ID format compliance
    print("\n[3] Checking ID format compliance...")
    
    # Check books IDs
    cursor.execute("SELECT id FROM books WHERE id NOT LIKE '319721%' OR LENGTH(id) != 14")
    bad_books = cursor.fetchall()
    if bad_books:
        print(f"  ✗ {len(bad_books)} book(s) with invalid ID format")
        issues_found += len(bad_books)
    else:
        print(f"  ✓ All book IDs valid (319721xxxxxxxx format)")
    
    # Check video games IDs
    cursor.execute("SELECT id FROM video_games WHERE id NOT LIKE '319722%' OR LENGTH(id) != 14")
    bad_games = cursor.fetchall()
    if bad_games:
        print(f"  ✗ {len(bad_games)} video game(s) with invalid ID format")
        issues_found += len(bad_games)
    else:
        print(f"  ✓ All video game IDs valid (319722xxxxxxxx format)")
    
    # Check movies IDs
    cursor.execute("SELECT id FROM movies WHERE id NOT LIKE '319723%' OR LENGTH(id) != 14")
    bad_movies = cursor.fetchall()
    if bad_movies:
        print(f"  ✗ {len(bad_movies)} movie(s) with invalid ID format")
        issues_found += len(bad_movies)
    else:
        print(f"  ✓ All movie IDs valid (319723xxxxxxxx format)")
    
    # Check borrower IDs
    cursor.execute("SELECT id FROM borrowers WHERE id NOT LIKE '21972%' OR LENGTH(id) != 14")
    bad_borrowers = cursor.fetchall()
    if bad_borrowers:
        print(f"  ✗ {len(bad_borrowers)} borrower(s) with invalid ID format")
        issues_found += len(bad_borrowers)
    else:
        print(f"  ✓ All borrower IDs valid (21972xxxxxxxxx format)")
    
    # Check 4: Verify foreign key integrity
    print("\n[4] Checking foreign key integrity...")
    cursor.execute("""
        SELECT COUNT(*) FROM checkout_history 
        WHERE borrower_id NOT IN (SELECT id FROM borrowers)
    """)
    orphaned_checkouts = cursor.fetchone()[0]
    if orphaned_checkouts > 0:
        print(f"  ✗ {orphaned_checkouts} checkout record(s) with non-existent borrower")
        issues_found += orphaned_checkouts
    else:
        print(f"  ✓ No orphaned checkout records")
    
    # Check 5: Verify checkout_history validity
    print("\n[5] Checking checkout history validity...")
    cursor.execute("""
        SELECT COUNT(*) FROM checkout_history 
        WHERE status NOT IN ('checked_out', 'returned')
    """)
    invalid_status = cursor.fetchone()[0]
    if invalid_status > 0:
        print(f"  ✗ {invalid_status} checkout record(s) with invalid status")
        issues_found += invalid_status
    else:
        print(f"  ✓ All checkout records have valid status")
    
    # Check 6: Verify required fields
    print("\n[6] Checking required fields...")
    
    cursor.execute("SELECT COUNT(*) FROM books WHERE title IS NULL OR title = ''")
    missing_titles = cursor.fetchone()[0]
    if missing_titles > 0:
        print(f"  ✗ {missing_titles} book(s) with missing title")
        issues_found += missing_titles
    else:
        print(f"  ✓ All books have titles")
    
    cursor.execute("SELECT COUNT(*) FROM borrowers WHERE first_name IS NULL OR first_name = '' OR last_name IS NULL OR last_name = ''")
    missing_names = cursor.fetchone()[0]
    if missing_names > 0:
        print(f"  ✗ {missing_names} borrower(s) with missing name")
        issues_found += missing_names
    else:
        print(f"  ✓ All borrowers have names")
    
    conn.close()
    
    # Summary
    print("\n" + "=" * 60)
    if issues_found == 0:
        print("✓ DATABASE IS HEALTHY - NO ISSUES FOUND")
    else:
        print(f"✗ DATABASE HAS {issues_found} ISSUE(S) DETECTED")
    print("=" * 60 + "\n")
    
    return issues_found == 0

def repair_database():
    """Attempt to repair common database issues."""
    print("=" * 60)
    print("DATABASE REPAIR")
    print("=" * 60)
    
    conn = connect_to_database()
    cursor = conn.cursor()
    repairs_made = 0
    
    # Repair 1: Remove orphaned checkout history
    print("\n[1] Checking for orphaned checkout records...")
    cursor.execute("""
        SELECT COUNT(*) FROM checkout_history 
        WHERE borrower_id NOT IN (SELECT id FROM borrowers)
    """)
    orphaned_count = cursor.fetchone()[0]
    if orphaned_count > 0:
        cursor.execute("""
            DELETE FROM checkout_history 
            WHERE borrower_id NOT IN (SELECT id FROM borrowers)
        """)
        print(f"  ✓ Removed {orphaned_count} orphaned checkout record(s)")
        repairs_made += 1
    else:
        print(f"  ✓ No orphaned records found")
    
    # Repair 2: Fix invalid checkout status
    print("\n[2] Checking for invalid checkout status...")
    cursor.execute("""
        SELECT COUNT(*) FROM checkout_history 
        WHERE status NOT IN ('checked_out', 'returned')
    """)
    invalid_status_count = cursor.fetchone()[0]
    if invalid_status_count > 0:
        cursor.execute("""
            UPDATE checkout_history 
            SET status = 'returned' 
            WHERE status NOT IN ('checked_out', 'returned')
        """)
        print(f"  ✓ Fixed {invalid_status_count} invalid status record(s)")
        repairs_made += 1
    else:
        print(f"  ✓ No invalid status records found")
    
    # Repair 3: Clean up empty titles
    print("\n[3] Checking for missing required fields...")
    cursor.execute("SELECT COUNT(*) FROM books WHERE title IS NULL OR title = ''")
    missing_books = cursor.fetchone()[0]
    if missing_books > 0:
        cursor.execute("UPDATE books SET title = '[Unknown Title]' WHERE title IS NULL OR title = ''")
        print(f"  ✓ Fixed {missing_books} book(s) with missing title")
        repairs_made += 1
    
    cursor.execute("SELECT COUNT(*) FROM borrowers WHERE first_name IS NULL OR first_name = ''")
    missing_first = cursor.fetchone()[0]
    if missing_first > 0:
        cursor.execute("UPDATE borrowers SET first_name = '[Unknown]' WHERE first_name IS NULL OR first_name = ''")
        print(f"  ✓ Fixed {missing_first} borrower(s) with missing first name")
        repairs_made += 1
    
    cursor.execute("SELECT COUNT(*) FROM borrowers WHERE last_name IS NULL OR last_name = ''")
    missing_last = cursor.fetchone()[0]
    if missing_last > 0:
        cursor.execute("UPDATE borrowers SET last_name = '[Unknown]' WHERE last_name IS NULL OR last_name = ''")
        print(f"  ✓ Fixed {missing_last} borrower(s) with missing last name")
        repairs_made += 1
    
    conn.commit()
    conn.close()
    
    print("\n" + "=" * 60)
    print(f"REPAIR COMPLETE - {repairs_made} repair operation(s) performed")
    print("=" * 60 + "\n")

def run_diagnostics():
    """Run full diagnostic tests on the system."""
    print("=" * 60)
    print("SYSTEM DIAGNOSTICS")
    print("=" * 60)
    
    tests_passed = 0
    tests_failed = 0
    
    # Test 1: Database connectivity
    print("\n[TEST 1] Database Connectivity")
    try:
        conn = connect_to_database()
        conn.close()
        print("  ✓ Database connection successful")
        tests_passed += 1
    except Exception as e:
        print(f"  ✗ Database connection failed: {e}")
        tests_failed += 1
        return
    
    # Test 2: Media ID generation
    print("\n[TEST 2] Media ID Generation")
    try:
        test_book_id = generate_media_id('books')
        test_game_id = generate_media_id('video_games')
        test_movie_id = generate_media_id('movies')
        
        if test_book_id.startswith('319721') and len(test_book_id) == 14:
            print(f"  ✓ Book ID generation working: {test_book_id}")
            tests_passed += 1
        else:
            print(f"  ✗ Book ID format invalid: {test_book_id}")
            tests_failed += 1
        
        if test_game_id.startswith('319722') and len(test_game_id) == 14:
            print(f"  ✓ Video game ID generation working: {test_game_id}")
            tests_passed += 1
        else:
            print(f"  ✗ Video game ID format invalid: {test_game_id}")
            tests_failed += 1
        
        if test_movie_id.startswith('319723') and len(test_movie_id) == 14:
            print(f"  ✓ Movie ID generation working: {test_movie_id}")
            tests_passed += 1
        else:
            print(f"  ✗ Movie ID format invalid: {test_movie_id}")
            tests_failed += 1
    except Exception as e:
        print(f"  ✗ ID generation failed: {e}")
        tests_failed += 3
    
    # Test 3: Borrower ID generation
    print("\n[TEST 3] Borrower ID Generation")
    try:
        test_borrower_id = generate_borrower_id()
        if test_borrower_id.startswith('21972') and len(test_borrower_id) == 14:
            print(f"  ✓ Borrower ID generation working: {test_borrower_id}")
            tests_passed += 1
        else:
            print(f"  ✗ Borrower ID format invalid: {test_borrower_id}")
            tests_failed += 1
    except Exception as e:
        print(f"  ✗ Borrower ID generation failed: {e}")
        tests_failed += 1
    
    # Test 4: Database operations
    print("\n[TEST 4] Database Operations")
    try:
        # Test add and retrieve
        test_book = add_book('Diagnostic Test Book', 'Test Author', 2024)
        conn = connect_to_database()
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM books WHERE id = ?", (test_book,))
        result = cursor.fetchone()
        conn.close()
        
        if result:
            print(f"  ✓ Book add/retrieve working")
            tests_passed += 1
            # Clean up
            delete_book(test_book)
        else:
            print(f"  ✗ Book add/retrieve failed")
            tests_failed += 1
    except Exception as e:
        print(f"  ✗ Database operations failed: {e}")
        tests_failed += 1
    
    # Summary
    print("\n" + "=" * 60)
    print(f"DIAGNOSTICS COMPLETE")
    print(f"  Passed: {tests_passed}")
    print(f"  Failed: {tests_failed}")
    if tests_failed == 0:
        print("  ✓ ALL TESTS PASSED")
    else:
        print(f"  ✗ {tests_failed} TEST(S) FAILED")
    print("=" * 60 + "\n")

if __name__ == "__main__":
    create_database()