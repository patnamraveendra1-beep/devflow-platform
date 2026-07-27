pipeline {
    agent any

    environment {
        BACKEND_IMAGE = "patnamraveendra/devflow-backend"
        FRONTEND_IMAGE = "patnamraveendra/devflow-frontend"
        IMAGE_TAG = "${BUILD_NUMBER}"

        KUBECTL = "/usr/local/bin/kubectl"
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
                sh """
                    export PATH=/usr/local/bin:/usr/bin:/bin
                    export KUBECONFIG=${KUBECONFIG}

                    echo "Current Context"
                    kubectl config current-context

                    echo "Cluster"
                    kubectl cluster-info

                    echo "Nodes"
                    kubectl get nodes

                    echo "Applying Kubernetes manifests"
                    kubectl apply -f kubernetes/

                    echo "Updating Backend Image"
                    kubectl set image deployment/devflow-backend \
                        backend=${BACKEND_IMAGE}:${IMAGE_TAG} \
                        -n devflow

                    echo "Updating Frontend Image"
                    kubectl set image deployment/devflow-frontend \
                        frontend=${FRONTEND_IMAGE}:${IMAGE_TAG} \
                        -n devflow

                    echo "Waiting 20 seconds..."
                    sleep 20

                    echo "Backend Rollout"
                    kubectl rollout status deployment/devflow-backend \
                        -n devflow \
                        --timeout=300s

                    echo "Frontend Rollout"
                    kubectl rollout status deployment/devflow-frontend \
                        -n devflow \
                        --timeout=300s
                """
            }
        }

        stage('Verify Deployment') {
            steps {
                sh """
                    export KUBECONFIG=${KUBECONFIG}

                    kubectl get deployments -n devflow
                    kubectl get pods -n devflow -o wide
                    kubectl get svc -n devflow
                """
            }
        }

        stage('Cleanup') {
            steps {
                sh "docker image prune -f"
            }
        }
    }

    post {

        success {
            echo "Deployment Successful"
        }

        failure {
            echo "Deployment Failed"

            sh """
                export KUBECONFIG=${KUBECONFIG}

                kubectl get deployments -n devflow || true
                kubectl get pods -n devflow -o wide || true

                kubectl describe deployment devflow-backend -n devflow || true
                kubectl describe deployment devflow-frontend -n devflow || true

                kubectl get events -n devflow --sort-by=.metadata.creationTimestamp | tail -30 || true
            """
        }

        always {
            sh """
                docker ps
                docker images | head

                export KUBECONFIG=${KUBECONFIG}

                kubectl get nodes || true
                kubectl get deployments -n devflow || true
                kubectl get pods -n devflow || true
                kubectl get svc -n devflow || true
            """
        }
    }
}
