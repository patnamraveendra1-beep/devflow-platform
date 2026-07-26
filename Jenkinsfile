pipeline {
    agent any

    environment {
        BACKEND_IMAGE = "patnamraveendra/devflow-backend"
        FRONTEND_IMAGE = "patnamraveendra/devflow-frontend"
        IMAGE_TAG = "${BUILD_NUMBER}"
        KUBECONFIG = "/home/ubuntu/.kube/config"
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/patnamraveendra1-beep/devflow-platform.git'
            }
        }

        stage('Build Backend Image') {
            steps {
                sh '''
                cd backend
                docker build -t $BACKEND_IMAGE:$IMAGE_TAG .
                docker tag $BACKEND_IMAGE:$IMAGE_TAG $BACKEND_IMAGE:latest
                '''
            }
        }

        stage('Build Frontend Image') {
            steps {
                sh '''
                cd frontend
                docker build -t $FRONTEND_IMAGE:$IMAGE_TAG .
                docker tag $FRONTEND_IMAGE:$IMAGE_TAG $FRONTEND_IMAGE:latest
                '''
            }
        }

        stage('Docker Login') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                    echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                    '''
                }
            }
        }

        stage('Push Docker Images') {
            steps {
                sh '''
                docker push $BACKEND_IMAGE:$IMAGE_TAG
                docker push $BACKEND_IMAGE:latest

                docker push $FRONTEND_IMAGE:$IMAGE_TAG
                docker push $FRONTEND_IMAGE:latest
                '''
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh '''
                export KUBECONFIG=$KUBECONFIG

                kubectl apply -f kubernetes/namespace.yaml

                kubectl apply -f kubernetes/backend-deployment.yaml
                kubectl apply -f kubernetes/backend-service.yaml

                kubectl apply -f kubernetes/frontend-deployment.yaml
                kubectl apply -f kubernetes/frontend-service.yaml

                kubectl rollout restart deployment/devflow-backend -n devflow
                kubectl rollout restart deployment/devflow-frontend -n devflow

                kubectl rollout status deployment/devflow-backend -n devflow
                kubectl rollout status deployment/devflow-frontend -n devflow
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                export KUBECONFIG=$KUBECONFIG

                kubectl get nodes

                kubectl get pods -n devflow

                kubectl get svc -n devflow

                kubectl get deployments -n devflow
                '''
            }
        }

        stage('Cleanup') {
            steps {
                sh '''
                docker image prune -f
                '''
            }
        }
    }

    post {

        success {
            echo '✅ CI/CD Pipeline Completed Successfully!'
        }

        failure {
            echo '❌ CI/CD Pipeline Failed!'
        }

        always {
            sh '''
            docker ps
            docker images | head
            '''
        }
    }
}
