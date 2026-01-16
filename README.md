# Application de Gestion de Tâches - Microservices

Application de gestion de tâches (Todo App) déployée avec Docker et Kubernetes, composée de plusieurs services microservices.

## Architecture

L'application suit une architecture microservices avec une **gateway** comme point d'entrée unique :

```
┌─────────────────────────────────────────┐
│         Gateway (Nginx)                 │
│      Point d'entrée unique              │
│         Port 3000 (80)                  │
└──────────────┬──────────────────────────┘
               │
       ┌───────┴────────┐
       │                │
       ▼                ▼
┌─────────────┐  ┌──────────────┐
│  Frontend   │  │   Backend    │
│   (React)   │  │   (Flask)    │
│             │  │              │
└─────────────┘  └──────┬───────┘
                        │
                ┌───────┴────────┐
                │                │
                ▼                ▼
         ┌──────────┐    ┌──────────┐
         │  MySQL   │    │  Redis   │
         │          │    │  (Cache)  │
         └──────────┘    └──────────┘
```

### Services

- **Gateway** : Point d'entrée unique (Nginx reverse proxy)
  - Route `/` → Frontend
  - Route `/api` → Backend(s)
- **Frontend** : Interface utilisateur React (accessible via la gateway)
- **Backend API** : API REST en Python Flask (accessible via la gateway sur `/api`)
- **Base de données** : MySQL
- **Cache** : Redis (optionnel)

## Prérequis

- **Docker** (version 20.10+) et **Docker Compose** (version 2.0+)
- **Kubernetes** : minikube, kind, ou un cluster K8s pour le déploiement
- **kubectl** configuré pour Kubernetes
- **Git** pour cloner le dépôt
- **Node.js** (18+) et **npm** (optionnel, uniquement pour le développement local du frontend)
- **Python** (3.11+) (optionnel, uniquement pour le développement local du backend)

## Installation

```bash
# Cloner le dépôt
git clone <url-du-repo>
cd evaluation-docker

# Ou si le dépôt n'existe pas encore, initialiser Git
git init
git add .
git commit -m "Initial commit - Application Todo App avec Docker et Kubernetes"
```

## Scripts d'automatisation

Des scripts d'automatisation sont fournis pour faciliter le déploiement et la gestion de l'application :

### Scripts disponibles

- **`scripts/build-images.sh`** : Construit les images Docker (gateway, backend et frontend)
- **`scripts/deploy-k8s.sh`** : Déploie l'application complète sur Kubernetes
- **`scripts/cleanup-k8s.sh`** : Nettoie toutes les ressources Kubernetes
- **`scripts/test-k8s.sh`** : Test complet avec minikube (démarre minikube si nécessaire)

**Exemple d'utilisation** :
```bash
# Construire les images
./scripts/build-images.sh

# Déployer sur Kubernetes
./scripts/deploy-k8s.sh

# Test complet avec minikube
./scripts/test-k8s.sh
```

Voir `scripts/README.md` pour la documentation complète des scripts.

**Note** : Ces scripts démontrent une maîtrise avancée des technologies Docker et Kubernetes, facilitent le déploiement et réduisent les erreurs. Ils sont recommandés pour l'évaluation.

## Démarrage rapide avec Docker Compose

```bash
# Lancer tous les services
docker-compose up -d

# Vérifier le statut
docker-compose ps

# Voir les logs
docker-compose logs -f

# Arrêter les services
docker-compose down
```

L'application sera accessible via la **gateway** (point d'entrée unique) :
- **Application complète** : http://localhost:3000
  - Frontend : http://localhost:3000/
  - Backend API : http://localhost:3000/api

## Déploiement avec Kubernetes

### Préparation (avec minikube)

```bash
# Démarrer minikube
minikube start

# Activer le registry local si nécessaire
eval $(minikube docker-env)

# Vérifier que minikube est en cours d'exécution

kubectl get nodes
```

### Construction des images Docker

```bash
# Construire les images
docker build -t todo-gateway:latest ./gateway
docker build -t todo-frontend:latest ./frontend
docker build -t todo-backend:latest ./backend

# Pour minikube, charger les images
minikube image load todo-gateway:latest
minikube image load todo-frontend:latest
minikube image load todo-backend:latest

# Vérifier que les images sont chargées dans minikube
minikube image ls | grep todo
```

### Déploiement Kubernetes

#### Méthode 1 : Déploiement manuel

