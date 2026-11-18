# Installation d'Argo CD avec Kubernetes

Le manifeste officiel Argo CD v3.6.1 est chargé directement depuis GitHub par `kubectl`. La version est fixée pour rendre l’installation reproductible. Prérequis : `kubectl`, droits d’administration et accès Internet au manifeste et aux images.

Sur un cluster vierge, depuis la racine du dépôt :

```sh
kubectl apply -f k8s/00-installation/02-argocd/00-namespace.yaml
kubectl apply -n argocd --server-side --force-conflicts -f https://raw.githubusercontent.com/argoproj/argo-cd/v3.6.1/manifests/install.yaml
kubectl -n argocd rollout status deployment/argocd-server
kubectl -n argocd port-forward svc/argocd-server 8082:443
```

Ouvrir https://localhost:8082. Le mot de passe initial du compte `admin`, s'il existe encore, se trouve dans le Secret `argocd-initial-admin-secret` ; le consulter localement sans le partager. Le certificat local peut nécessiter une exception dans le navigateur.

La commande d'installation avec `--force-conflicts` peut reprendre la gestion de ressources existantes : ne pas l'exécuter sur une installation existante sans vérifier son impact.

Après publication des images et configuration de l'accès au dépôt privé dans Argo CD, appliquer `argocd/application.yaml`. Cette Application surveille uniquement les YAML à la racine de `k8s/`, sans parcourir le sous-dossier d'installation.

Source : https://argo-cd.readthedocs.io/en/stable/getting_started/
