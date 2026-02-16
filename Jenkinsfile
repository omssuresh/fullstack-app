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
        EC2_IP = '43.205.254.103'  // Set once, use everywhere
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
                    # Create .env file with all variables
                    cat > .env << EOF
DB_NAME=${DB_NAME}
DB_USER=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}
JWT_SECRET=${JWT_SECRET}
NODE_ENV=${NODE_ENV}
MYSQL_ROOT_PASSWORD=${DB_PASSWORD}
MYSQL_DATABASE=${DB_NAME}
EC2_IP=${EC2_IP}
EOF
                    echo "✅ .env file created:"
                    cat .env
                '''
            }
        }
        
        stage('Clean Environment') {
            steps {
                echo '🧹 Cleaning up previous containers...'
                sh '''
                    docker-compose down -v
                    docker system prune -f
                '''
            }
        }
        
        stage('Build Backend') {
            steps {
                echo '🏗️ Building Backend image...'
                sh 'docker build -t devops-fullstack-backend ./backend'
            }
        }
        
        stage('Build Frontend') {
            steps {
                script {
                    // Build frontend with EC2 IP as build argument
                    sh """
                        cd frontend
                        docker build \\
                          --build-arg API_URL=http://${EC2_IP}:5000/api \\
                          -t devops-fullstack-frontend .
                    """
                }
            }
        }
        
        stage('Start Services') {
            steps {
                echo '🚀 Starting services...'
                sh '''
                    # Export EC2 IP for docker-compose
                    export EC2_IP=${EC2_IP}
                    
                    # Start all services
                    docker-compose up -d
                    
                    echo "Waiting for MySQL to be healthy..."
                    timeout=60
                    elapsed=0
                    while [ $elapsed -lt $timeout ]; do
                        if docker inspect fullstack-mysql --format='{{.State.Health.Status}}' 2>/dev/null | grep -q "healthy"; then
                            echo "✅ MySQL is healthy"
                            break
                        fi
                        echo "⏳ Waiting for MySQL... ($elapsed/$timeout seconds)"
                        sleep 5
                        elapsed=$((elapsed + 5))
                    done
                    
                    echo "Waiting for backend to be ready..."
                    timeout=90
                    elapsed=0
                    while [ $elapsed -lt $timeout ]; do
                        if curl -s http://localhost:5000/health > /dev/null 2>&1; then
                            echo "✅ Backend is ready"
                            break
                        fi
                        echo "⏳ Waiting for backend... ($elapsed/$timeout seconds)"
                        sleep 5
                        elapsed=$((elapsed + 5))
                    done
                    
                    echo "Waiting for frontend..."
                    sleep 10
                    
                    echo "✅ All services started:"
                    docker-compose ps
                '''
            }
        }
        
        stage('Verify Deployments') {
            steps {
                echo '🔍 Verifying services are accessible...'
                sh '''
                    echo "Testing backend health endpoint..."
                    curl -s http://localhost:5000/health | jq . || echo "Backend not responding"
                    
                    echo "Testing frontend..."
                    curl -s -I http://localhost:80 | head -n 1 || echo "Frontend not responding"
                    
                    echo "Testing from public IP..."
                    curl -s -I http://${EC2_IP}:80 | head -n 1 || echo "Public access not ready"
                '''
            }
        }
        
        stage('Run Tests') {
            steps {
                echo '🧪 Running integration tests...'
                sh '''
                    if [ -f ./tests/integration-tests.sh ]; then
                        chmod +x ./tests/integration-tests.sh
                        ./tests/integration-tests.sh
                    else
                        echo "⚠️ Test script not found, skipping..."
                    fi
                '''
            }
        }
        
        stage('Deployment Info') {
            steps {
                echo '🚀 Deployment Complete!'
                sh '''
                    echo "=========================================="
                    echo "✅ DEPLOYMENT SUCCESSFUL"
                    echo "=========================================="
                    echo "🌐 Public URLs:"
                    echo "   Frontend: http://${EC2_IP}"
                    echo "   Backend API: http://${EC2_IP}:5000"
                    echo "   Health Check: http://${EC2_IP}:5000/health"
                    echo ""
                    echo "📡 Local URLs:"
                    echo "   Frontend: http://localhost:80"
                    echo "   Backend: http://localhost:5000"
                    echo "=========================================="
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
                echo "=== Container Status ==="
                docker-compose ps
                
                echo "=== Backend Logs ==="
                docker-compose logs --tail=30 backend
                
                echo "=== Frontend Logs ==="
                docker-compose logs --tail=20 frontend
                
                echo "=== MySQL Logs ==="
                docker-compose logs --tail=20 mysql
            '''
        }
        
        always {
            script {
                sh '''
                    mkdir -p logs
                    docker-compose logs > logs/build-${BUILD_NUMBER}.log 2>&1 || true
                '''
                archiveArtifacts artifacts: 'logs/*.log', allowEmptyArchive: true
            }
        }
    }
}
