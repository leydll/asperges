#!/bin/bash

set -e

echo "Test de l'application avec Kubernetes (minikube)..."

# Couleurs
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Vérifier que minikube est installé
if ! command -v minikube &> /dev/null; then
    echo -e "${RED}minikube n'est pas installé${NC}"
    exit 1
fi

# Vérifier que kubectl est installé
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}kubectl n'est pas installé${NC}"
    exit 1
fi

# Démarrer minikube si nécessaire
if ! minikube status &> /dev/null; then
    echo -e "${YELLOW}Démarrage de minikube...${NC}"
    minikube start
else
    echo -e "${GREEN}minikube est déjà démarré${NC}"
fi

# Configurer l'environnement Docker pour minikube
echo -e "${BLUE}Configuration de l'environnement Docker pour minikube...${NC}"
eval $(minikube docker-env)

# Construire les images
echo -e "${BLUE}Construction des images Docker...${NC}"
./scripts/build-images.sh

# Déployer l'application
echo -e "${BLUE}Déploiement de l'application...${NC}"
./scripts/deploy-k8s.sh

# Attendre que tous les pods soient prêts
echo -e "${YELLOW}Attente que tous les pods soient prêts...${NC}"
sleep 20

# Afficher le statut
echo -e "${GREEN}Statut des pods :${NC}"
kubectl get pods -n todo-app

echo -e "${GREEN}Statut des services :${NC}"
kubectl get services -n todo-app

# Obtenir l'URL de la gateway
echo ""
echo -e "${GREEN}Accéder à l'application via la gateway :${NC}"
echo "  Option 1 (Port-forward) : kubectl port-forward -n todo-app service/gateway-service 3000:80"
echo "  Puis ouvrir : http://localhost:3000"
echo ""
echo "  Option 2 (minikube service) :"
minikube service gateway-service -n todo-app --url

echo ""
echo -e "${YELLOW}Pour voir les logs :${NC}"
echo "  kubectl logs -l app=gateway -n todo-app"
echo "  kubectl logs -l app=backend -n todo-app"
echo "  kubectl logs -l app=frontend -n todo-app"
echo ""
echo -e "${YELLOW}Pour nettoyer :${NC}"
echo "  ./scripts/cleanup-k8s.sh"

