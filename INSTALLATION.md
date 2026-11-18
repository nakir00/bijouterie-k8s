# Installation et déploiement de Bijouterie

Ce guide présente les commandes dans l'ordre pour un **nouveau cluster**. Lancer les commandes depuis la racine de ce dépôt. Jenkins et Argo CD déjà présents sur un cluster ne doivent pas être remplacés sans examiner leur configuration.

## 1. Vérifier les prérequis

Il faut `kubectl`, un accès administrateur au cluster, une connexion Internet, une StorageClass par défaut pour Jenkins, et un accès au dépôt Git privé. Les images Docker Hub référencées dans `k8s/` doivent être publiées avec les tags indiqués avant le déploiement de Bijouterie.

```bash
kubectl config current-context
kubectl get nodes
kubectl get storageclass
```

Vérifier que le contexte est le bon, que le nœud est `Ready` et qu'une StorageClass est marquée `(default)`.

## 2. Installer Jenkins

Sur un cluster qui ne possède pas déjà cette installation :

```bash
kubectl apply -f k8s/00-installation/01-jenkins/00-namespace.yaml
kubectl apply -f k8s/00-installation/01-jenkins/
kubectl -n devops-tools rollout status deployment/jenkins
kubectl -n devops-tools get pods,svc,pvc
```

Le PVC doit être `Bound` et le pod prêt. Jenkins est accessible sur `http://<adresse-du-noeud>:32000` ; sur Docker Desktop : http://localhost:32000. Voir [jenkins/README.md](jenkins/README.md) pour la première connexion.

**À configurer avant de lancer une CI :** le job utilisant le `Jenkinsfile` à la racine, un agent portant le label `docker` capable de construire les images, les credentials Docker Hub et GitHub et leur accès aux dépôts. Le pipeline est fourni mais ces éléments et sa validation restent à finaliser. Ne pas afficher les mots de passe ou tokens dans les captures ni les enregistrer dans Git.

## 3. Installer Argo CD

Sur un cluster qui ne possède pas déjà Argo CD :

```bash
kubectl apply -f k8s/00-installation/02-argocd/00-namespace.yaml
kubectl apply --server-side --force-conflicts -k k8s/00-installation/02-argocd/
kubectl -n argocd rollout status deployment/argocd-server
kubectl -n argocd rollout status deployment/argocd-repo-server
kubectl -n argocd rollout status statefulset/argocd-application-controller
```

L'option `--force-conflicts` peut modifier la gestion des ressources existantes ; ne pas l'utiliser sur une installation existante sans en vérifier l'impact.

Pour accéder à l'interface, garder la commande suivante ouverte dans un terminal :

```bash
kubectl -n argocd port-forward svc/argocd-server 8082:443
```

Ouvrir https://localhost:8082 et suivre [argocd/README.md](argocd/README.md) pour la connexion. Dans l'interface Argo CD, configurer un accès HTTPS en lecture au dépôt privé `https://github.com/nakir00/bijouterie-k8s.git` avec un credential GitHub adapté. Saisir le token directement dans l'interface ; ne pas le copier dans le dépôt.

## 4. Déployer Bijouterie avec Argo CD

**Avant cette étape**, vérifier dans Docker Hub que les trois images et les tags indiqués dans les Deployments existent et sont publics, et que la connexion au dépôt privé est établie dans Argo CD. Les images `:1` ont été publiées manuellement ; la CI Jenkins reste à configurer pour produire les versions suivantes.

Depuis un autre terminal, créer l'Application Argo CD :

```bash
kubectl apply -f argocd/application.yaml
kubectl -n argocd get application bijouterie
kubectl -n bijouterie get pods,svc
```

Dans l'interface Argo CD, attendre les états `Synced` et `Healthy`. Sur Docker Desktop, ouvrir ensuite http://localhost:30080 ; sur un autre cluster, utiliser l'adresse d'un nœud avec le port `30080`. Vérifier les répliques et tester le catalogue.

L'Application lit uniquement les fichiers YAML à la racine de `k8s/`, pas le sous-dossier `00-installation/`. Après ce premier lancement, les modifications de l'application passent par Git et Argo CD ; ne pas appliquer manuellement les manifests de Bijouterie. Si `argocd/application.yaml` lui-même change, il doit être réappliqué : il n'est pas surveillé par l'Application actuelle.
