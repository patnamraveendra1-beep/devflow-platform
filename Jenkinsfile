pipeline {
    agent any

    environment {
        DOCKER_USER = "patnamraveendra"
        BACKEND_IMAGE = "patnamraveendra/devflow-backend"
        FRONTEND_IMAGE = "patnamraveendra/devflow-frontend"
        BUILD_TAG = "${BUILD_NUMBER}"
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
                    sh """
                    docker build -t ${BACKEND_IMAGE}:${BUILD_TAG} .
                    docker tag ${BACKEND_IMAGE}:${BUILD_TAG} ${BACKEND_IMAGE}:latest
                    """
                }
            }
        }

        stage('Build Frontend Image') {
            steps {
                dir('frontend') {
                    sh """
                    docker build -t ${FRONTEND_IMAGE}:${BUILD_TAG} .
                    docker tag ${FRONTEND_IMAGE}:${BUILD_TAG} ${FRONTEND_IMAGE}:latest
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

        stage('Push Docker Images') {
            steps {
                sh """
                docker push ${BACKEND_IMAGE}:${BUILD_TAG}
                docker push ${BACKEND_IMAGE}:latest

                docker push ${FRONTEND_IMAGE}:${BUILD_TAG}
                docker push ${FRONTEND_IMAGE}:latest
                """
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh '''
                export PATH=/usr/local/bin:/usr/bin:/bin:$PATH
                export KUBECONFIG=/var/lib/jenkins/.kube/config

                echo "PATH=$PATH"

                which kubectl

                kubectl version --client

                kubectl get nodes

                kubectl apply -f k8s/

                kubectl rollout restart deployment/devflow-backend
                kubectl rollout restart deployment/devflow-frontend

                kubectl rollout status deployment/devflow-backend --timeout=180s
                kubectl rollout status deployment/devflow-frontend --timeout=180s
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                export KUBECONFIG=/var/lib/jenkins/.kube/config

                kubectl get pods
                kubectl get svc
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
            echo "✅ Pipeline completed successfully."
        }

        failure {
            echo "❌ Kubernetes Deployment Failed!"

            sh '''
            echo "========== RUNNING CONTAINERS =========="
            docker ps

            echo "========== DOCKER IMAGES =========="
            docker images | head

            echo "========== KUBERNETES PODS =========="
            export KUBECONFIG=/var/lib/jenkins/.kube/config
            kubectl get pods -A || true
            '''
        }
    }
}
