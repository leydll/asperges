# Scripts d'automatisation

Ce dossier contient les scripts d'automatisation pour faciliter le déploiement et la gestion de l'application.

## Scripts disponibles

### 1. `build-images.sh`
**Utilité** : Construit les images Docker pour le backend et le frontend.

**Utilisation** :
```bash
./scripts/build-images.sh
```

**Fonctionnalités** :
- Construit l'image `todo-backend:latest`
- Construit l'image `todo-frontend:latest`
- Propose automatiquement de charger les images dans minikube (si disponible)

### 2. `deploy-k8s.sh`
**Utilité** : Déploie l'application complète sur Kubernetes.

**Utilisation** :
```bash
./scripts/deploy-k8s.sh
```

**Fonctionnalités** :
- Crée le namespace `todo-app`
- Crée les secrets Kubernetes
- Déploie MySQL avec PVC
- Déploie Redis
- Déploie le backend
- Déploie le frontend
- Affiche le statut de tous les services
- Fournit les instructions pour accéder à l'application

**Prérequis** :
- `kubectl` configuré
- Cluster Kubernetes accessible (minikube, kind, ou cluster distant)
- Images Docker construites et disponibles dans le cluster

### 3. `cleanup-k8s.sh`
**Utilité** : Nettoie toutes les ressources Kubernetes de l'application.

**Utilisation** :
```bash
./scripts/cleanup-k8s.sh
```

**Fonctionnalités** :
- Supprime le namespace `todo-app` et toutes ses ressources
- Demande confirmation avant suppression
- Utile pour réinitialiser complètement l'environnement

### 4. `test-k8s.sh`
**Utilité** : Test complet de l'application avec Kubernetes (minikube).

**Utilisation** :
```bash
./scripts/test-k8s.sh
```

**Fonctionnalités** :
- Démarre minikube si nécessaire
- Configure l'environnement Docker pour minikube
- Construit les images Docker
- Déploie l'application
- Affiche les URLs pour accéder à l'application
- Fournit des commandes utiles pour le débogage

## Pourquoi garder ces scripts dans le projet ?

### ✅ **Arguments POUR garder les scripts** :

1. **Démonstration de maîtrise des technologies** :
   - Montre la capacité à automatiser les déploiements
   - Démontre la compréhension de Docker et Kubernetes
   - Impressionne les évaluateurs avec l'automatisation

2. **Réutilisabilité** :
   - Facilite le déploiement pour vous et les autres
   - Réutilisable pour d'autres projets similaires
   - Économise du temps lors des tests

3. **Documentation interactive** :
   - Les scripts servent de documentation exécutable
   - Plus clair que des instructions manuelles dans le README
   - Réduit les erreurs de copier-coller

4. **Critères d'évaluation** :
   - L'énoncé mentionne "Maitrise des technos" comme critère principal
   - Les scripts d'automatisation montrent une maîtrise avancée
   - Montre la capacité à créer des outils pratiques

5. **Professionnalisme** :
   - Les projets professionnels incluent des scripts d'automatisation
   - Montre une approche mature du développement
   - Facilite l'intégration continue (CI/CD)

### ❌ **Arguments CONTRE** (moins forts) :

1. **Complexité** :
   - Peut sembler "trop" pour un projet d'évaluation
   - Les évaluateurs peuvent ne pas les utiliser

2. **Maintien** :
   - Nécessite de garder les scripts à jour
   - Peut devenir obsolète si le projet évolue

## Recommandation

**✅ GARDEZ les scripts dans le projet** pour les raisons suivantes :

1. Ils démontrent une **maîtrise avancée** des technologies (critère principal d'évaluation)
2. Ils **améliorent l'expérience utilisateur** du dépôt GitHub
3. Ils montrent une **approche professionnelle** du développement
4. Ils sont **légers** (quelques KB) et n'encombrent pas le projet
5. Ils peuvent servir de **documentation exécutable**

## Utilisation recommandée

Dans votre README, mentionnez les scripts :
```markdown
## Scripts d'automatisation

Des scripts sont fournis pour faciliter le déploiement :
- `./scripts/build-images.sh` - Construire les images Docker
- `./scripts/deploy-k8s.sh` - Déployer sur Kubernetes
- `./scripts/cleanup-k8s.sh` - Nettoyer les ressources
- `./scripts/test-k8s.sh` - Test complet avec minikube
```

## Note pour l'évaluation

Lors de la présentation ou dans le README, mentionnez que vous avez créé des scripts d'automatisation pour :
- Simplifier le déploiement
- Réduire les erreurs humaines
- Démontrer votre maîtrise des outils DevOps

Cela montre une compréhension approfondie des technologies Docker et Kubernetes, ce qui est un atout majeur pour l'évaluation !

