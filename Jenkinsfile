pipeline {
    agent any

    tools {
        maven "Maven"
        jdk "JDK17"
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/alaabenterdayet1/devops-tp.git'
            }
        }

        stage('Build') {
            steps {
                sh "mvn clean package -Dmaven.test.skip=true"
            }
        }
    }
}