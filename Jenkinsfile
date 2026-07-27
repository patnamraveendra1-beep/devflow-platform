pipeline {
    agent any

    environment {
        BACKEND_IMAGE = "patnamraveendra/devflow-backend"
        FRONTEND_IMAGE = "patnamraveendra/devflow-frontend"
        IMAGE_TAG = "${BUILD_NUMBER}"
        KUBECONFIG = "/var/lib/jenkins/.kube/config"
        KUBECTL = "/usr/local/bin/kubectl"
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
                dir('backend') {
                    sh '''
                    docker build -t ${BACKEND_IMAGE}:${IMAGE_TAG} .
                    docker tag ${BACKEND_IMAGE}:${IMAGE_TAG} ${BACKEND_IMAGE}:latest
                    '''
                }
            }
        }

        stage('Build Frontend Image') {
            steps {
                dir('frontend') {
                    sh '''
                    docker build -t ${FRONTEND_IMAGE}:${IMAGE_TAG} .
                    docker tag ${FRONTEND_IMAGE}:${IMAGE_TAG} ${FRONTEND_IMAGE}:latest
                    '''
                }
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
                docker push ${BACKEND_IMAGE}:${IMAGE_TAG}
                docker push ${BACKEND_IMAGE}:latest
                docker push ${FRONTEND_IMAGE}:${IMAGE_TAG}
                docker push ${FRONTEND_IMAGE}:latest
                '''
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh '''
                export PATH=/usr/local/bin:/usr/bin:/bin
                export KUBECONFIG=/var/lib/jenkins/.kube/config

                which kubectl
                kubectl version --client
                kubectl get nodes

                kubectl apply -f kubernetes/

                kubectl set image deployment/devflow-backend \
                  devflow-backend=${BACKEND_IMAGE}:${IMAGE_TAG} -n devflow

                kubectl set image deployment/devflow-frontend \
                  devflow-frontend=${FRONTEND_IMAGE}:${IMAGE_TAG} -n devflow

                kubectl rollout status deployment/devflow-backend -n devflow --timeout=180s
                kubectl rollout status deployment/devflow-frontend -n devflow --timeout=180s
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                export KUBECONFIG=/var/lib/jenkins/.kube/config

                kubectl get nodes
                kubectl get pods -n devflow
                kubectl get svc -n devflow
                kubectl get deployments -n devflow
                '''
            }
        }

        stage('Cleanup') {
            steps {
                sh 'docker image prune -f'
            }
        }
    }

    post {
        success {
            echo 'Deployment Successful'
        }

        failure {
            echo 'Deployment Failed'
        }

        always {
            sh '''
            docker ps
            docker images | head

            export KUBECONFIG=/var/lib/jenkins/.kube/config

            kubectl get pods -A || true
            '''
        }
    }
}
