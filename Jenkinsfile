pipeline {
    agent any

    environment {
        BACKEND_IMAGE = "patnamraveendra/devflow-backend"
        FRONTEND_IMAGE = "patnamraveendra/devflow-frontend"
        IMAGE_TAG = "${BUILD_NUMBER}"
        KUBECONFIG = "/var/lib/jenkins/.kube/config"
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
                        docker build -t ${BACKEND_IMAGE}:${IMAGE_TAG} .
                        docker tag ${BACKEND_IMAGE}:${IMAGE_TAG} ${BACKEND_IMAGE}:latest
                    """
                }
            }
        }

        stage('Build Frontend Image') {
            steps {
                dir('frontend') {
                    sh """
                        docker build -t ${FRONTEND_IMAGE}:${IMAGE_TAG} .
                        docker tag ${FRONTEND_IMAGE}:${IMAGE_TAG} ${FRONTEND_IMAGE}:latest
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
                    docker push ${BACKEND_IMAGE}:${IMAGE_TAG}
                    docker push ${BACKEND_IMAGE}:latest

                    docker push ${FRONTEND_IMAGE}:${IMAGE_TAG}
                    docker push ${FRONTEND_IMAGE}:latest
                """
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh '''
                    set -eux

                    export KUBECONFIG=/var/lib/jenkins/.kube/config
                    export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH

                    echo "========== DEBUG =========="
                    hostname
                    whoami
                    pwd

                    echo "PATH=$PATH"

                    echo "Checking kubectl..."
                    which kubectl || true
                    find /usr -name kubectl 2>/dev/null || true

                    if [ -x /usr/local/bin/kubectl ]; then
                        KUBECTL=/usr/local/bin/kubectl
                    elif [ -x /usr/bin/kubectl ]; then
                        KUBECTL=/usr/bin/kubectl
                    else
                        echo "ERROR: kubectl not found"
                        exit 1
                    fi

                    echo "Using: $KUBECTL"

                    $KUBECTL version --client
                    $KUBECTL get nodes

                    echo "Applying Kubernetes manifests..."
                    $KUBECTL apply -f kubernetes/

                    echo "Updating backend image..."
                    $KUBECTL set image deployment/devflow-backend \
                        devflow-backend=patnamraveendra/devflow-backend:${BUILD_NUMBER} \
                        -n devflow

                    echo "Updating frontend image..."
                    $KUBECTL set image deployment/devflow-frontend \
                        devflow-frontend=patnamraveendra/devflow-frontend:${BUILD_NUMBER} \
                        -n devflow

                    echo "Waiting for rollout..."
                    $KUBECTL rollout status deployment/devflow-backend \
                        -n devflow --timeout=180s

                    $KUBECTL rollout status deployment/devflow-frontend \
                        -n devflow --timeout=180s
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                    set -eux

                    export KUBECONFIG=/var/lib/jenkins/.kube/config

                    if [ -x /usr/local/bin/kubectl ]; then
                        KUBECTL=/usr/local/bin/kubectl
                    else
                        KUBECTL=$(which kubectl)
                    fi

                    echo "========== NODES =========="
                    $KUBECTL get nodes

                    echo "========== PODS =========="
                    $KUBECTL get pods -n devflow

                    echo "========== SERVICES =========="
                    $KUBECTL get svc -n devflow

                    echo "========== DEPLOYMENTS =========="
                    $KUBECTL get deployments -n devflow
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
                echo "========== RUNNING CONTAINERS =========="
                docker ps

                echo "========== DOCKER IMAGES =========="
                docker images | head -20

                export KUBECONFIG=/var/lib/jenkins/.kube/config

                if [ -x /usr/local/bin/kubectl ]; then
                    /usr/local/bin/kubectl get pods -A || true
                else
                    which kubectl || true
                fi
            '''
        }
    }
}
