#!/usr/bin/env bash
set -euo pipefail

# Le chart officiel configure le contrôleur et le plugin Kubernetes pour les agents.
# Cette installation ne configure ni credential ni agent de build Docker.
for tool in kubectl helm; do
  command -v "$tool" >/dev/null 2>&1 || { echo "Commande requise : $tool" >&2; exit 1; }
done
kubectl cluster-info >/dev/null
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
namespace=jenkins
release=jenkins
chart_version=5.13.3

# Ne jamais adopter ou écraser une installation préexistante.
if kubectl get namespace "$namespace" >/dev/null 2>&1; then
  echo "Le namespace $namespace existe déjà : installation interrompue pour préserver ses ressources." >&2
  exit 1
fi
helm repo add jenkinsci https://charts.jenkins.io
helm repo update jenkinsci
helm install "$release" jenkinsci/jenkins --version "$chart_version" \
  --namespace "$namespace" --create-namespace \
  --values "$script_dir/values.yaml" --wait --timeout 10m
printf '\nJenkins installé. Pour accéder à l’interface :\n'
printf 'kubectl -n jenkins port-forward svc/jenkins 8081:8080\n'
printf 'Suivre jenkins/README.md pour la connexion et les credentials.\n'
