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
                    export PATH=${PATH}
                    export KUBECONFIG=${KUBECONFIG}

                    echo "===== PATH ====="
                    echo \$PATH

                    echo "===== KUBECTL ====="
                    ls -l ${KUBECTL}

                    ${KUBECTL} version --client

                    ${KUBECTL} get nodes

                    ${KUBECTL} apply -f kubernetes/

                    ${KUBECTL} set image deployment/devflow-backend \
                    devflow-backend=${BACKEND_IMAGE}:${IMAGE_TAG} \
                    -n devflow

                    ${KUBECTL} set image deployment/devflow-frontend \
                    devflow-frontend=${FRONTEND_IMAGE}:${IMAGE_TAG} \
                    -n devflow

                    ${KUBECTL} rollout status deployment/devflow-backend \
                    -n devflow --timeout=180s

                    ${KUBECTL} rollout status deployment/devflow-frontend \
                    -n devflow --timeout=180s
                """
            }
        }

        stage('Verify Deployment') {
            steps {
                sh """
                    export KUBECONFIG=${KUBECONFIG}

                    ${KUBECTL} get nodes

                    ${KUBECTL} get pods -n devflow

                    ${KUBECTL} get svc -n devflow

                    ${KUBECTL} get deployments -n devflow
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
            echo 'Deployment Successful'
        }

        failure {
            echo 'Deployment Failed'
        }

        always {

            sh """
                docker ps

                docker images | head

                export KUBECONFIG=${KUBECONFIG}

                ${KUBECTL} get pods -A || true
            """
        }
    }
}
