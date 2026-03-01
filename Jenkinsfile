 pipeline {
    agent any
    
    tools {
        maven "Maven"
        jdk "JDK17"
    }
    
    environment {
        DOCKER_HUB_REPO = 'alaabenterdayet/student-management'
        SONAR_HOST_URL = 'http://192.168.56.10:9000'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo 'Cloning repository...'
                git branch: 'main', url: 'https://github.com/alaabenterdayet1/devops-tp.git'
            }
        }
        
        stage('Build') {
            steps {
                echo 'Building with Maven...'
                sh "mvn clean package -Dmaven.test.skip=true"
            }
        }
        
        stage('SonarQube Analysis') {
            steps {
                echo 'Running SonarQube analysis...'
                withSonarQubeEnv('SonarQube') {
                    sh """
                        mvn sonar:sonar \
                          -Dsonar.projectKey=student-management \
                          -Dsonar.projectName='Student Management' \
                          -Dsonar.host.url=${SONAR_HOST_URL}
                    """
                }
            }
        }
        
        stage('Quality Gate') {
            steps {
                echo 'Waiting for Quality Gate...'
                timeout(time: 5, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: false
                }
            }
        }
        
        stage('Docker Build') {
            steps {
                echo 'Building Docker image...'
                sh "docker build -t ${DOCKER_HUB_REPO}:${BUILD_NUMBER} ."
                sh "docker build -t ${DOCKER_HUB_REPO}:latest ."
            }
        }
        
        stage('Docker Push') {
            steps {
                echo 'Pushing to DockerHub...'
                withCredentials([usernamePassword(credentialsId: 'dockerhub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh "echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin"
                    sh "docker push ${DOCKER_HUB_REPO}:${BUILD_NUMBER}"
                    sh "docker push ${DOCKER_HUB_REPO}:latest"
                }
            }
        }
        
        stage('Deploy') {
            steps {
                echo 'Deploying container...'
                sh """
                    docker stop student-app || true
                    docker rm student-app || true
                    docker run -d -p 8089:8089 --name student-app ${DOCKER_HUB_REPO}:latest
                """
            }
        }
    }
    
    post {
        success {
            echo '✅ Pipeline exécuté avec succès!'
        }
        failure {
            echo '❌ Le pipeline a échoué.'
        }
        always {
            echo 'Cleaning workspace...'
            cleanWs()
        }
    }
}
