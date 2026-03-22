#!/usr/bin/env python3
import system

# Run diagnostics
system.run_diagnostics()

# Add some test data
print("\nAdding test data...")
borrower_id = system.add_borrower('Jane', 'Doe', '456 Oak Ave', '555-5678')
book_id = system.add_book('Test Book', 'Test Author', 2024, 'Test Publisher', 'Fiction', 'Drama', 'A test book')
game_id = system.add_video_game('Test Game', 'PlayStation', 'Action', 2023)
movie_id = system.add_movie('Test Movie', 'Test Director', 'Test Cast', 2023, 'Test Studio', 'Comedy', 'DVD')

print(f"Borrower ID: {borrower_id}")
print(f"Book ID: {book_id}")
print(f"Game ID: {game_id}")
print(f"Movie ID: {movie_id}")

# Create some checkout records
system.checkout_media(borrower_id, book_id, 'books')
system.checkout_media(borrower_id, game_id, 'video_games')

# Check database integrity with real data
system.check_database_integrity()
