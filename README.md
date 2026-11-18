# Bijouterie : infrastructure Kubernetes

- `k8s/` : manifests de l'application surveillés par Argo CD.
- `bootstrap/` : installation de Jenkins et Argo CD sur un nouveau cluster.
- `argocd/application.yaml` : Application Argo CD déclarative.

Les sources applicatives se trouvent dans les dépôts privés `bijouterie-frontend`, `bijouterie-backend` et `bijouterie-database` du compte `nakir00`. Voir [bootstrap/README.md](bootstrap/README.md) pour l'installation et les prérequis.

Les mots de passe présents dans les Secrets Kubernetes sont des valeurs de démonstration autorisées par l'énoncé pour le TP. Ne jamais utiliser ces valeurs en production ; base64 n'est pas du chiffrement. Les images `nabyyy/*:1` doivent être publiées avant le déploiement et les tags synchronisés avec les builds Jenkins.
