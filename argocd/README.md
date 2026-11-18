# Installation d'Argo CD

Le script installe le manifeste officiel Argo CD v3.6.1 dans le namespace `argocd`. Il nécessite `kubectl`, un accès Internet, des droits d'administration et le bon contexte Kubernetes. Depuis la racine du dépôt :

```sh
./argocd/install.sh
kubectl -n argocd port-forward svc/argocd-server 8082:443
```

Ouvrir https://localhost:8082. Le mot de passe initial du compte `admin`, s'il est encore présent, se trouve dans le Secret `argocd-initial-admin-secret` du namespace `argocd` ; le consulter localement sans le partager. Le certificat local peut nécessiter une exception dans le navigateur.

Le script s'arrête si le namespace `argocd` ou la CRD principale existe déjà ; il ne met pas à niveau une installation existante. Il ne déploie pas l'application Bijouterie automatiquement. Pour cela, donner à Argo CD un accès en lecture au dépôt privé, vérifier que les images référencées existent, puis appliquer `application.yaml`. Ensuite, les changements de l'application passent par Git.

Documentation officielle : https://argo-cd.readthedocs.io/en/stable/getting_started/
