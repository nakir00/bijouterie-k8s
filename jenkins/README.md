# Installation de Jenkins

Le script utilise le chart officiel Jenkins version 5.13.3. Il installe le contrôleur dans le namespace `jenkins` et demande un volume persistant de 10 Gio.

Prérequis : `kubectl` configuré sur le bon cluster, des droits d'administration, Helm 3, un accès Internet et une StorageClass par défaut capable de provisionner un volume. Depuis la racine du dépôt :

```sh
./jenkins/install.sh
kubectl -n jenkins port-forward svc/jenkins 8081:8080
```

Ouvrir ensuite http://localhost:8081. Pour accéder au compte administrateur initial, consulter localement les instructions affichées par `helm get notes jenkins -n jenkins`, sans partager le mot de passe ni le montrer dans une capture.

Le script s'arrête si le namespace `jenkins` existe déjà ; il ne met pas à niveau une installation existante. Un PVC `Pending` indique un problème de stockage. L'installation ne configure ni le pipeline ni ses credentials. Il faut encore configurer l'agent de build et les accès à Docker Hub et au dépôt Git privé.

Documentation officielle : https://www.jenkins.io/doc/book/installing/kubernetes/
