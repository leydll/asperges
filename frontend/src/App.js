import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './App.css';

// Configuration de l'URL de l'API
// L'API est toujours accessible via la gateway sur /api
// La gateway route /api vers le backend
const getApiUrl = () => {
  if (process.env.REACT_APP_API_URL) {
    return process.env.REACT_APP_API_URL;
  }
  // Utiliser /api comme URL relative - cela fonctionne quand on accède via la gateway
  // Si on accède via le service frontend directement, cela ne fonctionnera pas
  // Solution : toujours accéder via la gateway-service
  return '/api';
};

const API_URL = getApiUrl();

function App() {
  const [todos, setTodos] = useState([]);
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchTodos();
  }, []);

  const fetchTodos = async () => {
    try {
      setLoading(true);
      const url = `${API_URL}/todos`;
      console.log('Fetching todos from:', url);
      const response = await axios.get(url);
      console.log('Todos response:', response.data);
      setTodos(response.data);
      setError(null);
    } catch (err) {
      console.error('Error fetching todos:', err);
      console.error('Error details:', {
        message: err.message,
        code: err.code,
        config: err.config,
        response: err.response
      });
      setError('Erreur lors du chargement des tâches');
    } finally {
      setLoading(false);
    }
  };

  const createTodo = async (e) => {
    e.preventDefault();
    if (!title.trim()) return;

    try {
      setLoading(true);
      const response = await axios.post(`${API_URL}/todos`, {
        title: title.trim(),
        description: description.trim(),
        completed: false
      });
      setTodos([response.data, ...todos]);
      setTitle('');
      setDescription('');
      setError(null);
    } catch (err) {
      setError('Erreur lors de la création de la tâche');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const updateTodo = async (id, updates) => {
    try {
      setLoading(true);
      const response = await axios.put(`${API_URL}/todos/${id}`, updates);
      setTodos(todos.map(todo => todo.id === id ? response.data : todo));
      setError(null);
    } catch (err) {
      setError('Erreur lors de la mise à jour de la tâche');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const deleteTodo = async (id) => {
    if (!window.confirm('Êtes-vous sûr de vouloir supprimer cette tâche ?')) {
      return;
    }

    try {
      setLoading(true);
      await axios.delete(`${API_URL}/todos/${id}`);
      setTodos(todos.filter(todo => todo.id !== id));
      setError(null);
    } catch (err) {
      setError('Erreur lors de la suppression de la tâche');
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const toggleComplete = (todo) => {
    updateTodo(todo.id, { completed: !todo.completed });
  };

  return (
    <div className="App">
      <header className="App-header">
        <h1>Todo App - Microservices</h1>
        <p>Application de gestion de tâches avec Docker et Kubernetes</p>
      </header>

      <main className="App-main">
        <form onSubmit={createTodo} className="todo-form">
          <input
            type="text"
            placeholder="Titre de la tâche"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            className="todo-input"
            disabled={loading}
          />
          <textarea
            placeholder="Description (optionnelle)"
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            className="todo-textarea"
            disabled={loading}
            rows="3"
          />
          <button type="submit" className="todo-button" disabled={loading}>
            {loading ? 'En cours...' : 'Ajouter une tâche'}
          </button>
        </form>

        {error && (
          <div className="error-message">
            {error}
          </div>
        )}

        <div className="todos-container">
          <h2>Mes Tâches ({todos.length})</h2>
          {loading && todos.length === 0 ? (
            <div className="loading">Chargement...</div>
          ) : todos.length === 0 ? (
            <div className="empty-state">
              Aucune tâche pour le moment. Créez-en une !
            </div>
          ) : (
            <div className="todos-list">
              {todos.map(todo => (
                <div
                  key={todo.id}
                  className={`todo-item ${todo.completed ? 'completed' : ''}`}
                >
                  <div className="todo-content">
                    <h3>{todo.title}</h3>
                    {todo.description && <p>{todo.description}</p>}
                    <div className="todo-meta">
                      <small>
                        Créé le {new Date(todo.created_at).toLocaleDateString('fr-FR')}
                      </small>
                    </div>
                  </div>
                  <div className="todo-actions">
                    <button
                      onClick={() => toggleComplete(todo)}
                      className={`todo-action-button ${todo.completed ? 'completed' : ''}`}
                      disabled={loading}
                    >
                      {todo.completed ? 'Fait' : 'A faire'}
                    </button>
                    <button
                      onClick={() => deleteTodo(todo.id)}
                      className="todo-action-button delete"
                      disabled={loading}
                    >
                      Supprimer
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </main>

      <footer className="App-footer">
        <p>Application conteneurisée avec Docker et orchestrée avec Kubernetes</p>
      </footer>
    </div>
  );
}

export default App;

