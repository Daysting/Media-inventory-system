#!/usr/bin/env python3
import system
import sqlite3

# Create some intentional problems to test repair

print("Creating test database with intentional issues...\n")

conn = system.connect_to_database()
cursor = conn.cursor()

# Add a book with a missing title
cursor.execute('''
    INSERT INTO books (id, title, author, year_published, publisher, fiction_nonfiction, genre, description, status)
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
''', ('31972100000099', '', 'Test Author', 2020, 'Test Publisher', 'Fiction', 'Drama', 'A book with no title', 'owned'))

# Add a borrower with missing name
cursor.execute('''
    INSERT INTO borrowers (id, first_name, last_name, address, phone_number)
    VALUES (?, ?, ?, ?, ?)
''', ('21972000000099', '', 'Smith', '123 Main St', '555-1234'))

# Add an orphaned checkout record
cursor.execute('''
    INSERT INTO checkout_history (borrower_id, media_id, media_type, checkout_date, status)
    VALUES (?, ?, ?, ?, ?)
''', ('21972000000999', '31972100000088', 'books', '2024-01-01 10:00:00', 'checked_out'))

# Add a checkout with invalid status
cursor.execute('''
    INSERT INTO checkout_history (borrower_id, media_id, media_type, checkout_date, status)
    VALUES (?, ?, ?, ?, ?)
''', ('21972000000099', '31972100000099', 'books', '2024-02-01 10:00:00', 'unknown_status'))

conn.commit()
conn.close()

# Run integrity check to find issues
print("Running integrity check to detect issues...")
system.check_database_integrity()

# Repair the database
print("Repairing database...")
system.repair_database()

# Run integrity check again to verify repairs
print("Running integrity check again after repairs...")
system.check_database_integrity()
