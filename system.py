import sqlite3

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

def add_book(title, author=None, year_published=None, publisher=None, fiction_nonfiction=None, genre=None, description=None, status='owned'):
    """Add a new book to the inventory."""
    conn = connect_to_database()
    cursor = conn.cursor()

    media_id = generate_media_id('books')

    cursor.execute('''
        INSERT INTO books (id, title, author, year_published, publisher, fiction_nonfiction, genre, description, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', (media_id, title, author, year_published, publisher, fiction_nonfiction, genre, description, status))

    conn.commit()
    conn.close()
    return media_id

def add_video_game(title, game_system=None, genre=None, year_released=None, status='owned'):
    """Add a new video game to the inventory."""
    conn = connect_to_database()
    cursor = conn.cursor()

    media_id = generate_media_id('video_games')

    cursor.execute('''
        INSERT INTO video_games (id, title, game_system, genre, year_released, status)
        VALUES (?, ?, ?, ?, ?, ?)
    ''', (media_id, title, game_system, genre, year_released, status))

    conn.commit()
    conn.close()
    return media_id

def add_movie(title, director=None, cast=None, year_released=None, studio=None, genre=None, format=None, status='owned'):
    """Add a new movie to the inventory."""
    conn = connect_to_database()
    cursor = conn.cursor()

    media_id = generate_media_id('movies')

    cursor.execute('''
        INSERT INTO movies (id, title, director, cast, year_released, studio, genre, format, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', (media_id, title, director, cast, year_released, studio, genre, format, status))

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

def update_book(book_id, title=None, author=None, year_published=None, publisher=None, fiction_nonfiction=None, genre=None, description=None):
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

    cursor.execute('''
        UPDATE books
        SET title = ?, author = ?, year_published = ?, publisher = ?, fiction_nonfiction = ?, genre = ?, description = ?
        WHERE id = ?
    ''', (title, author, year_published, publisher, fiction_nonfiction, genre, description, book_id))

    conn.commit()
    conn.close()
    print(f"Book {book_id} has been updated.")
    return True

def update_video_game(game_id, title=None, game_system=None, genre=None, year_released=None):
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

    cursor.execute('''
        UPDATE video_games
        SET title = ?, game_system = ?, genre = ?, year_released = ?
        WHERE id = ?
    ''', (title, game_system, genre, year_released, game_id))

    conn.commit()
    conn.close()
    print(f"Video game {game_id} has been updated.")
    return True

def update_movie(movie_id, title=None, director=None, cast=None, year_released=None, studio=None, genre=None, format=None):
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

    cursor.execute('''
        UPDATE movies
        SET title = ?, director = ?, cast = ?, year_released = ?, studio = ?, genre = ?, format = ?
        WHERE id = ?
    ''', (title, director, cast, year_released, studio, genre, format, movie_id))

    conn.commit()
    conn.close()
    print(f"Movie {movie_id} has been updated.")
    return True

if __name__ == "__main__":
    create_database()