#!/bin/bash

set -e

echo "Nettoyage des ressources Kubernetes..."

# Couleurs
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

read -p "Êtes-vous sûr de vouloir supprimer toutes les ressources de l'application ? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Annulé."
    exit 0
fi

echo -e "${YELLOW}Suppression du namespace todo-app...${NC}"
kubectl delete namespace todo-app --ignore-not-found=true

echo -e "${RED}Nettoyage terminé !${NC}"

