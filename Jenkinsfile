pipeline {
    agent any

    environment {
        DOCKER_USERNAME = "patnamraveendra"
        BACKEND_IMAGE = "patnamraveendra/devflow-backend"
        FRONTEND_IMAGE = "patnamraveendra/devflow-frontend"
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

        stage('Push Docker Images') {
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
                sh '''
                export KUBECONFIG=/var/lib/jenkins/.kube/config
                export PATH=/usr/local/bin:/usr/bin:/bin

                echo "=================================="
                echo "Waiting for Kubernetes API"
                echo "=================================="

                for i in $(seq 1 30)
                do
                    if kubectl cluster-info >/dev/null 2>&1
                    then
                        echo "Kubernetes API Ready"
                        break
                    fi

                    echo "Attempt $i/30..."
                    sleep 10
                done

                kubectl cluster-info

                echo "=================================="
                echo "Applying Kubernetes manifests"
                echo "=================================="

                kubectl apply -f kubernetes/

                echo "=================================="
                echo "Updating Backend Image"
                echo "=================================="

                kubectl set image deployment/devflow-backend \
                backend=${BACKEND_IMAGE}:${BUILD_NUMBER} \
                -n devflow

                echo "=================================="
                echo "Updating Frontend Image"
                echo "=================================="

                kubectl set image deployment/devflow-frontend \
                frontend=${FRONTEND_IMAGE}:${BUILD_NUMBER} \
                -n devflow

                echo "=================================="
                echo "Backend Rollout"
                echo "=================================="

                kubectl rollout status deployment/devflow-backend \
                -n devflow \
                --timeout=600s

                echo "=================================="
                echo "Frontend Rollout"
                echo "=================================="

                kubectl rollout status deployment/devflow-frontend \
                -n devflow \
                --timeout=600s
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                export KUBECONFIG=/var/lib/jenkins/.kube/config

                kubectl get deployments -n devflow
                kubectl get pods -n devflow
                kubectl get svc -n devflow
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
            echo "=================================="
            echo "Deployment Successful"
            echo "=================================="

            sh '''
            export KUBECONFIG=/var/lib/jenkins/.kube/config

            kubectl get pods -n devflow
            kubectl get svc -n devflow
            '''
        }

        failure {
            echo "=================================="
            echo "Deployment Failed"
            echo "=================================="

            sh '''
            export KUBECONFIG=/var/lib/jenkins/.kube/config

            kubectl get nodes || true
            kubectl get deployments -n devflow || true
            kubectl get pods -n devflow -o wide || true
            kubectl describe deployment devflow-backend -n devflow || true
            kubectl describe deployment devflow-frontend -n devflow || true
            kubectl get events -n devflow --sort-by=.metadata.creationTimestamp | tail -30 || true
            '''
        }

        always {
            sh '''
            docker logout || true
            '''
        }
    }
}
