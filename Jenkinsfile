pipeline {
    // Le job doit s'exécuter sur un agent équipé de Docker et de Git.
    agent { label 'local' }

    options {
        // Empêche deux builds de se concurrencer sur le tag latest.
        disableConcurrentBuilds()
        // Le stage Checkout ci-dessous gère explicitement la récupération du code.
        skipDefaultCheckout()
    }

    triggers {
        // Vérifie périodiquement la branche configurée dans le job Pipeline.
        pollSCM('H/5 * * * *')
    }

    environment {
        DOCKERHUB_NAMESPACE = 'nabyyy'
        // Le préfixe évite de remplacer les images :1 publiées manuellement.
        IMAGE_TAG = "build-${BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                // Utilise le dépôt et le credential SCM configurés dans le job.
                checkout scm
            }
        }

        stage('Build') {
            steps {
                // Chaque contexte contient le Dockerfile du service correspondant.
                sh '''
                    docker build -t bijouterie-frontend:ci frontend/
                    docker build -t bijouterie-backend:ci backend/
                    docker build -t bijouterie-mysql:ci database/
                '''
            }
        }

        stage('Tag') {
            steps {
                // Chaque image reçoit le numéro du build et le tag latest.
                sh '''
                    for service in frontend backend mysql; do
                        docker tag "bijouterie-${service}:ci" "${DOCKERHUB_NAMESPACE}/bijouterie-${service}:${IMAGE_TAG}"
                        docker tag "bijouterie-${service}:ci" "${DOCKERHUB_NAMESPACE}/bijouterie-${service}:latest"
                    done
                '''
            }
        }

        stage('Push') {
            steps {
                // Le token est stocké dans Jenkins et n'apparaît pas dans le dépôt.
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials',
                    usernameVariable: 'DOCKERHUB_USER', passwordVariable: 'DOCKERHUB_TOKEN')]) {
                    sh '''
                        set +x
                        export DOCKER_CONFIG="$(mktemp -d)"
                        trap 'rm -rf "$DOCKER_CONFIG"' EXIT
                        printf '%s' "$DOCKERHUB_TOKEN" | docker login --username "$DOCKERHUB_USER" --password-stdin
                        for service in frontend backend mysql; do
                            docker push "${DOCKERHUB_NAMESPACE}/bijouterie-${service}:${IMAGE_TAG}"
                            docker push "${DOCKERHUB_NAMESPACE}/bijouterie-${service}:latest"
                        done
                    '''
                }
            }
        }
    }
}
