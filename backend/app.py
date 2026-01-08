from flask import Flask, request, jsonify
from flask_sqlalchemy import SQLAlchemy
import os
import redis
from datetime import datetime

app = Flask(__name__)

# Configuration CORS personnalisée
@app.after_request
def after_request(response):
    """Ajouter les headers CORS à toutes les réponses"""
    origin = request.headers.get('Origin')
    if origin:
        response.headers['Access-Control-Allow-Origin'] = origin
    else:
        response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Credentials'] = 'true'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization, X-Requested-With, Accept'
    response.headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS, PATCH'
    response.headers['Access-Control-Max-Age'] = '86400'
    return response

@app.before_request
def handle_preflight():
    """Gérer les requêtes OPTIONS (preflight)"""
    if request.method == "OPTIONS":
        response = jsonify({})
        response.status_code = 200
        return response

# Configuration de la base de données MySQL
db_host = os.getenv('DB_HOST', 'localhost')
db_port = os.getenv('DB_PORT', '3306')
db_name = os.getenv('DB_NAME', 'todos')
db_user = os.getenv('DB_USER', 'todo_user')
db_password = os.getenv('DB_PASSWORD', 'todo_password')

app.config['SQLALCHEMY_DATABASE_URI'] = f'mysql+pymysql://{db_user}:{db_password}@{db_host}:{db_port}/{db_name}?charset=utf8mb4'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy(app)

# Configuration Redis (optionnel)
redis_host = os.getenv('REDIS_HOST', 'localhost')
redis_port = int(os.getenv('REDIS_PORT', '6379'))
try:
    redis_client = redis.Redis(host=redis_host, port=redis_port, decode_responses=True)
    redis_client.ping()
    redis_available = True
except:
    redis_available = False
    print("Redis non disponible, fonctionnement sans cache")

# Modèle de données
class Todo(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(200), nullable=False)
    description = db.Column(db.Text)
    completed = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def to_dict(self):
        return {
            'id': self.id,
            'title': self.title,
            'description': self.description,
            'completed': self.completed,
            'created_at': self.created_at.isoformat() if self.created_at else None,
            'updated_at': self.updated_at.isoformat() if self.updated_at else None
        }

# Routes API

@app.route('/api/health', methods=['GET'])
def health():
    return jsonify({'status': 'healthy', 'redis': redis_available}), 200

@app.route('/api/todos', methods=['GET'])
def get_todos():
    cache_key = 'todos:all'
    
    # Essayer de récupérer depuis le cache Redis
    if redis_available:
        cached = redis_client.get(cache_key)
        if cached:
            import json
            return jsonify(json.loads(cached)), 200
    
    # Récupérer depuis la base de données
    todos = Todo.query.order_by(Todo.created_at.desc()).all()
    result = [todo.to_dict() for todo in todos]
    
    # Mettre en cache Redis
    if redis_available:
        import json
        redis_client.setex(cache_key, 60, json.dumps(result))  # Cache 60 secondes
    
    return jsonify(result), 200

@app.route('/api/todos/<int:todo_id>', methods=['GET'])
def get_todo(todo_id):
    cache_key = f'todos:{todo_id}'
    
    # Essayer de récupérer depuis le cache Redis
    if redis_available:
        cached = redis_client.get(cache_key)
        if cached:
            import json
            return jsonify(json.loads(cached)), 200
    
    todo = Todo.query.get_or_404(todo_id)
    result = todo.to_dict()
    
    # Mettre en cache Redis
    if redis_available:
        import json
        redis_client.setex(cache_key, 60, json.dumps(result))
    
    return jsonify(result), 200

@app.route('/api/todos', methods=['POST'])
def create_todo():
    data = request.get_json()
    
    if not data or 'title' not in data:
        return jsonify({'error': 'Le titre est requis'}), 400
    
    todo = Todo(
        title=data['title'],
        description=data.get('description', ''),
        completed=data.get('completed', False)
    )
    
    db.session.add(todo)
    db.session.commit()
    
    # Invalider le cache
    if redis_available:
        redis_client.delete('todos:all')
    
    return jsonify(todo.to_dict()), 201

@app.route('/api/todos/<int:todo_id>', methods=['PUT'])
def update_todo(todo_id):
    todo = Todo.query.get_or_404(todo_id)
    data = request.get_json()
    
    if 'title' in data:
        todo.title = data['title']
    if 'description' in data:
        todo.description = data['description']
    if 'completed' in data:
        todo.completed = data['completed']
    
    todo.updated_at = datetime.utcnow()
    db.session.commit()
    
    # Invalider le cache
    if redis_available:
        redis_client.delete('todos:all')
        redis_client.delete(f'todos:{todo_id}')
    
    return jsonify(todo.to_dict()), 200

@app.route('/api/todos/<int:todo_id>', methods=['DELETE'])
def delete_todo(todo_id):
    todo = Todo.query.get_or_404(todo_id)
    db.session.delete(todo)
    db.session.commit()
    
    # Invalider le cache
    if redis_available:
        redis_client.delete('todos:all')
        redis_client.delete(f'todos:{todo_id}')
    
    return jsonify({'message': 'Tâche supprimée'}), 200

# Initialisation de la base de données avec retry
def init_db(max_retries=30, retry_delay=2):
    import time
    for attempt in range(max_retries):
        try:
            with app.app_context():
                db.create_all()
                print("Base de données initialisée avec succès")
                return True
        except Exception as e:
            if attempt < max_retries - 1:
                print(f"Tentative de connexion à la base de données ({attempt + 1}/{max_retries})...")
                time.sleep(retry_delay)
            else:
                print(f"Impossible de se connecter à la base de données après {max_retries} tentatives")
                print(f"Erreur: {e}")
                return False
    return False

if __name__ == '__main__':
    if init_db():
        port = int(os.getenv('PORT', 5000))
        app.run(host='0.0.0.0', port=port, debug=False)
    else:
        print("Echec de l'initialisation. Arret de l'application.")
        exit(1)

