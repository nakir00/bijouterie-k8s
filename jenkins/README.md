# Installation de Jenkins avec Kubernetes

Les manifests adaptés de [scriptcamp/kubernetes-jenkins](https://github.com/scriptcamp/kubernetes-jenkins/tree/0c3fba187adbc96c78d9c1dc60e11cdd176ca45b) se trouvent dans `k8s/00-installation/01-jenkins/` : namespace, compte de service, stockage, Deployment et Service. Contrairement à l'exemple, le PVC utilise la StorageClass par défaut et le compte de service ne reçoit pas de rôle administrateur.

Prérequis : `kubectl` configuré sur le bon cluster, droits de création des ressources, accès aux images et StorageClass par défaut. Sur un cluster vierge, depuis la racine du dépôt :

```sh
kubectl apply -f k8s/00-installation/01-jenkins/00-namespace.yaml
kubectl apply -f k8s/00-installation/01-jenkins/
kubectl -n devops-tools rollout status deployment/jenkins
kubectl -n devops-tools get pods,svc,pvc
```

Accès : `http://<adresse-du-noeud>:32000` ; sur Docker Desktop, http://localhost:32000. Pour le mot de passe initial, consulter localement le fichier `/var/jenkins_home/secrets/initialAdminPassword` dans le conteneur Jenkins, sans l'afficher dans une capture ni le partager.

Un PVC `Pending` indique un problème de stockage. Le contrôleur ne dispose pas d'un moteur Docker : l'agent de build, ses droits éventuels, le pipeline et les credentials restent à configurer.

Ne pas appliquer ces fichiers par-dessus une installation Jenkins existante sans examiner les différences : le Deployment, son compte de service et son PVC pourraient être modifiés.
