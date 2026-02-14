pipeline {
    agent any
    
    environment {
        DB_NAME = 'fullstack_db'
        DB_USER = 'root'
        // Use Jenkins credentials instead of hardcoded values
        DB_PASSWORD = credentials('mysql-root-password')
        JWT_SECRET = credentials('jwt-secret-key')
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
                        set -e
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
                        echo "✅ .env file created (secrets hidden)"
                        # Don't print .env contents for security
                    '''
                }
            }
        }
        
        stage('Clean Environment') {
            steps {
                script {
                    echo '🧹 Cleaning up previous containers...'
                    sh '''
                        set -e
                        # Stop containers but KEEP volumes (preserve data)
                        docker-compose down || true
                        
                        # Clean up unused images
                        docker image prune -f || true
                    '''
                }
            }
        }
        
        stage('Build') {
            steps {
                script {
                    echo '🏗️ Building Docker images...'
                    sh '''
                        set -e
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
                        set -e
                        docker-compose up -d
                        
                        echo "=========================================="
                        echo "Waiting for all services to be healthy..."
                        echo "This may take 2-3 minutes for first run"
                        echo "=========================================="
                        
                        # Function to check container health
                        check_health() {
                            local service=$1
                            local container=$(docker-compose ps -q $service)
                            if [ -z "$container" ]; then
                                echo "not_running"
                                return
                            fi
                            local status=$(docker inspect $container --format='{{.State.Health.Status}}' 2>/dev/null || echo "starting")
                            echo $status
                        }
                        
                        # Wait for MySQL first
                        echo "Waiting for MySQL to be healthy..."
                        timeout=60
                        elapsed=0
                        while [ $elapsed -lt $timeout ]; do
                            STATUS=$(check_health "mysql")
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
                        
                        # Now wait for backend
                        echo "Waiting for Backend to be healthy..."
                        timeout=180
                        elapsed=0
                        while [ $elapsed -lt $timeout ]; do
                            STATUS=$(check_health "backend")
                            if [ "$STATUS" = "healthy" ]; then
                                echo "✅ Backend is healthy after ${elapsed}s"
                                break
                            fi
                            
                            # Show progress every 15 seconds
                            if [ $((elapsed % 15)) -eq 0 ]; then
                                echo "⏳ Backend status: $STATUS (${elapsed}s/${timeout}s)"
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
                        set -e
                        
                        # Check if test script exists
                        if [ ! -f ./tests/integration-tests.sh ]; then
                            echo "⚠️ Integration test script not found, skipping tests..."
                            exit 0
                        fi
                        
                        # Make test script executable
                        chmod +x ./tests/integration-tests.sh
                        
                        # Run tests
                        if ./tests/integration-tests.sh; then
                            echo "✅ All tests passed!"
                        else
                            TEST_EXIT_CODE=$?
                            echo "❌ Tests failed with exit code: $TEST_EXIT_CODE"
                            echo "=== CONTAINER STATUS ==="
                            docker-compose ps
                            echo "=== BACKEND LOGS ==="
                            docker-compose logs --tail=30 backend
                            echo "=== DATABASE LOGS ==="
                            docker-compose logs --tail=30 mysql
                            exit $TEST_EXIT_CODE
                        fi
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
                        echo "Frontend: http://$(hostname -I | awk '{print $1}'):80"
                        echo "Backend API: http://$(hostname -I | awk '{print $1}'):5000"
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
                sh '''
                    echo "=== FINAL STATUS ==="
                    docker-compose ps
                '''
            }
        }
        
        failure {
            script {
                echo '❌ Pipeline failed!'
                sh '''
                    echo "=== CONTAINER STATUS ==="
                    docker-compose ps || true
                    
                    echo "=== BACKEND LOGS ==="
                    docker-compose logs --tail=50 backend || true
                    
                    echo "=== DATABASE LOGS ==="
                    docker-compose logs --tail=50 mysql || true
                    
                    echo "=== FRONTEND LOGS ==="
                    docker-compose logs --tail=50 frontend || true
                    
                    echo "=== DISK SPACE ==="
                    df -h
                    
                    echo "=== MEMORY ==="
                    free -h
                    
                    echo "=== DOCKER SYSTEM INFO ==="
                    docker system df
                '''
                
                // Clean up failed deployment
                sh 'docker-compose down || true'
            }
        }
        
        always {
            script {
                echo '🧹 Archiving logs...'
                sh '''
                    mkdir -p logs
                    docker-compose logs > logs/docker-compose-${BUILD_NUMBER:-unknown}.log 2>&1 || true
                '''
                archiveArtifacts artifacts: 'logs/*.log', allowEmptyArchive: true
            }
        }
    }
}