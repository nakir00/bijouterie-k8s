# Installation des outils sur un nouveau cluster

Les scripts installent les outils, pas encore le pipeline Jenkins ni ses identifiants.
Ils utilisent le contexte courant de `kubectl`. Vérifier ce contexte et disposer des droits d'administration du cluster avant de les lancer. Ne pas les lancer sur une installation existante : ils s'arrêtent lorsqu'ils détectent leurs namespaces respectifs. Le script Argo CD vérifie également la présence de sa CRD principale.

Prérequis : `kubectl`, Helm 3 pour Jenkins, accès Internet pour télécharger les images et chart, et une StorageClass par défaut qui provisionne les volumes. Les scripts ne créent pas la StorageClass. Le chart Jenkins demande un volume de 10 Gio ; un PVC `Pending` signale un problème de stockage.

1. Depuis la racine du dépôt, lancer `./bootstrap/install-jenkins.sh`, puis dans un autre terminal `kubectl -n jenkins port-forward svc/jenkins 8081:8080`. Ouvrir http://localhost:8081. Consulter les notes du chart `helm get notes jenkins -n jenkins` pour accéder au compte administrateur initial. Ne pas exposer son mot de passe dans une capture ou un dépôt.
2. Lancer `./bootstrap/install-argocd.sh`, puis dans un autre terminal `kubectl -n argocd port-forward svc/argocd-server 8082:443`. Ouvrir https://localhost:8082. Le mot de passe initial du compte `admin`, s'il est présent, se trouve dans le Secret `argocd-initial-admin-secret` du namespace `argocd` ; le consulter localement, sans le partager. Le certificat local peut nécessiter une exception dans le navigateur.
3. Configurer dans Jenkins le credential `dockerhub-credentials` et l'accès en lecture à ce dépôt GitHub privé. Un agent de build avec accès à un moteur ou outil de construction d'images reste à configurer ; le chart seul ne le fournit pas.
4. Donner à Argo CD un accès en lecture au dépôt privé `nakir00/bijouterie-k8s` avant d'appliquer `argocd/application.yaml`. Vérifier auparavant que les images et tags des manifests existent sur Docker Hub. À partir de là, les changements d'application passent par Git.

Versions fixées : chart officiel Jenkins 5.13.3 ; manifest officiel Argo CD v3.6.1. Sources : https://www.jenkins.io/doc/book/installing/kubernetes/ et https://argo-cd.readthedocs.io/en/stable/getting_started/ . Les scripts ne modifient pas une installation existante et ne sont pas des scripts de mise à niveau.
