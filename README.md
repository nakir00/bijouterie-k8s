# Bijouterie — application microservices (CRUD bijoux en or)

Petite boutique en ligne de bijoux en or : catalogue, ajout, modification,
suppression de bijoux, avec **photo** pour chaque bijou.

```
Navigateur ──► frontend (Nginx :80) ──/api/*──► backend (Node.js :3000) ──► mysql (:3306)
```

| Service    | Dossier      | Technologie            | Port | Rôle                                                  |
|------------|--------------|------------------------|------|-------------------------------------------------------|
| `frontend` | `frontend/`  | Nginx 1.27 + HTML/JS   | 80   | Sert le site et relaie `/api/*` vers le backend        |
| `backend`  | `backend/`   | Node.js 20 / Express   | 3000 | API REST CRUD, stockage des photos en base (BLOB)     |
| `mysql`    | `database/`  | MySQL 8.4              | 3306 | Base `bijouterie`, table `bijoux` + données de démo   |

## Lancer en local

```bash
cp .env.example .env          # facultatif
docker compose up --build
```

Puis ouvrir <http://localhost:8080>.

Arrêter : `docker compose down` (ajouter `-v` pour effacer aussi les données MySQL).

## Variables d'environnement

### backend
| Variable                    | Défaut          | Sensible | Description                              |
|-----------------------------|-----------------|----------|------------------------------------------|
| `PORT`                      | `3000`          | non      | Port d'écoute de l'API                    |
| `DB_HOST`                   | *(obligatoire)* | non      | Hôte MySQL (nom du service)               |
| `DB_PORT`                   | `3306`          | non      | Port MySQL                                |
| `DB_NAME`                   | *(obligatoire)* | non      | Nom de la base                            |
| `DB_USER`                   | *(obligatoire)* | **oui**  | Utilisateur MySQL                         |
| `DB_PASSWORD`               | *(obligatoire)* | **oui**  | Mot de passe MySQL                        |
| `SHOP_NAME`                 | `Maison Aurore` | non      | Nom affiché sur le site                   |
| `CURRENCY`                  | `EUR`           | non      | Devise des prix (code ISO 4217)           |
| `MAX_FILE_SIZE_MB`          | `5`             | non      | Taille max d'une photo                    |
| `DB_CONNECT_RETRIES`        | `30`            | non      | Nb de tentatives de connexion au démarrage|
| `DB_CONNECT_RETRY_DELAY_MS` | `3000`          | non      | Délai entre deux tentatives               |

### frontend
| Variable          | Défaut                 | Description                                  |
|-------------------|------------------------|----------------------------------------------|
| `BACKEND_URL`     | `http://backend:3000`  | URL interne du backend (reverse proxy Nginx) |
| `MAX_UPLOAD_SIZE` | `6m`                   | Taille max d'une requête (upload photo)      |

### mysql
`MYSQL_ROOT_PASSWORD`, `MYSQL_DATABASE`, `MYSQL_USER`, `MYSQL_PASSWORD` (toutes obligatoires).

## API REST

| Méthode  | Route                    | Description                                       |
|----------|--------------------------|---------------------------------------------------|
| `GET`    | `/api/health`            | Liveness : le processus répond                    |
| `GET`    | `/api/ready`             | Readiness : la base est joignable (503 sinon)     |
| `GET`    | `/api/config`            | Configuration publique + nom du pod (`servedBy`)  |
| `GET`    | `/api/bijoux`            | Liste (`?categorie=bague&q=or`)                   |
| `GET`    | `/api/bijoux/:id`        | Détail                                            |
| `GET`    | `/api/bijoux/:id/photo`  | Photo du bijou                                    |
| `POST`   | `/api/bijoux`            | Création (`multipart/form-data`, champ `photo`)   |
| `PUT`    | `/api/bijoux/:id`        | Modification (photo facultative, `supprimerPhoto=true`) |
| `DELETE` | `/api/bijoux/:id`        | Suppression                                       |

Champs d'un bijou : `nom`, `description`, `categorie` (`bague`, `collier`,
`bracelet`, `boucles`, `pendentif`, `montre`), `carat` (9, 14, 18, 22, 24),
`poids_g`, `prix`, `stock`.

Exemple :
```bash
curl -F nom="Bague Test" -F categorie=bague -F carat=18 -F poids_g=3.5 \
     -F prix=450 -F stock=2 -F photo=@bague.jpg http://localhost:8080/api/bijoux
```

## Remarques techniques

- Les photos sont stockées **dans MySQL** (colonne `LONGBLOB`) : le backend ne
  garde aucun fichier sur disque, il peut donc tourner avec plusieurs replicas.
- Le backend crée la table si elle n'existe pas et réessaie de se connecter à
  MySQL tant que la base n'est pas prête.
- Le frontend n'appelle que des URL relatives (`/api/...`) ; seul le frontend a
  besoin d'être exposé à l'extérieur.

---

## Organisation du dépôt

- `frontend/`, `backend/`, `database/` : application et Dockerfiles fournis.
- `docker-compose.yml` : démarrage local.
- `k8s/` : manifests de Bijouterie ; `k8s/00-installation/` contient ceux des outils.
- `Jenkinsfile` : pipeline CI.
- `argocd/application.yaml` : Application Argo CD qui surveille les YAML à la racine de `k8s/`.

