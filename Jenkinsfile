pipeline {
    agent any
    
    environment {
        DOCKER_COMPOSE_VERSION = '2.20.0'
        PROJECT_NAME = 'fullstack-app'
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
                    // Copy environment variables if not exists
                    sh '''
                        if [ ! -f .env ]; then
                            echo "Creating .env file..."
                            cat > .env << EOF
DB_NAME=fullstack_db
DB_USER=root
DB_PASSWORD=SecureRootPassword123!
JWT_SECRET=jenkins-deployment-secret-key-minimum-32-characters-required-for-security
NODE_ENV=production
EOF
                        fi
                    '''
                }
            }
        }
        
        stage('Build') {
            steps {
                script {
                    echo '🏗️ Building Docker images...'
                    sh '''
                        docker-compose down -v || true
                        docker-compose build --no-cache
                    '''
                }
            }
        }
        
        stage('Test') {
            steps {
                script {
                    echo '🧪 Running integration tests...'
                    
                    // Start services
                    sh 'docker-compose up -d'
                    
                    // Wait for services to be healthy
                    echo 'Waiting for services to be healthy...'
                    sh '''
                        timeout=120
                        elapsed=0
                        interval=5
                        
                        while [ $elapsed -lt $timeout ]; do
                            if docker-compose ps | grep -q "healthy"; then
                                echo "✅ Services are healthy"
                                break
                            fi
                            echo "Waiting for services... ($elapsed/$timeout seconds)"
                            sleep $interval
                            elapsed=$((elapsed + interval))
                        done
                        
                        if [ $elapsed -ge $timeout ]; then
                            echo "❌ Timeout waiting for services to be healthy"
                            docker-compose ps
                            docker-compose logs
                            exit 1
                        fi
                    '''
                    
                    // Run integration tests
                    sh '''
                        chmod +x ./tests/integration-tests.sh
                        ./tests/integration-tests.sh
                    '''
                }
            }
        }
        
        stage('Deploy') {
            steps {
                script {
                    echo '🚀 Deploying application...'
                    sh '''
                        # Application is already running from test stage
                        # Just verify all services are up
                        docker-compose ps
                        
                        echo "✅ Application deployed successfully!"
                        echo "Frontend: http://localhost:80"
                        echo "Backend API: http://localhost:5000"
                        echo "Database: localhost:3306"
                    '''
                }
            }
        }
    }
    
    post {
        success {
            script {
                echo '✅ Pipeline completed successfully!'
                // You can add notification here (email, Slack, etc.)
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
                '''
                // You can add notification here (email, Slack, etc.)
            }
        }
        
        always {
            script {
                echo '🧹 Cleaning up...'
                // Archive logs
                sh '''
                    mkdir -p logs
                    docker-compose logs > logs/docker-compose-${BUILD_NUMBER}.log 2>&1 || true
                '''
                archiveArtifacts artifacts: 'logs/*.log', allowEmptyArchive: true
            }
        }
    }
}
