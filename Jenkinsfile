pipeline {
    agent any
    
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
                script {
                    echo '📥 Checking out code from GitHub...'
                    checkout scm
                }
            }
        }
        
        stage('Environment Setup') {
            steps {
                script {
                    echo '🔧 Setting up environment variables...'
                    sh '''
                        # Create .env file if it doesn't exist
                        if [ ! -f .env ]; then
                            echo "Creating .env file..."
                            cat > .env << EOF
DB_NAME=${DB_NAME}
DB_USER=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}
JWT_SECRET=${JWT_SECRET}
NODE_ENV=${NODE_ENV}
MYSQL_ROOT_PASSWORD=${DB_PASSWORD}
MYSQL_DATABASE=${DB_NAME}
EOF
                        fi
                        
                        echo "✅ Environment setup complete"
                        echo "Current .env file:"
                        cat .env
                    '''
                }
            }
        }
        
        stage('Clean Environment') {
            steps {
                script {
                    echo '🧹 Cleaning up previous containers...'
                    sh '''
                        docker-compose down -v || true
                        docker system prune -f || true
                    '''
                }
            }
        }
        
        stage('Build') {
            steps {
                script {
                    echo '🏗️ Building Docker images...'
                    sh '''
                        docker-compose build --no-cache
                    '''
                }
            }
        }
        
        stage('Start Services') {
            steps {
                script {
                    echo '🚀 Starting services...'
                    sh '''
                        docker-compose up -d
                        
                        echo "Waiting for services to be healthy..."
                        timeout=120
                        elapsed=0
                        interval=5
                        
                        while [ $elapsed -lt $timeout ]; do
                            if docker-compose ps | grep -q "healthy"; then
                                echo "✅ Services are healthy"
                                docker-compose ps
                                break
                            fi
                            echo "⏳ Waiting for services... ($elapsed/$timeout seconds)"
                            docker-compose ps
                            sleep $interval
                            elapsed=$((elapsed + interval))
                        done
                        
                        if [ $elapsed -ge $timeout ]; then
                            echo "❌ Timeout waiting for services"
                            docker-compose logs
                            exit 1
                        fi
                    '''
                }
            }
        }
        
        stage('Test') {
            steps {
                script {
                    echo '🧪 Running integration tests...'
                    
                    sh '''
                        # Fix line endings (in case of Windows development)
                        if command -v dos2unix > /dev/null; then
                            dos2unix ./tests/integration-tests.sh 2>/dev/null || true
                        else
                            sed -i 's/\r$//' ./tests/integration-tests.sh 2>/dev/null || true
                        fi
                        
                        # Make script executable
                        chmod +x ./tests/integration-tests.sh
                        
                        # Run tests with explicit bash
                        bash ./tests/integration-tests.sh
                        
                        # Capture exit code
                        TEST_EXIT_CODE=$?
                        echo "Test script exited with code: $TEST_EXIT_CODE"
                        
                        if [ $TEST_EXIT_CODE -ne 0 ]; then
                            echo "❌ Tests failed! Capturing debug info..."
                            echo "=== CONTAINER STATUS ==="
                            docker-compose ps
                            echo "=== CONTAINER LOGS ==="
                            docker-compose logs --tail=50
                            exit $TEST_EXIT_CODE
                        fi
                        
                        echo "✅ All tests passed!"
                    '''
                }
            }
        }
        
        stage('Deploy') {
            steps {
                script {
                    echo '🚀 Deploying application...'
                    sh '''
                        docker-compose ps
                        
                        echo "==================================="
                        echo "✅ APPLICATION DEPLOYED SUCCESSFULLY!"
                        echo "==================================="
                        echo "Frontend: http://localhost:80"
                        echo "Backend API: http://localhost:5000"
                        echo "Database: localhost:3306"
                        echo "==================================="
                    '''
                }
            }
        }
    }
    
    post {
        success {
            script {
                echo '✅ Pipeline completed successfully!'
                sh '''
                    echo "==================================="
                    echo "BUILD SUCCESSFUL"
                    echo "==================================="
                    echo "Application URLs:"
                    echo "  Frontend: http://localhost:80"
                    echo "  Backend:  http://localhost:5000"
                    echo "  Database: localhost:3306"
                    echo "==================================="
                    echo "Default Admin Credentials:"
                    echo "  Email: admin@example.com"
                    echo "  Password: Admin@123"
                    echo "==================================="
                '''
            }
        }
        
        failure {
            script {
                echo '❌ Pipeline failed!'
                sh '''
                    echo "==================================="
                    echo "BUILD FAILED"
                    echo "==================================="
                    echo "Checking logs..."
                    docker-compose logs --tail=50
                    
                    echo "=== CONTAINER STATUS ==="
                    docker-compose ps
                    
                    echo "=== DISK SPACE ==="
                    df -h
                    
                    echo "=== MEMORY ==="
                    free -h
                '''
            }
        }
        
        always {
            script {
                echo '🧹 Archiving logs...'
                sh '''
                    mkdir -p logs
                    docker-compose logs > logs/docker-compose-${BUILD_NUMBER}.log 2>&1 || true
                    cp ./tests/integration-tests.sh logs/test-script-${BUILD_NUMBER}.sh 2>/dev/null || true
                '''
                archiveArtifacts artifacts: 'logs/*.log, logs/*.sh', allowEmptyArchive: true
            }
        }
    }
}