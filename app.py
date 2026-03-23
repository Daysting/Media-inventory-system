from flask import Flask, render_template, request, jsonify
import system
import os
import uuid
import urllib.parse

app = Flask(__name__)

UPLOAD_FOLDER = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'static', 'uploads')
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

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
                    'image_url': book[8],
                    'status': book[9]
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
            data.get('description'),
            data.get('image_url')
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
            data.get('description'),
            data.get('image_url')
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
                    'developer': game[2],
                    'platform': game[2],
                    'genre': game[3],
                    'year_released': game[4],
                    'rating': None,
                    'description': None,
                    'image_url': game[5],
                    'status': game[6]
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
        game_system = data.get('game_system') or data.get('platform') or data.get('developer')
        game_id = system.add_video_game(
            data.get('title'),
            game_system,
            data.get('genre'),
            data.get('year_released'),
            data.get('image_url')
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
        game_system = data.get('game_system') or data.get('platform') or data.get('developer')
        system.update_video_game(
            game_id,
            data.get('title'),
            game_system,
            data.get('genre'),
            data.get('year_released'),
            data.get('image_url')
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
                    'rating': movie[7],
                    'runtime_minutes': None,
                    'image_url': movie[8],
                    'status': movie[9]
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
        movie_format = data.get('format') or data.get('rating')
        movie_id = system.add_movie(
            data.get('title'),
            data.get('director'),
            data.get('cast'),
            data.get('year_released'),
            data.get('studio'),
            data.get('genre'),
            movie_format,
            data.get('image_url')
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
        movie_format = data.get('format') or data.get('rating')
        system.update_movie(
            movie_id,
            data.get('title'),
            data.get('director'),
            data.get('cast'),
            data.get('year_released'),
            data.get('studio'),
            data.get('genre'),
            movie_format,
            data.get('image_url')
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
                    'phone_number': borrower[4],
                    'email': None
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
@app.route('/api/upload', methods=['POST'])
def upload_media_image():
    try:
        if 'image' not in request.files:
            return jsonify({'success': False, 'error': 'No image file provided'}), 400

        file = request.files['image']
        if file.filename == '':
            return jsonify({'success': False, 'error': 'No selected file'}), 400

        extension = os.path.splitext(file.filename)[1].lower()
        if extension not in ['.jpg', '.jpeg', '.png', '.gif']:
            return jsonify({'success': False, 'error': 'Unsupported image type'}), 400

        filename = f"{uuid.uuid4().hex}{extension}"
        filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        file.save(filepath)

        # Return relative path for storage and display
        image_url = f"/static/uploads/{filename}"
        return jsonify({'success': True, 'image_url': image_url})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/search-image', methods=['GET'])
def search_image():
    query = request.args.get('query')
    if not query:
        return jsonify({'success': False, 'error': 'query parameter is required'}), 400

    try:
        image_url = system.search_google_image(query)
        return jsonify({'success': True, 'image_url': image_url})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


# Reporting endpoints
@app.route('/api/reports/inventory-summary', methods=['GET'])
def get_inventory_summary_report():
    try:
        summary = system.get_inventory_summary()
        return jsonify({'success': True, 'summary': summary})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})


@app.route('/api/reports/borrower-activity', methods=['GET'])
def get_borrower_activity_report():
    try:
        report = system.get_borrower_activity_report()
        return jsonify({'success': True, 'borrowers': report})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})


@app.route('/api/reports/checkout-history', methods=['GET'])
def get_checkout_history_report():
    try:
        start_date = request.args.get('start_date')
        end_date = request.args.get('end_date')
        report = system.get_checkout_history_report(start_date, end_date)
        return jsonify({'success': True, 'history': report})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})


@app.route('/api/reports/genre-distribution', methods=['GET'])
def get_genre_distribution_report():
    try:
        report = system.get_genre_distribution()
        return jsonify({'success': True, 'genres': report})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})


@app.route('/api/reports/overdue-items', methods=['GET'])
def get_overdue_items_report():
    try:
        report = system.get_overdue_items()
        return jsonify({'success': True, 'overdue': report})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})


# Barcode generation endpoints
@app.route('/api/barcodes/generate', methods=['GET'])
def generate_barcode():
    id_number = request.args.get('id')
    barcode_type = request.args.get('type', 'code128')

    if not id_number:
        return jsonify({'success': False, 'error': 'id parameter is required'}), 400

    try:
        barcode_data = system.generate_barcode(id_number, barcode_type)
        return jsonify(barcode_data)
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/barcodes/media', methods=['GET'])
def get_media_barcodes():
    media_type = request.args.get('type')  # optional: books, video_games, movies

    try:
        barcodes = system.generate_media_barcodes(media_type)
        return jsonify({'success': True, 'barcodes': barcodes})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


@app.route('/api/barcodes/borrowers', methods=['GET'])
def get_borrower_barcodes():
    try:
        barcodes = system.generate_borrower_barcodes()
        return jsonify({'success': True, 'barcodes': barcodes})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)}), 500


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