```bash
# Créer le namespace
kubectl apply -f kubernetes/namespace.yaml

# Créer les secrets
kubectl apply -f kubernetes/secrets.yaml

# Déployer MySQL (PVC, Deployment, Service)
kubectl apply -f kubernetes/mysql/pvc.yaml
kubectl apply -f kubernetes/mysql/deployment.yaml
kubectl apply -f kubernetes/mysql/service.yaml

# Attendre que MySQL soit prêt
kubectl wait --for=condition=ready pod -l app=mysql -n todo-app --timeout=120s

# Déployer Redis
kubectl apply -f kubernetes/redis/deployment.yaml
kubectl apply -f kubernetes/redis/service.yaml

# Attendre que Redis soit prêt
kubectl wait --for=condition=ready pod -l app=redis -n todo-app --timeout=60s

# Déployer le backend
kubectl apply -f kubernetes/backend/deployment.yaml
kubectl apply -f kubernetes/backend/service.yaml

# Attendre que le backend soit prêt
kubectl wait --for=condition=ready pod -l app=backend -n todo-app --timeout=120s

# Déployer le frontend
kubectl apply -f kubernetes/frontend/deployment.yaml
kubectl apply -f kubernetes/frontend/service.yaml

# Attendre que le frontend soit prêt
kubectl wait --for=condition=ready pod -l app=frontend -n todo-app --timeout=120s

# Déployer la gateway (point d'entrée unique)
kubectl apply -f kubernetes/gateway/deployment.yaml
kubectl apply -f kubernetes/gateway/service.yaml

# Vérifier le déploiement
kubectl get all -n todo-app

# Voir les logs d'un service
kubectl logs -l app=backend -n todo-app
kubectl logs -l app=frontend -n todo-app
```

#### Méthode 2 : Déploiement avec script (voir scripts/deploy-k8s.sh)

```bash
chmod +x scripts/deploy-k8s.sh
./scripts/deploy-k8s.sh
```

### Accéder à l'application

```bash
# Avec minikube (via la gateway)
minikube service gateway-service -n todo-app

# Ou obtenir l'URL directement
minikube service gateway-service -n todo-app --url

# Port-forward (alternative)
kubectl port-forward -n todo-app service/gateway-service 3000:80
```

L'application sera accessible sur l'URL fournie par minikube.

### Ingress (optionnel)

Si vous avez configuré un Ingress Controller (nginx-ingress) :

```bash
# Activer le ingress controller dans minikube
minikube addons enable ingress

# Appliquer la configuration Ingress
kubectl apply -f kubernetes/frontend/ingress.yaml

# Ajouter l'entrée dans /etc/hosts (sur macOS/Linux)
echo "$(minikube ip) todo-app.local" | sudo tee -a /etc/hosts

# Accéder via
# http://todo-app.local
```

### Commandes utiles pour Kubernetes

```bash
# Voir tous les pods
kubectl get pods -n todo-app

# Voir les services
kubectl get services -n todo-app

# Voir les déploiements
kubectl get deployments -n todo-app

# Décrire un pod
kubectl describe pod <pod-name> -n todo-app

# Exécuter une commande dans un pod
kubectl exec -it <pod-name> -n todo-app -- /bin/sh

# Supprimer tous les ressources
kubectl delete namespace todo-app
```

## Structure du projet

```
.
├── gateway/              # Gateway (Point d'entrée unique)
│   ├── nginx.conf        # Configuration pour Docker Compose
│   ├── nginx-k8s.conf    # Configuration pour Kubernetes
│   └── Dockerfile
├── backend/              # Service API Flask
│   ├── app.py
│   ├── requirements.txt
│   ├── Dockerfile
│   └── .dockerignore
├── frontend/             # Application React
│   ├── src/
│   ├── public/
│   ├── package.json
│   ├── Dockerfile
│   ├── nginx.conf
│   └── .dockerignore
├── kubernetes/           # Manifests Kubernetes
│   ├── namespace.yaml
│   ├── secrets.yaml
│   ├── gateway/
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   ├── backend/
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   ├── frontend/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── ingress.yaml
│   ├── mysql/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── pvc.yaml
│   └── redis/
│       ├── deployment.yaml
│       └── service.yaml
├── scripts/              # Scripts d'automatisation
│   ├── README.md         # Documentation des scripts
│   ├── build-images.sh   # Construire les images Docker
│   ├── deploy-k8s.sh     # Déployer sur Kubernetes
│   ├── cleanup-k8s.sh    # Nettoyer les ressources K8s
│   └── test-k8s.sh       # Test complet avec minikube
├── docker-compose.yml    # Configuration Docker Compose
├── .gitignore
└── README.md
```

## Fonctionnalités

### Fonctionnalités applicatives
- Création, lecture, mise à jour et suppression de tâches (CRUD complet)
- Interface utilisateur moderne et responsive
- Gestion de l'état des tâches (complétées/non complétées)
- Affichage de la date de création des tâches

### Fonctionnalités techniques
- **Gateway** : Point d'entrée unique (Nginx reverse proxy) pour router les requêtes
- API REST complète avec Flask
- Persistance des données avec MySQL
- Cache avec Redis pour améliorer les performances
- Architecture microservices avec séparation des responsabilités
- Conteneurisation avec Docker (multi-stage builds)
- Orchestration avec Kubernetes (Deployments, Services, PVC, Secrets)
- Health checks et readiness probes
- Gestion des configurations avec Kubernetes Secrets
- Support de l'Ingress pour le routage
- Scripts d'automatisation pour le déploiement (build, deploy, cleanup, test)

