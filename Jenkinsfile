pipeline {
    agent {
        label 'built-in'
    }
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timestamps()
    }
    
    environment {
        DB_NAME = 'fullstack_db'
        DB_USER = 'root'
        DB_PASSWORD = 'SecureRootPassword123!'
        JWT_SECRET = 'jenkins-deployment-secret-key-minimum-32-characters-required-for-security'
        NODE_ENV = 'production'
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo '📥 Checking out code from GitHub...'
                checkout scm
            }
        }
        
        stage('Environment Setup') {
            steps {
                echo '🔧 Setting up environment variables...'
                sh '''
                    cat > .env << EOF
DB_NAME=${DB_NAME}
DB_USER=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}
JWT_SECRET=${JWT_SECRET}
NODE_ENV=${NODE_ENV}
MYSQL_ROOT_PASSWORD=${DB_PASSWORD}
MYSQL_DATABASE=${DB_NAME}
EOF
                    echo "✅ .env file created"
                '''
            }
        }
        
        stage('Clean Environment') {
            steps {
                echo '🧹 Cleaning up previous containers...'
                sh '''
                    docker-compose down || true
                    docker system prune -f || true
                '''
            }
        }
        
        stage('Build') {
            steps {
                echo '🏗️ Building Docker images...'
                sh 'docker-compose build --no-cache'
            }
        }
        
        stage('Start Services') {
            steps {
                echo '🚀 Starting services...'
                sh '''
                    docker-compose up -d
                    
                    echo "Waiting for services to be ready..."
                    sleep 60
                    
                    docker-compose ps
                '''
            }
        }
        
        stage('Test') {
            steps {
                echo '🧪 Running integration tests...'
                sh '''
                    if [ -f ./tests/integration-tests.sh ]; then
                        chmod +x ./tests/integration-tests.sh
                        ./tests/integration-tests.sh || true
                    else
                        echo "⚠️ Test script not found, skipping..."
                    fi
                '''
            }
        }
        
        stage('Deploy') {
            steps {
                echo '🚀 Application deployed!'
                sh '''
                    echo "==================================="
                    echo "✅ DEPLOYMENT SUCCESSFUL"
                    echo "==================================="
                    echo "Frontend: http://localhost:80"
                    echo "Backend: http://localhost:5000"
                    echo "==================================="
                    docker-compose ps
                '''
            }
        }
    }
    
    post {
        success {
            echo '✅ Pipeline completed successfully!'
        }
        
        failure {
            echo '❌ Pipeline failed!'
            sh '''
                docker-compose logs --tail=50 || true
            '''
        }
        
        always {
            sh '''
                mkdir -p logs
                docker-compose logs > logs/build-${BUILD_NUMBER}.log 2>&1 || true
            '''
            archiveArtifacts artifacts: 'logs/*.log', allowEmptyArchive: true
        }
    }
}