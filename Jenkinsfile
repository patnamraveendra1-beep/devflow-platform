pipeline {
    agent any

    environment {
        BACKEND_IMAGE = "patnamraveendra/devflow-backend"
        FRONTEND_IMAGE = "patnamraveendra/devflow-frontend"
        IMAGE_TAG = "${BUILD_NUMBER}"

        KUBECTL = "/usr/local/bin/kubectl"
        KUBECONFIG = "/var/lib/jenkins/.kube/config"
        PATH = "/usr/local/bin:/usr/bin:/bin"
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
                sh '''
                    export PATH=/usr/local/bin:/usr/bin:/bin
                    export KUBECONFIG=/var/lib/jenkins/.kube/config

                    echo "=============================="
                    echo " Kubernetes Information"
                    echo "=============================="

                    kubectl config current-context
                    kubectl version --client
                    kubectl cluster-info
                    kubectl get nodes

                    echo "=============================="
                    echo " Applying Manifests"
                    echo "=============================="

                    kubectl apply -f kubernetes/

                    echo "=============================="
                    echo " Updating Backend Image"
                    echo "=============================="

                    kubectl set image deployment/devflow-backend \
                        backend=''' + BACKEND_IMAGE + ''':'${IMAGE_TAG} \
                        -n devflow

                    echo "=============================="
                    echo " Updating Frontend Image"
                    echo "=============================="

                    kubectl set image deployment/devflow-frontend \
                        frontend=''' + FRONTEND_IMAGE + ''':'${IMAGE_TAG} \
                        -n devflow

                    echo "Waiting for deployment..."
                    sleep 20

                    echo "=============================="
                    echo " Backend Rollout"
                    echo "=============================="

                    kubectl rollout status deployment/devflow-backend \
                        -n devflow \
                        --timeout=300s

                    echo "=============================="
                    echo " Frontend Rollout"
                    echo "=============================="

                    kubectl rollout status deployment/devflow-frontend \
                        -n devflow \
                        --timeout=300s
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                    export KUBECONFIG=/var/lib/jenkins/.kube/config

                    echo "=============================="
                    echo " Pods"
                    echo "=============================="
                    kubectl get pods -n devflow -o wide

                    echo "=============================="
                    echo " Deployments"
                    echo "=============================="
                    kubectl get deployments -n devflow

                    echo "=============================="
                    echo " Services"
                    echo "=============================="
                    kubectl get svc -n devflow

                    echo "=============================="
                    echo " Rollout History"
                    echo "=============================="
                    kubectl rollout history deployment/devflow-backend -n devflow
                    kubectl rollout history deployment/devflow-frontend -n devflow
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
            echo "✅ Deployment Successful!"
        }

        failure {
            echo "❌ Deployment Failed!"

            sh '''
                export KUBECONFIG=/var/lib/jenkins/.kube/config

                echo "=============================="
                echo " Deployment Status"
                echo "=============================="

                kubectl get deployments -n devflow || true

                echo "=============================="
                echo " Pods"
                echo "=============================="

                kubectl get pods -n devflow -o wide || true

                echo "=============================="
                echo " Describe Backend"
                echo "=============================="

                kubectl describe deployment devflow-backend -n devflow || true

                echo "=============================="
                echo " Describe Frontend"
                echo "=============================="

                kubectl describe deployment devflow-frontend -n devflow || true

                echo "=============================="
                echo " Events"
                echo "=============================="

                kubectl get events -n devflow --sort-by=.metadata.creationTimestamp | tail -30 || true
            '''
        }

        always {
            sh '''
                echo "=============================="
                echo " Docker Containers"
                echo "=============================="
                docker ps

                echo "=============================="
                echo " Docker Images"
                echo "=============================="
                docker images | head

                export KUBECONFIG=/var/lib/jenkins/.kube/config

                echo "=============================="
                echo " Final Kubernetes Status"
                echo "=============================="

                kubectl get nodes || true
                kubectl get pods -n devflow || true
                kubectl get svc -n devflow || true
                kubectl get deployments -n devflow || true
            '''
        }
    }
}
