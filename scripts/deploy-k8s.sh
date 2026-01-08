#!/bin/bash

set -e

echo "Déploiement de l'application Todo App sur Kubernetes..."

# Couleurs pour les messages
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Vérifier que kubectl est installé
if ! command -v kubectl &> /dev/null; then
    echo "kubectl n'est pas installé. Veuillez l'installer d'abord."
    exit 1
fi

# Vérifier que le contexte Kubernetes est valide
if ! kubectl cluster-info &> /dev/null; then
    echo "Impossible de se connecter au cluster Kubernetes."
    echo "Assurez-vous que minikube est démarré ou que votre contexte K8s est configuré."
    exit 1
fi

echo -e "${BLUE}Création du namespace...${NC}"
kubectl apply -f kubernetes/namespace.yaml

echo -e "${BLUE}Création des secrets...${NC}"
kubectl apply -f kubernetes/secrets.yaml

echo -e "${BLUE}Déploiement de MySQL...${NC}"
kubectl apply -f kubernetes/mysql/pvc.yaml
kubectl apply -f kubernetes/mysql/deployment.yaml
kubectl apply -f kubernetes/mysql/service.yaml

echo -e "${YELLOW}Attente que MySQL soit prêt...${NC}"
kubectl wait --for=condition=ready pod -l app=mysql -n todo-app --timeout=120s || true

echo -e "${BLUE}Déploiement de Redis...${NC}"
kubectl apply -f kubernetes/redis/deployment.yaml
kubectl apply -f kubernetes/redis/service.yaml

echo -e "${YELLOW}Attente que Redis soit prêt...${NC}"
kubectl wait --for=condition=ready pod -l app=redis -n todo-app --timeout=60s || true

echo -e "${BLUE}Déploiement du backend...${NC}"
kubectl apply -f kubernetes/backend/deployment.yaml
kubectl apply -f kubernetes/backend/service.yaml

echo -e "${YELLOW}Attente que le backend soit prêt...${NC}"
kubectl wait --for=condition=ready pod -l app=backend -n todo-app --timeout=120s || true

echo -e "${BLUE}Déploiement du frontend...${NC}"
kubectl apply -f kubernetes/frontend/deployment.yaml
kubectl apply -f kubernetes/frontend/service.yaml

echo -e "${YELLOW}Attente que le frontend soit prêt...${NC}"
sleep 10

echo -e "${GREEN}Déploiement terminé !${NC}"
echo ""
echo -e "${BLUE}Statut des services :${NC}"
kubectl get all -n todo-app

echo ""
echo -e "${GREEN}Pour accéder à l'application :${NC}"
if command -v minikube &> /dev/null; then
    echo "  minikube service frontend-service -n todo-app"
else
    echo "  kubectl port-forward -n todo-app service/frontend-service 3000:80"
fi
echo ""

