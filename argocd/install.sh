#!/usr/bin/env bash
set -euo pipefail

# Manifest officiel Argo CD fixé à la version du cluster de développement.
command -v kubectl >/dev/null 2>&1 || { echo 'Commande requise : kubectl' >&2; exit 1; }
kubectl cluster-info >/dev/null
namespace=argocd
version=v3.6.1

# L’installation officielle possède des ressources au niveau du cluster.
# Refuser de modifier une installation existante ou une CRD déjà présente.
if kubectl get namespace "$namespace" >/dev/null 2>&1 || kubectl get crd applications.argoproj.io >/dev/null 2>&1; then
  echo 'Argo CD ou son namespace existe déjà : installation interrompue pour préserver les ressources.' >&2
  exit 1
fi
kubectl create namespace "$namespace"
# Server-side apply évite la limite de taille des annotations sur les CRD.
kubectl apply --server-side -n "$namespace" -f "https://raw.githubusercontent.com/argoproj/argo-cd/${version}/manifests/install.yaml"
kubectl rollout status deployment/argocd-server -n "$namespace" --timeout=10m
kubectl rollout status deployment/argocd-repo-server -n "$namespace" --timeout=10m
kubectl rollout status statefulset/argocd-application-controller -n "$namespace" --timeout=10m
printf '\nArgo CD installé. Pour accéder à l’interface :\n'
printf 'kubectl -n argocd port-forward svc/argocd-server 8082:443\n'
printf 'Suivre argocd/README.md pour la connexion et les credentials.\n'
