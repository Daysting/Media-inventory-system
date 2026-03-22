from flask import Flask, render_template, request, jsonify
import system
import traceback

app = Flask(__name__)

@app.route('/')
def index():
    return render_template('index.html')

# Books endpoints
@app.route('/api/books', methods=['GET'])
def get_books():
    try:
        conn = system.connect_to_database()
        cursor = conn.cursor()
        cursor.execute('SELECT * FROM books ORDER BY title')
        books = cursor.fetchall()
        conn.close()
        
        return jsonify({
            'success': True,
            'books': [
                {
                    'id': book[0],
                    'title': book[1],
                    'author': book[2],
                    'year_published': book[3],
                    'publisher': book[4],
                    'fiction_nonfiction': book[5],
                    'genre': book[6],
                    'description': book[7],
                    'status': book[8]
                }
                for book in books
            ]
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/books', methods=['POST'])
def add_book():
    try:
        data = request.json
        book_id = system.add_book(
            data.get('title'),
            data.get('author'),
            data.get('year_published'),
            data.get('publisher'),
            data.get('fiction_nonfiction'),
            data.get('genre'),
            data.get('description')
        )
        return jsonify({'success': True, 'book_id': book_id})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/books/<book_id>', methods=['DELETE'])
def delete_book(book_id):
    try:
        system.delete_book(book_id)
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/books/<book_id>', methods=['PUT'])
def update_book(book_id):
    try:
        data = request.json
        system.update_book(
            book_id,
            data.get('title'),
            data.get('author'),
            data.get('year_published'),
            data.get('publisher'),
            data.get('fiction_nonfiction'),
            data.get('genre'),
            data.get('description')
        )
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

# Video Games endpoints
@app.route('/api/video_games', methods=['GET'])
def get_video_games():
    try:
        conn = system.connect_to_database()
        cursor = conn.cursor()
        cursor.execute('SELECT * FROM video_games ORDER BY title')
        games = cursor.fetchall()
        conn.close()
        
        return jsonify({
            'success': True,
            'games': [
                {
                    'id': game[0],
                    'title': game[1],
                    'game_system': game[2],
                    'genre': game[3],
                    'year_released': game[4],
                    'status': game[5]
                }
                for game in games
            ]
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/video_games', methods=['POST'])
def add_video_game():
    try:
        data = request.json
        game_id = system.add_video_game(
            data.get('title'),
            data.get('game_system'),
            data.get('genre'),
            data.get('year_released')
        )
        return jsonify({'success': True, 'game_id': game_id})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/video_games/<game_id>', methods=['DELETE'])
def delete_video_game(game_id):
    try:
        system.delete_video_game(game_id)
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/video_games/<game_id>', methods=['PUT'])
def update_video_game(game_id):
    try:
        data = request.json
        system.update_video_game(
            game_id,
            data.get('title'),
            data.get('game_system'),
            data.get('genre'),
            data.get('year_released')
        )
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

# Movies endpoints
@app.route('/api/movies', methods=['GET'])
def get_movies():
    try:
        conn = system.connect_to_database()
        cursor = conn.cursor()
        cursor.execute('SELECT * FROM movies ORDER BY title')
        movies = cursor.fetchall()
        conn.close()
        
        return jsonify({
            'success': True,
            'movies': [
                {
                    'id': movie[0],
                    'title': movie[1],
                    'director': movie[2],
                    'cast': movie[3],
                    'year_released': movie[4],
                    'studio': movie[5],
                    'genre': movie[6],
                    'format': movie[7],
                    'status': movie[8]
                }
                for movie in movies
            ]
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/movies', methods=['POST'])
def add_movie():
    try:
        data = request.json
        movie_id = system.add_movie(
            data.get('title'),
            data.get('director'),
            data.get('cast'),
            data.get('year_released'),
            data.get('studio'),
            data.get('genre'),
            data.get('format')
        )
        return jsonify({'success': True, 'movie_id': movie_id})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/movies/<movie_id>', methods=['DELETE'])
def delete_movie(movie_id):
    try:
        system.delete_movie(movie_id)
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/movies/<movie_id>', methods=['PUT'])
def update_movie(movie_id):
    try:
        data = request.json
        system.update_movie(
            movie_id,
            data.get('title'),
            data.get('director'),
            data.get('cast'),
            data.get('year_released'),
            data.get('studio'),
            data.get('genre'),
            data.get('format')
        )
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

# Borrowers endpoints
@app.route('/api/borrowers', methods=['GET'])
def get_borrowers():
    try:
        conn = system.connect_to_database()
        cursor = conn.cursor()
        cursor.execute('SELECT * FROM borrowers ORDER BY last_name, first_name')
        borrowers = cursor.fetchall()
        conn.close()
        
        return jsonify({
            'success': True,
            'borrowers': [
                {
                    'id': borrower[0],
                    'first_name': borrower[1],
                    'last_name': borrower[2],
                    'address': borrower[3],
                    'phone_number': borrower[4]
                }
                for borrower in borrowers
            ]
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/borrowers', methods=['POST'])
def add_borrower():
    try:
        data = request.json
        borrower_id = system.add_borrower(
            data.get('first_name'),
            data.get('last_name'),
            data.get('address'),
            data.get('phone_number')
        )
        return jsonify({'success': True, 'borrower_id': borrower_id})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/borrowers/<borrower_id>', methods=['DELETE'])
def delete_borrower(borrower_id):
    try:
        system.delete_borrower(borrower_id)
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/borrowers/<borrower_id>', methods=['PUT'])
def update_borrower(borrower_id):
    try:
        data = request.json
        system.update_borrower(
            borrower_id,
            data.get('first_name'),
            data.get('last_name'),
            data.get('address'),
            data.get('phone_number')
        )
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/borrowers/<borrower_id>/history', methods=['GET'])
def get_borrower_history(borrower_id):
    try:
        history = system.get_borrower_history(borrower_id)
        return jsonify({
            'success': True,
            'history': [
                {
                    'id': record[0],
                    'media_id': record[1],
                    'media_type': record[2],
                    'checkout_date': record[3],
                    'return_date': record[4],
                    'status': record[5]
                }
                for record in history
            ]
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

# Checkout endpoints
@app.route('/api/checkout', methods=['POST'])
def checkout():
    try:
        data = request.json
        system.checkout_media(
            data.get('borrower_id'),
            data.get('media_id'),
            data.get('media_type')
        )
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/return', methods=['POST'])
def return_media():
    try:
        data = request.json
        system.return_media(
            data.get('borrower_id'),
            data.get('media_id')
        )
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

# Diagnostics endpoints
@app.route('/api/diagnostics', methods=['GET'])
def diagnostics():
    try:
        conn = system.connect_to_database()
        cursor = conn.cursor()
        
        cursor.execute("SELECT COUNT(*) FROM books")
        books_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM video_games")
        games_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM movies")
        movies_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM borrowers")
        borrowers_count = cursor.fetchone()[0]
        
        cursor.execute("SELECT COUNT(*) FROM checkout_history WHERE status = 'checked_out'")
        checked_out_count = cursor.fetchone()[0]
        
        conn.close()
        
        return jsonify({
            'success': True,
            'stats': {
                'total_books': books_count,
                'total_games': games_count,
                'total_movies': movies_count,
                'total_borrowers': borrowers_count,
                'items_checked_out': checked_out_count
            }
        })
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/check-integrity', methods=['GET'])
def check_integrity():
    try:
        result = system.check_database_integrity()
        return jsonify({'success': True, 'healthy': result})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/api/repair', methods=['POST'])
def repair():
    try:
        system.repair_database()
        return jsonify({'success': True})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

if __name__ == '__main__':
    app.run(debug=True, port=5000)
