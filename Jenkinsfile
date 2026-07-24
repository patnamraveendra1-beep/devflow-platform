pipeline {
    agent any

    environment {
        IMAGE_NAME = "patnamraveendra/devflow-backend:v1"
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/patnamraveendra1-beep/devflow-platform.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                cd backend
                docker build -t $IMAGE_NAME .
                '''
            }
        }
    }
}
