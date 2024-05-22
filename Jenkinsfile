pipeline {
    agent none
    
    environment {
        GIT_REPO_URL = 'https://github.com/your-repo.git'
        GIT_BRANCH = 'main'
        MAVEN_HOME = tool name: 'Maven', type: 'hudson.tasks.Maven$MavenInstallation'
        JAVA_HOME = tool name: 'JDK11', type: 'hudson.model.JDK'
        DEV_SERVER = 'dev.example.com'
        PROD_SERVER = 'prod.example.com'
    }
    
    stages {
        stage('Checkout') {
            agent { label 'linux' }
            steps {
                script {
                    echo "Checking out from ${GIT_REPO_URL}, branch: ${GIT_BRANCH}"
                }
                git branch: "${GIT_BRANCH}", url: "${GIT_REPO_URL}"
            }
        }
        
        stage('Build') {
            agent { label 'maven' }
            environment {
                PATH = "${JAVA_HOME}/bin:${MAVEN_HOME}/bin:${env.PATH}"
            }
            steps {
                script {
                    echo "Building the project with Maven"
                }
                sh 'mvn clean install'
            }
        }
        
        stage('Test') {
            agent { label 'maven' }
            steps {
                script {
                    echo "Running tests"
                }
                sh 'mvn test'
            }
        }
        
        stage('Deploy to Dev') {
            agent { label 'deploy' }
            steps {
                script {
                    echo "Deploying to Development Server: ${DEV_SERVER}"
                }
                sh """
                ssh user@${DEV_SERVER} 'mkdir -p /path/to/deploy'
                scp target/your-app.jar user@${DEV_SERVER}:/path/to/deploy/
                ssh user@${DEV_SERVER} 'systemctl restart your-app-service'
                """
            }
        }
        
        stage('Approve Deployment to Prod') {
            agent none
            steps {
                input message: 'Approve deployment to Production?', ok: 'Deploy'
            }
        }
        
        stage('Deploy to Prod') {
            agent { label 'deploy' }
            steps {
                script {
                    echo "Deploying to Production Server: ${PROD_SERVER}"
                }
                sh """
                ssh user@${PROD_SERVER} 'mkdir -p /path/to/deploy'
                scp target/your-app.jar user@${PROD_SERVER}:/path/to/deploy/
                ssh user@${PROD_SERVER} 'systemctl restart your-app-service'
                """
            }
        }
    }
    
    post {
        always {
            script {
                echo "Cleaning up workspace"
            }
            cleanWs()
        }
        success {
            script {
                echo "Build, Test, and Deployment succeeded!"
            }
        }
        failure {
            script {
                echo "Build, Test, or Deployment failed."
            }
        }
    }
}
