pipeline {
    agent {
        label 'built-in'
    }
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timestamps()
        timeout(time: 30, unit: 'MINUTES')
    }
    
    environment {
        DB_NAME = 'fullstack_db'
        DB_USER = 'root'
        DB_PASSWORD = 'SecureRootPassword123!'
        JWT_SECRET = 'jenkins-deployment-secret-key-minimum-32-characters-required-for-security'
        NODE_ENV = 'production'
        EC2_IP = '43.205.254.103'
        IMAGE_TAG = "${BUILD_NUMBER}"
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
EC2_IP=${EC2_IP}
EOF
                    echo "✅ .env file created"
                '''
            }
        }
        
        stage('Clean Environment') {
            steps {
                echo '🧹 Cleaning up previous containers...'
                sh '''
                    docker-compose down -v || true
                    docker system prune -f || true
                '''
            }
        }
        
        stage('Build Backend') {
            steps {
                echo '🏗️ Building Backend image...'
                sh """
                    docker build -t devops-fullstack-backend:${IMAGE_TAG} ./backend
                    docker tag devops-fullstack-backend:${IMAGE_TAG} devops-fullstack-backend:latest
                """
            }
        }
        
        stage('Build Frontend') {
            steps {
                script {
                    sh """
                        cd frontend
                        docker build \\
                          --build-arg API_URL=http://${EC2_IP}:5000/api \\
                          -t devops-fullstack-frontend:${IMAGE_TAG} .
                        docker tag devops-fullstack-frontend:${IMAGE_TAG} devops-fullstack-frontend:latest
                    """
                }
            }
        }
        
        stage('Start Services') {
            steps {
                echo '🚀 Starting services...'
                sh '''
                    export EC2_IP=${EC2_IP}
                    
                    echo "=========================================="
                    echo "Starting all services..."
                    echo "=========================================="
                    
                    docker-compose up -d
                    
                    # Function to check health
                    check_health() {
                        local container=$1
                        local timeout=$2
                        local elapsed=0
                        
                        echo "Waiting for $container to be healthy..."
                        while [ $elapsed -lt $timeout ]; do
                            STATUS=$(docker inspect $container --format='{{.State.Health.Status}}' 2>/dev/null || echo "starting")
                            if [ "$STATUS" = "healthy" ]; then
                                echo "✅ $container is healthy after ${elapsed}s"
                                return 0
                            fi
                            echo "⏳ $container status: $STATUS (${elapsed}s/${timeout}s)"
                            sleep 5
                            elapsed=$((elapsed + 5))
                        done
                        
                        echo "❌ $container failed to become healthy"
                        return 1
                    }
                    
                    check_health "fullstack-mysql" 60 || exit 1
                    check_health "fullstack-backend" 120 || exit 1
                    check_health "fullstack-frontend" 60 || exit 1
                    
                    echo ""
                    echo "✅ ALL SERVICES ARE HEALTHY!"
                    docker-compose ps
                '''
            }
        }
        
        stage('Verify Deployments') {
            steps {
                echo '🔍 Verifying services...'
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
                    echo "✅ DEPLOYMENT SUCCESSFUL - Build #${BUILD_NUMBER}"
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
                docker-compose logs --tail=50 backend
                
                echo "=== Frontend Logs ==="
                docker-compose logs --tail=30 frontend
                
                echo "=== MySQL Logs ==="
                docker-compose logs --tail=30 mysql
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
            cleanWs()  // Clean workspace after build
        }
    }
}
