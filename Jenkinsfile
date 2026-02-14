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
                        # Create .env file
                        cat > .env << EOF
DB_NAME=${DB_NAME}
DB_USER=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}
JWT_SECRET=${JWT_SECRET}
NODE_ENV=${NODE_ENV}
MYSQL_ROOT_PASSWORD=${DB_PASSWORD}
MYSQL_DATABASE=${DB_NAME}
EOF
                        echo "✅ .env file created:"
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
                        docker-compose down -v
                        docker system prune -f || true
                    '''
                }
            }
        }
        
        stage('Build') {
            steps {
                script {
                    echo '🏗️ Building Docker images...'
                    sh 'docker-compose build --no-cache'
                }
            }
        }
        
        stage('Start Services') {
            steps {
                script {
                    echo '🚀 Starting services...'
                    sh '''
                        docker-compose up -d
                        
                        echo "=========================================="
                        echo "Waiting for all services to be healthy..."
                        echo "This may take 2-3 minutes for first run"
                        echo "=========================================="
                        
                        # Function to check container health
                        check_health() {
                            local container=$1
                            local status=$(docker inspect $container --format='{{.State.Health.Status}}' 2>/dev/null || echo "starting")
                            echo $status
                        }
                        
                        # Wait for MySQL first
                        echo "Waiting for MySQL to be healthy..."
                        timeout=60
                        elapsed=0
                        while [ $elapsed -lt $timeout ]; do
                            STATUS=$(check_health "fullstack-mysql")
                            if [ "$STATUS" = "healthy" ]; then
                                echo "✅ MySQL is healthy after ${elapsed}s"
                                break
                            fi
                            echo "⏳ MySQL status: $STATUS (${elapsed}s/${timeout}s)"
                            sleep 5
                            elapsed=$((elapsed + 5))
                        done
                        
                        if [ $elapsed -ge $timeout ]; then
                            echo "❌ MySQL failed to become healthy"
                            docker-compose logs mysql
                            exit 1
                        fi
                        
                        # Now wait for backend (this will take longer due to DB connection retries)
                        echo "Waiting for Backend to be healthy..."
                        timeout=180
                        elapsed=0
                        while [ $elapsed -lt $timeout ]; do
                            STATUS=$(check_health "fullstack-backend")
                            if [ "$STATUS" = "healthy" ]; then
                                echo "✅ Backend is healthy after ${elapsed}s"
                                break
                            fi
                            
                            # Show progress every 15 seconds
                            if [ $((elapsed % 15)) -eq 0 ]; then
                                echo "⏳ Backend status: $STATUS (${elapsed}s/${timeout}s)"
                                echo "Recent backend logs:"
                                docker logs --tail=3 fullstack-backend 2>/dev/null || true
                                echo "---"
                            fi
                            
                            sleep 5
                            elapsed=$((elapsed + 5))
                        done
                        
                        if [ $elapsed -ge $timeout ]; then
                            echo "❌ Backend failed to become healthy"
                            docker-compose logs --tail=50 backend
                            exit 1
                        fi
                        
                        # Frontend will start automatically once backend is healthy
                        echo "Waiting for Frontend to start..."
                        sleep 10
                        
                        echo "✅ All services are ready!"
                        docker-compose ps
                    '''
                }
            }
        }
        
        stage('Test') {
            steps {
                script {
                    echo '🧪 Running integration tests...'
                    sh '''
                        # Make test script executable
                        chmod +x ./tests/integration-tests.sh
                        
                        # Run tests
                        ./tests/integration-tests.sh
                        
                        # Capture exit code
                        TEST_EXIT_CODE=$?
                        
                        if [ $TEST_EXIT_CODE -ne 0 ]; then
                            echo "❌ Tests failed!"
                            echo "=== CONTAINER STATUS ==="
                            docker-compose ps
                            echo "=== BACKEND LOGS ==="
                            docker-compose logs --tail=30 backend
                            echo "=== DATABASE LOGS ==="
                            docker-compose logs --tail=30 mysql
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
                        echo "==================================="
                        echo "✅ APPLICATION DEPLOYED SUCCESSFULLY!"
                        echo "==================================="
                        echo "Frontend: http://localhost:80"
                        echo "Backend API: http://localhost:5000"
                        echo "Database: localhost:3306"
                        echo "==================================="
                        docker-compose ps
                    '''
                }
            }
        }
    }
    
    post {
        success {
            script {
                echo '✅ Pipeline completed successfully!'
            }
        }
        
        failure {
            script {
                echo '❌ Pipeline failed!'
                sh '''
                    echo "=== CONTAINER STATUS ==="
                    docker-compose ps
                    
                    echo "=== BACKEND LOGS ==="
                    docker-compose logs --tail=30 backend
                    
                    echo "=== DATABASE LOGS ==="
                    docker-compose logs --tail=30 mysql
                    
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
                '''
                archiveArtifacts artifacts: 'logs/*.log', allowEmptyArchive: true
            }
        }
    }
}