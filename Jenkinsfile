pipeline {
    agent any

    environment {
        BACKEND_IMAGE = 'patnamraveendra/devflow-backend'
        FRONTEND_IMAGE = 'patnamraveendra/devflow-frontend'
        IMAGE_TAG = "${BUILD_NUMBER}"

        // Jenkins user kubeconfig
        KUBECONFIG = '/var/lib/jenkins/.kube/config'
        KUBECTL = '/snap/bin/kubectl'
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

                    ${KUBECTL} version --client

                    ${KUBECTL} apply -f kubernetes/

                    ${KUBECTL} rollout restart deployment/devflow-backend -n devflow
                    ${KUBECTL} rollout restart deployment/devflow-frontend -n devflow

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
                    ${KUBECTL} get pods -n devflow

                    echo "===== Services ====="
                    ${KUBECTL} get svc -n devflow

                    echo "===== Deployments ====="
                    ${KUBECTL} get deployments -n devflow
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
            echo '✅ Kubernetes Deployment Successful!'
        }

        failure {
            echo '❌ Kubernetes Deployment Failed!'
        }

        always {
            sh '''
                docker ps
                docker images | head
            '''
        }
    }
}

