# Jenkins sur Kubernetes

Les manifests de `k8s/00-installation/01-jenkins/` installent Jenkins avec son image officielle. La première configuration, les plugins, les credentials, le job et le nœud de build se configurent manuellement dans l'interface.

## 1. Installer et ouvrir Jenkins

Sur un nouveau cluster, depuis la racine du dépôt :

```bash
kubectl apply -f k8s/00-installation/01-jenkins/00-namespace.yaml
kubectl apply -f k8s/00-installation/01-jenkins/
kubectl -n devops-tools rollout status deployment/jenkins --timeout=10m
kubectl -n devops-tools get pods,svc,pvc
```

Le cluster doit disposer d'une StorageClass par défaut. Le pod doit être prêt et son PVC `Bound`. Sur Docker Desktop, ouvrir http://localhost:32000 ; ailleurs, utiliser `http://<adresse-du-noeud>:32000`.

Lors du premier démarrage, Jenkins demande son mot de passe initial. Le consulter localement avec la commande ci-dessous, puis le saisir dans l'interface. Ne pas le partager ni le montrer dans une capture.

```bash
kubectl exec -n devops-tools deploy/jenkins -- cat /var/jenkins_home/secrets/initialAdminPassword
```

Choisir l'installation des plugins suggérés, puis créer le compte administrateur. Si des plugins manquent ensuite, aller dans **Administrer Jenkins → Plugins → Disponibles** : vérifier notamment Pipeline, Pipeline: Declarative, Git, Credentials Binding et, pour visualiser les stages, Pipeline: Stage View. Le plugin Docker Pipeline n'est pas nécessaire aux commandes Docker utilisées dans notre Jenkinsfile.

Ne pas appliquer ces manifests sur une installation Jenkins existante sans examiner les différences : le Deployment et son PVC pourraient être modifiés. L'ancien PVC n'est pas supprimé par ces commandes.

## 2. Ajouter les credentials

Dans **Administrer Jenkins → Credentials**, ouvrir le domaine global, puis ajouter :

1. **Docker Hub** : type `Username with password`, identifiant `dockerhub-credentials`, utilisateur `nabyyy`, mot de passe = token Docker Hub ayant les droits de lecture et d'écriture.
2. **GitHub** : type `Username with password`, identifiant par exemple `github-read-credentials`, utilisateur `nakir00`, mot de passe = token ayant accès en lecture à ce dépôt privé.

Saisir les tokens directement dans Jenkins. Ne pas les ajouter au dépôt, les envoyer dans une conversation ou les laisser apparaître dans les captures. Le Secret Kubernetes éventuellement créé auparavant n'est pas importé automatiquement par cette configuration manuelle.

## 3. Ajouter un nœud sur la machine hôte

Sur la machine qui exécutera les builds, vérifier Java compatible avec le contrôleur Jenkins, Git et Docker :

```bash
java -version
git --version
docker version
```

Docker Desktop et son moteur doivent être démarrés. Dans **Administrer Jenkins → Nodes → New Node**, créer un agent permanent `mac-docker` :

- un exécuteur ;
- un répertoire de travail absolu existant sur la machine hôte, par exemple `/Users/<utilisateur>/jenkins-agent` sur Mac ;
- le label `local` : il correspond au label du Jenkinsfile ;
- la méthode de lancement où l'agent se connecte au contrôleur.

Créer le répertoire choisi sur le Mac. Enregistrer le nœud, ouvrir sa page et suivre les instructions fournies par Jenkins pour télécharger son `agent.jar` et lancer l'agent. Si l'option WebSocket est proposée, elle permet d'utiliser le port HTTP Jenkins sans exposer un port agent TCP supplémentaire. Le secret propre au nœud doit rester privé ; ne pas le copier dans Git, dans une capture ou dans une conversation. La documentation Jenkins permet aussi de le lire depuis un fichier protégé avec l'option `-secret @chemin-du-fichier`.

Lancer l'agent dans un terminal où `git` et `docker` sont accessibles dans le `PATH`, puis vérifier que le nœud apparaît en ligne. Le processus doit rester actif pendant le build. Son accès à Docker permet au pipeline d'agir avec les droits Docker de l'utilisateur qui l'exécute : réserver ce nœud aux builds de confiance.

## 4. Créer le job Pipeline

Depuis l'accueil Jenkins :

1. Créer un nouvel élément `bijouterie` de type **Pipeline**.
2. Dans la section Pipeline, choisir **Pipeline script from SCM**, puis **Git**.
3. Renseigner `https://github.com/nakir00/bijouterie-k8s.git` et sélectionner le credential GitHub créé précédemment.
4. Indiquer la branche `*/main` et le chemin `Jenkinsfile`.
5. Enregistrer, puis lancer un premier build.

Le Jenkinsfile demande le label `local` et prévoit les étapes Checkout, Build, Tag et Push. Il vérifie le dépôt périodiquement avec `pollSCM` toutes les cinq minutes environ. Chaque build utilise `build-<numéro>` et `latest` pour les trois images. Il ne modifie pas automatiquement les tags des manifests Kubernetes.

Vérifier que les quatre étapes réussissent et que les trois dépôts publics Docker Hub affichent les nouveaux tags. Les manifests Kubernetes doivent utiliser un tag explicite, pas `latest`. Le premier build de bout en bout et la connexion de l'agent restent à valider sur notre installation.