## Technologies utilisées

- **Gateway** : Nginx (reverse proxy)
- **Frontend** : React, HTML5, CSS3
- **Backend** : Python 3.11, Flask, SQLAlchemy
- **Base de données** : MySQL 8.0
- **Cache** : Redis 7
- **Conteneurisation** : Docker
- **Orchestration** : Kubernetes

## Tests et vérification

### Tester avec Docker Compose

```bash
# Démarrer l'application
docker-compose up -d

# Vérifier que tous les services sont en cours d'exécution
docker-compose ps

# Tester l'API backend
curl http://localhost:5000/api/health
curl http://localhost:5000/api/todos

# Voir les logs
docker-compose logs -f backend
docker-compose logs -f frontend

# Accéder à la base de données
docker-compose exec mysql mysql -u todo_user -ptodo_password todos

# Tester Redis
docker-compose exec redis redis-cli ping
```

### Tester avec Kubernetes

#### Méthode 1 : Script automatique (recommandé)

```bash
# Test complet avec minikube (démarre minikube si nécessaire)
./scripts/test-k8s.sh
```

#### Méthode 2 : Manuel

```bash
# Démarrer minikube
minikube start

# Configurer l'environnement Docker pour minikube
eval $(minikube docker-env)

# Construire les images
./scripts/build-images.sh

# Déployer l'application
./scripts/deploy-k8s.sh

# Vérifier le statut des pods
kubectl get pods -n todo-app

# Voir les logs d'un service
kubectl logs -l app=backend -n todo-app --tail=50
kubectl logs -l app=frontend -n todo-app --tail=50

# Tester l'API backend
kubectl port-forward -n todo-app service/backend-service 5000:5000
curl http://localhost:5000/api/health

# Accéder à l'application via la gateway
minikube service gateway-service -n todo-app

# Vérifier les événements
kubectl get events -n todo-app --sort-by='.lastTimestamp'
```

## Dépannage

### Problèmes courants

#### Les pods ne démarrent pas
- Vérifier les logs : `kubectl logs <pod-name> -n todo-app`
- Vérifier les événements : `kubectl describe pod <pod-name> -n todo-app`
- Vérifier que les images sont disponibles : `docker images | grep todo`

#### Erreur de connexion à la base de données
- Vérifier que MySQL est en cours d'exécution : `kubectl get pods -l app=mysql -n todo-app`
- Vérifier les secrets : `kubectl get secrets -n todo-app`
- Vérifier les variables d'environnement du backend : `kubectl describe deployment backend -n todo-app`

#### Le frontend ne peut pas se connecter au backend
- Vérifier que les services sont correctement configurés : `kubectl get services -n todo-app`
- Vérifier que le backend expose bien le port 5000
- En production, configurer correctement l'URL de l'API via les variables d'environnement

#### Redis non disponible
- Redis est optionnel, l'application fonctionne sans cache
- Vérifier les logs du backend pour voir si Redis est connecté
- Vérifier que Redis est déployé : `kubectl get pods -l app=redis -n todo-app`

### Réinitialiser complètement l'application

```bash
# Avec Docker Compose
docker-compose down -v
docker-compose up -d

# Avec Kubernetes
./scripts/cleanup-k8s.sh
./scripts/build-images.sh
./scripts/deploy-k8s.sh
```

## Captures d'écran

L'application est accessible sur **http://localhost:3000** après le démarrage avec Docker Compose.

### Captures d'écran recommandées :

1. **Interface principale avec liste des tâches**
   - Page d'accueil de l'application
   - Formulaire de création de tâche
   - Liste vide ou avec quelques tâches

2. **Création d'une nouvelle tâche**
   - Formulaire rempli avec titre et description
   - Tâche ajoutée et visible dans la liste

3. **Marquage d'une tâche comme complétée**
   - Tâche non complétée (état initial)
   - Après avoir cliqué sur "À faire" pour la marquer comme complétée

4. **Suppression d'une tâche**
   - Liste avec plusieurs tâches
   - Dialogue de confirmation de suppression

5. **Dashboard Docker Compose**
   - `docker-compose ps` montrant tous les services en cours d'exécution
   - `docker ps` montrant les conteneurs actifs

6. **Dashboard Kubernetes (si déployé avec K8s)**
   - `kubectl get all -n todo-app` montrant les pods/services
   - `kubectl get pods -n todo-app` avec les statuts

7. **Logs des services**
   - `docker-compose logs backend` ou `kubectl logs -l app=backend -n todo-app`
   - Affichage de la connexion à MySQL et Redis

8. **Test de l'API**
   - `curl http://localhost:5001/api/health` ou `curl http://localhost:5000/api/health` (selon l'environnement)
   - Réponse JSON montrant le statut de l'API et Redis

## Auteurs

- Leïla DIALLO

## Licence

Ce projet est un projet d'évaluation académique.
