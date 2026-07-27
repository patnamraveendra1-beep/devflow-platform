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
                sh '''
                cd backend

                docker build -t ${BACKEND_IMAGE}:${IMAGE_TAG} .
                docker tag ${BACKEND_IMAGE}:${IMAGE_TAG} ${BACKEND_IMAGE}:latest
                '''
            }
        }

        stage('Build Frontend Image') {
            steps {
                sh '''
                cd frontend

                docker build -t ${FRONTEND_IMAGE}:${IMAGE_TAG} .
                docker tag ${FRONTEND_IMAGE}:${IMAGE_TAG} ${FRONTEND_IMAGE}:latest
                '''
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
                export KUBECONFIG=${KUBECONFIG}

                echo "===== Kubernetes Client ====="
                ${KUBECTL} version --client

                echo "===== Cluster Nodes ====="
                ${KUBECTL} get nodes

                echo "===== Applying Manifests ====="
                ${KUBECTL} apply -f kubernetes/

                echo "===== Restart Deployments ====="
                ${KUBECTL} rollout restart deployment/devflow-backend -n devflow
                ${KUBECTL} rollout restart deployment/devflow-frontend -n devflow

                echo "===== Waiting for Rollout ====="
                ${KUBECTL} rollout status deployment/devflow-backend -n devflow
                ${KUBECTL} rollout status deployment/devflow-frontend -n devflow
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                export KUBECONFIG=${KUBECONFIG}

                echo "===== Nodes ====="
                ${KUBECTL} get nodes

                echo "===== Pods ====="
                ${KUBECTL} get pods -n devflow -o wide

                echo "===== Services ====="
                ${KUBECTL} get svc -n devflow

                echo "===== Deployments ====="
                ${KUBECTL} get deployments -n devflow

                echo "===== Rollout Status ====="
                ${KUBECTL} rollout status deployment/devflow-backend -n devflow
                ${KUBECTL} rollout status deployment/devflow-frontend -n devflow
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
            echo '✅ Kubernetes Deployment Successful!'
        }

        failure {
            echo '❌ Kubernetes Deployment Failed!'
        }

        always {
            sh '''
            echo "========== RUNNING CONTAINERS =========="
            docker ps

            echo "========== DOCKER IMAGES =========="
            docker images | head
            '''
        }
    }
}
