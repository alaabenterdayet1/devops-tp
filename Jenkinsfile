pipeline {
    agent any
    tools {
        maven "Maven"
        jdk "JDK17"
    }
    environment {
        DOCKER_HUB_REPO = 'alaabenterdayet/student-management'
        SONAR_HOST_URL  = 'http://192.168.56.10:9000'
        NAMESPACE       = 'devops'
        KUBECONFIG      = '/var/lib/jenkins/.kube/config'
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
                          -Dsonar.projectName=Student_Management \
                          -Dsonar.host.url=${SONAR_HOST_URL} \
                          -Dsonar.login=162ec4ac13f09642e1b3b4c1f65a590b84499353
                    """
                }
            }
        }

        stage('Quality Gate') {
            steps {
                echo 'Waiting for Quality Gate...'
                catchError(buildResult: 'SUCCESS', stageResult: 'UNSTABLE') {
                    timeout(time: 5, unit: 'MINUTES') {
                        waitForQualityGate abortPipeline: false
                    }
                }
            }
        }

        stage('Docker Build') {
            steps {
                echo 'Building Docker image...'
                sh "docker build -t ${DOCKER_HUB_REPO}:${BUILD_NUMBER} ."
                sh "docker tag  ${DOCKER_HUB_REPO}:${BUILD_NUMBER} ${DOCKER_HUB_REPO}:latest"
            }
        }

        stage('Docker Push') {
            steps {
                echo 'Pushing to DockerHub...'
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-credentials',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_TOKEN'
                )]) {
                    sh """
                        echo \$DOCKER_TOKEN | docker login -u \$DOCKER_USER --password-stdin
                        docker push ${DOCKER_HUB_REPO}:${BUILD_NUMBER}
                        docker push ${DOCKER_HUB_REPO}:latest
                    """
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                echo 'Deploying to Kubernetes...'
                sh """
                    kubectl set image deployment/spring-app-deployment \
                        spring-app=${DOCKER_HUB_REPO}:${BUILD_NUMBER} \
                        -n ${NAMESPACE}

                    kubectl rollout status deployment/spring-app-deployment \
                        -n ${NAMESPACE} --timeout=120s
                """
            }
        }

        stage('Verify Deployment') {
            steps {
                echo 'Verifying Kubernetes deployment...'
                sh """
                    echo '=== NODES ==='
                    kubectl get nodes

                    echo '=== PODS ==='
                    kubectl get pods -n ${NAMESPACE}

                    echo '=== SERVICES ==='
                    kubectl get svc -n ${NAMESPACE}

                    echo '=== LOGS ==='
                    kubectl logs -l app=spring-app -n ${NAMESPACE} --tail=20
                """
            }
        }

        stage('Test Application') {
            steps {
                echo 'Testing application endpoints...'
                sh """
                    pkill -f 'kubectl port-forward' || true
                    sleep 2
                    kubectl port-forward svc/spring-app-service 8089:8089 \
                        -n ${NAMESPACE} --address 0.0.0.0 &
                    sleep 5

                    echo '=== Test Students ==='
                    curl -s http://localhost:8089/student/students/getAllStudents

                    echo '=== Test Departments ==='
                    curl -s http://localhost:8089/student/department/getAllDepartment

                    echo '=== Test Enrollments ==='
                    curl -s http://localhost:8089/student/enrollment/getAllEnrollment
                """
            }
        }
    }

    post {
        success {
            echo '✅ Pipeline exécuté avec succès!'
            sh "kubectl get svc -n devops"
        }
        failure {
            echo '❌ Le pipeline a échoué.'
            sh """
                kubectl get pods -n devops || true
                kubectl logs -l app=spring-app -n devops --tail=30 || true
            """
        }
        always {
            sh "pkill -f 'kubectl port-forward' || true"
            cleanWs()
        }
    }
}
