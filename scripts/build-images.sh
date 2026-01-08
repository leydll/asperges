#!/bin/bash

set -e

echo "Construction des images Docker..."

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}Construction de l'image backend...${NC}"
docker build -t todo-backend:latest ./backend

echo -e "${BLUE}Construction de l'image frontend...${NC}"
docker build -t todo-frontend:latest ./frontend

echo -e "${GREEN}Images construites avec succès !${NC}"
echo ""
echo "Images disponibles :"
docker images | grep todo

# Si minikube est disponible, proposer de charger les images
if command -v minikube &> /dev/null; then
    echo ""
    read -p "Charger les images dans minikube ? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Chargement des images dans minikube..."
        eval $(minikube docker-env)
        minikube image load todo-backend:latest
        minikube image load todo-frontend:latest
        echo -e "${GREEN}Images chargées dans minikube !${NC}"
    fi
fi

