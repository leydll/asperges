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

echo -e "${BLUE}Construction de l'image gateway...${NC}"
# Construire la gateway pour Docker Compose (par défaut)
docker build -t todo-gateway:latest ./gateway

echo -e "${GREEN}Images construites avec succès !${NC}"
echo ""
echo "Images disponibles :"
docker images | grep todo

# Si minikube est disponible, reconstruire la gateway avec la config K8s et charger les images
if command -v minikube &> /dev/null; then
    echo ""
    read -p "Reconstruire pour Kubernetes et charger dans minikube ? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Configuration de l'environnement Docker pour minikube..."
        eval $(minikube docker-env)
        
        echo -e "${BLUE}Reconstruction de la gateway avec la configuration Kubernetes...${NC}"
        docker build --build-arg CONFIG_TYPE=k8s -t todo-gateway:latest ./gateway
        
        echo -e "${BLUE}Reconstruction du backend...${NC}"
        docker build -t todo-backend:latest ./backend
        
        echo -e "${BLUE}Reconstruction du frontend...${NC}"
        docker build -t todo-frontend:latest ./frontend
        
        echo -e "${GREEN}Images reconstruites dans minikube avec succès !${NC}"
    fi
fi

