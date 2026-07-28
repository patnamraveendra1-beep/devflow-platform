pipeline {
    agent any

    environment {
        DOCKERHUB_USER = "patnamraveendra"
        BACKEND_IMAGE = "${DOCKERHUB_USER}/devflow-backend"
        FRONTEND_IMAGE = "${DOCKERHUB_USER}/devflow-frontend"
        KUBECONFIG = "/var/lib/jenkins/.kube/config"
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                    credentialsId: 'github-creds',
                    url: 'https://github.com/patnamraveendra1-beep/devflow-platform.git'
            }
        }

        stage('Build Backend Image') {
            steps {
                dir('backend') {
                    sh """
                        docker build -t ${BACKEND_IMAGE}:${BUILD_NUMBER} .
                        docker tag ${BACKEND_IMAGE}:${BUILD_NUMBER} ${BACKEND_IMAGE}:latest
                    """
                }
            }
        }

        stage('Build Frontend Image') {
            steps {
                dir('frontend') {
                    sh """
                        docker build -t ${FRONTEND_IMAGE}:${BUILD_NUMBER} .
                        docker tag ${FRONTEND_IMAGE}:${BUILD_NUMBER} ${FRONTEND_IMAGE}:latest
                    """
                }
            }
        }

        stage('Docker Login') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-creds',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )
                ]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin
                    '''
                }
            }
        }

        stage('Push Images') {
            steps {
                sh """
                    docker push ${BACKEND_IMAGE}:${BUILD_NUMBER}
                    docker push ${BACKEND_IMAGE}:latest

                    docker push ${FRONTEND_IMAGE}:${BUILD_NUMBER}
                    docker push ${FRONTEND_IMAGE}:latest
                """
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh """
                    export KUBECONFIG=${KUBECONFIG}

                    kubectl apply -f kubernetes/

                    kubectl rollout restart deployment/devflow-backend -n devflow
                    kubectl rollout restart deployment/devflow-frontend -n devflow

                    kubectl rollout status deployment/devflow-backend -n devflow
                    kubectl rollout status deployment/devflow-frontend -n devflow
                """
            }
        }

        stage('Verify Deployment') {
            steps {
                sh """
                    export KUBECONFIG=${KUBECONFIG}

                    echo "===== Nodes ====="
                    kubectl get nodes

                    echo "===== Pods ====="
                    kubectl get pods -n devflow

                    echo "===== Services ====="
                    kubectl get svc -n devflow

                    echo "===== Deployments ====="
                    kubectl get deployments -n devflow
                """
            }
        }

        stage('Cleanup') {
            steps {
                sh '''
                    docker image prune -af
                '''
            }
        }
    }

    post {
        always {
            sh '''
                echo "===== Running Containers ====="
                docker ps

                echo "===== Docker Images ====="
                docker images | head
            '''
        }

        success {
            echo "✅ Kubernetes Deployment Successful!"
        }

        failure {
            echo "❌ Pipeline Failed!"
        }
    }
}
