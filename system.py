import sqlite3

def create_database():
    # Connect to SQLite database (creates file if it doesn't exist)
    conn = sqlite3.connect('media_inventory.db')
    cursor = conn.cursor()

    # Drop tables if they exist to recreate with new schema
    cursor.execute('DROP TABLE IF EXISTS books')
    cursor.execute('DROP TABLE IF EXISTS video_games')
    cursor.execute('DROP TABLE IF EXISTS movies')

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

if __name__ == "__main__":
    create_database()