## Installation et déploiement Kubernetes

Ce guide présente les commandes dans l'ordre pour un **nouveau cluster**. Lancer les commandes depuis la racine de ce dépôt. Jenkins et Argo CD déjà présents sur un cluster ne doivent pas être remplacés sans examiner leur configuration.

### 1. Vérifier les prérequis

Il faut `kubectl`, un accès administrateur au cluster, une connexion Internet, une StorageClass par défaut pour Jenkins, et un accès au dépôt Git privé. Les images Docker Hub référencées dans `k8s/` doivent être publiées avec les tags indiqués avant le déploiement de Bijouterie.

```bash
kubectl config current-context
kubectl get nodes
kubectl get storageclass
```

Vérifier que le contexte est le bon, que le nœud est `Ready` et qu'une StorageClass est marquée `(default)`.

### 2. Installer et configurer Jenkins

La procédure détaillée figure plus bas dans la section « Configuration de Jenkins ».

### 3. Installer Argo CD

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

Ouvrir https://localhost:8082 et suivre les indications de la section « Informations Argo CD » pour la connexion. Dans l'interface Argo CD, configurer un accès HTTPS en lecture au dépôt privé `https://github.com/nakir00/bijouterie-k8s.git` avec un credential GitHub adapté. Saisir le token directement dans l'interface ; ne pas le copier dans le dépôt.

### 4. Déployer Bijouterie avec Argo CD

**Avant cette étape**, vérifier dans Docker Hub que les trois images et les tags indiqués dans les Deployments existent et sont publics, et que la connexion au dépôt privé est établie dans Argo CD. Les images `:1` ont été publiées manuellement ; Jenkins peut produire les versions suivantes.

Depuis un autre terminal, créer l'Application Argo CD :

```bash
kubectl apply -f argocd/application.yaml
kubectl -n argocd get application bijouterie
kubectl -n bijouterie get pods,svc
```

Dans l'interface Argo CD, attendre les états `Synced` et `Healthy`. Sur Docker Desktop, ouvrir ensuite http://localhost:30080 ; sur un autre cluster, utiliser l'adresse d'un nœud avec le port `30080`. Vérifier les répliques et tester le catalogue.

L'Application lit uniquement les fichiers YAML à la racine de `k8s/`, pas le sous-dossier `00-installation/`. Après ce premier lancement, les modifications de l'application passent par Git et Argo CD ; ne pas appliquer manuellement les manifests de Bijouterie. Si `argocd/application.yaml` lui-même change, il doit être réappliqué : il n'est pas surveillé par l'Application actuelle.

---

## Configuration de Jenkins

Les manifests de `k8s/00-installation/01-jenkins/` installent Jenkins avec son image officielle. La première configuration, les plugins, les credentials, le job et le nœud de build se configurent manuellement dans l'interface.

### 1. Installer et ouvrir Jenkins

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

### 2. Ajouter les credentials

Dans **Administrer Jenkins → Credentials**, ouvrir le domaine global, puis ajouter :

1. **Docker Hub** : type `Username with password`, identifiant `dockerhub-credentials`, utilisateur `nabyyy`, mot de passe = token Docker Hub ayant les droits de lecture et d'écriture.
2. **GitHub** : type `Username with password`, identifiant par exemple `github-read-credentials`, utilisateur `nakir00`, mot de passe = token ayant accès en lecture à ce dépôt privé.

Saisir les tokens directement dans Jenkins. Ne pas les ajouter au dépôt, les envoyer dans une conversation ou les laisser apparaître dans les captures. Le Secret Kubernetes éventuellement créé auparavant n'est pas importé automatiquement par cette configuration manuelle.

### 3. Ajouter un nœud sur la machine hôte

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

### 4. Créer le job Pipeline

Depuis l'accueil Jenkins :

1. Créer un nouvel élément `bijouterie` de type **Pipeline**.
2. Dans la section Pipeline, choisir **Pipeline script from SCM**, puis **Git**.
3. Renseigner `https://github.com/nakir00/bijouterie-k8s.git` et sélectionner le credential GitHub créé précédemment.
4. Indiquer la branche `*/main` et le chemin `Jenkinsfile`.
5. Enregistrer, puis lancer un premier build.

Le Jenkinsfile demande le label `local` et prévoit les étapes Checkout, Build, Tag et Push. Il vérifie le dépôt périodiquement avec `pollSCM` toutes les cinq minutes environ. Chaque build utilise `build-<numéro>` et `latest` pour les trois images. Il ne modifie pas automatiquement les tags des manifests Kubernetes.

Vérifier que les quatre étapes réussissent et que les trois dépôts publics Docker Hub affichent les nouveaux tags. Les manifests Kubernetes doivent utiliser un tag explicite, pas `latest`. Un build complet a été validé sur notre installation avec l’agent local.

---

## Informations Argo CD

Le fichier `k8s/00-installation/02-argocd/kustomization.yaml` référence le manifeste officiel Argo CD v3.6.1 sur GitHub. L'accès à ce fichier et aux images nécessite Internet.

Le mot de passe initial du compte `admin`, s'il existe encore, se trouve dans le Secret `argocd-initial-admin-secret` du namespace `argocd` : le consulter localement sans le partager. Le certificat local peut nécessiter une exception dans le navigateur.

Source : https://argo-cd.readthedocs.io/en/stable/getting_started/
