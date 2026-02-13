#!/bin/bash

# AWS EC2 Setup Script for FullStack Application
# Run this script on a fresh Ubuntu 20.04/22.04 LTS instance

set -e

echo "=========================================="
echo "🚀 EC2 Instance Setup for FullStack App"
echo "=========================================="

# Update system packages
echo "📦 Updating system packages..."
sudo apt-get update
sudo apt-get upgrade -y

# Install required packages
echo "📦 Installing required packages..."
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    software-properties-common

# Install Docker
echo "🐳 Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
rm get-docker.sh

# Install Docker Compose
echo "🐳 Installing Docker Compose..."
DOCKER_COMPOSE_VERSION="2.20.0"
sudo curl -L "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify Docker installation
echo "✅ Verifying Docker installation..."
docker --version
docker-compose --version

# Install Java for Jenkins
echo "☕ Installing Java (OpenJDK 17)..."
sudo apt-get install -y openjdk-17-jdk

# Add Jenkins repository and install
echo "🔧 Installing Jenkins..."
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt-get update
sudo apt-get install -y jenkins

# Add Jenkins user to docker group
sudo usermod -aG docker jenkins

# Start Jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins

# Configure firewall
echo "🔥 Configuring UFW firewall..."
sudo ufw --force enable
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 5000/tcp  # Backend API
sudo ufw allow 8080/tcp  # Jenkins
sudo ufw status

# Create application directory
echo "📁 Creating application directory..."
sudo mkdir -p /var/www/fullstack-app
sudo chown -R $USER:$USER /var/www/fullstack-app

# Print Jenkins initial admin password
echo ""
echo "=========================================="
echo "✅ EC2 Setup Complete!"
echo "=========================================="
echo ""
echo "📋 Next Steps:"
echo "1. Get Jenkins initial admin password:"
echo "   sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
echo ""
echo "2. Access Jenkins at: http://YOUR_EC2_IP:8080"
echo ""
echo "3. Install suggested plugins and create admin user"
echo ""
echo "4. Install additional Jenkins plugins:"
echo "   - Docker Pipeline"
echo "   - Git plugin"
echo "   - GitHub plugin"
echo ""
echo "5. Clone your repository:"
echo "   cd /var/www/fullstack-app"
echo "   git clone YOUR_REPO_URL ."
echo ""
echo "6. Create Jenkins pipeline job pointing to Jenkinsfile"
echo ""
echo "7. Configure GitHub webhook:"
echo "   URL: http://YOUR_EC2_IP:8080/github-webhook/"
echo "   Content type: application/json"
echo "   Events: Just the push event"
echo ""
echo "=========================================="
echo ""
echo "⚠️  IMPORTANT: You may need to log out and back in for"
echo "   Docker group membership to take effect"
echo ""
echo "🔐 Jenkins Initial Admin Password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword || echo "Jenkins may still be starting..."
echo ""
