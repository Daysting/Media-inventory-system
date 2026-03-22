#!/usr/bin/env python3
import system

# Create some test data
print("Creating test data...")
borrower_id = system.add_borrower('John', 'Smith', '123 Main St', '555-1234')
book_id = system.add_book('Test Book', 'Test Author', 2020, 'Test Publisher', 'Fiction', 'Fiction', 'Test Description')
game_id = system.add_video_game('Test Game', 'Nintendo', 'Action', 2019)
movie_id = system.add_movie('Test Movie', 'Test Director', 'Test Cast', 2021, 'Test Studio', 'Action', 'Blu-Ray')

print(f'Created Borrower ID: {borrower_id}')
print(f'Created Book ID: {book_id}')
print(f'Created Game ID: {game_id}')
print(f'Created Movie ID: {movie_id}')

# Test checkout
system.checkout_media(borrower_id, book_id, 'books')
print(f'\nBook checked out by borrower')

# Get borrower info
info = system.get_borrower_info(borrower_id)
print(f'\nBefore update:')
print(f'  Name: {info["first_name"]} {info["last_name"]}')
print(f'  Phone: {info["phone_number"]}')

# Test update functions
print(f'\nUpdating information...')
system.update_borrower(borrower_id, phone_number='555-9999')
system.update_book(book_id, author='Updated Author')
system.update_video_game(game_id, genre='RPG')
system.update_movie(movie_id, format='4K Blu-Ray')

# Get updated info
info = system.get_borrower_info(borrower_id)
print(f'\nAfter update:')
print(f'  Name: {info["first_name"]} {info["last_name"]}')
print(f'  Phone: {info["phone_number"]}')

# Test delete functions
print(f'\nDeleting media and borrower...')
system.delete_book(book_id)
system.delete_video_game(game_id)
system.delete_movie(movie_id)
system.delete_borrower(borrower_id)

print(f'\nAll tests completed successfully!')
