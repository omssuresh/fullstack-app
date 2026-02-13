# AWS EC2 Deployment Guide

## 📋 Prerequisites

- AWS Account
- SSH key pair for EC2 access
- Basic knowledge of AWS services

## 🚀 Step-by-Step Deployment

### Step 1: Launch EC2 Instance

1. **Login to AWS Console**
   - Navigate to EC2 Dashboard
   - Click "Launch Instance"

2. **Configure Instance**
   ```
   Name: fullstack-app-server
   AMI: Ubuntu Server 22.04 LTS (HVM), SSD Volume Type
   Instance Type: t2.medium (2 vCPU, 4 GB RAM)
   Key Pair: Select or create new
   ```

3. **Network Settings**
   - Create new security group: `fullstack-app-sg`
   - Add inbound rules:
     - SSH (22) - Your IP
     - HTTP (80) - 0.0.0.0/0
     - HTTPS (443) - 0.0.0.0/0
     - Custom TCP (5000) - 0.0.0.0/0 [Backend API]
     - Custom TCP (8080) - Your IP [Jenkins]
     - Custom TCP (3306) - Your IP [MySQL - optional]

4. **Configure Storage**
   - Root Volume: 20 GB gp3

5. **Launch Instance**

### Step 2: Connect to Instance

```bash
# Download your key pair (if new)
chmod 400 your-key.pem

# Connect via SSH
ssh -i your-key.pem ubuntu@YOUR_EC2_PUBLIC_IP
```

### Step 3: Run Setup Script

```bash
# Update system
sudo apt-get update

# Download setup script
wget https://raw.githubusercontent.com/YOUR_USERNAME/YOUR_REPO/main/deployment/ec2-setup.sh

# Make executable
chmod +x ec2-setup.sh

# Run setup (takes 5-10 minutes)
./ec2-setup.sh

# Note: You'll need to logout and login again for Docker permissions
exit
ssh -i your-key.pem ubuntu@YOUR_EC2_PUBLIC_IP
```

### Step 4: Setup Application

```bash
# Clone your repository
cd /var/www
sudo mkdir fullstack-app
sudo chown ubuntu:ubuntu fullstack-app
cd fullstack-app
git clone YOUR_GITHUB_REPO_URL .

# Configure environment
cp .env.example .env
nano .env
# Update with production values:
# - Strong DB_PASSWORD
# - Strong JWT_SECRET (min 32 characters)
# - Correct FRONTEND_URL (your EC2 IP or domain)
```

### Step 5: Start Application

```bash
# Build and start services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f
```

### Step 6: Configure Jenkins

1. **Get Initial Admin Password**
   ```bash
   sudo cat /var/lib/jenkins/secrets/initialAdminPassword
   ```

2. **Access Jenkins**
   - Navigate to `http://YOUR_EC2_IP:8080`
   - Enter initial admin password
   - Install suggested plugins

3. **Install Additional Plugins**
   - Manage Jenkins → Plugins → Available
   - Install:
     - Docker Pipeline
     - GitHub Integration

4. **Create New Pipeline Job**
   - Click "New Item"
   - Name: "fullstack-app-pipeline"
   - Type: Pipeline
   - Click OK

5. **Configure Pipeline**
   - Pipeline Definition: Pipeline script from SCM
   - SCM: Git
   - Repository URL: YOUR_GITHUB_REPO_URL
   - Credentials: Add GitHub credentials if private
   - Branch: */main
   - Script Path: Jenkinsfile
   - Save

### Step 7: Configure GitHub Webhook

1. **Go to GitHub Repository Settings**
   - Settings → Webhooks → Add webhook

2. **Configure Webhook**
   ```
   Payload URL: http://YOUR_EC2_IP:8080/github-webhook/
   Content type: application/json
   Secret: (leave empty or configure in Jenkins)
   Events: Just the push event
   Active: ✓
   ```

3. **Test Webhook**
   - Push a commit to repository
   - Jenkins should automatically trigger build

### Step 8: Configure Domain (Optional)

If you have a domain name:

1. **Point Domain to EC2**
   - Create A record: yourdomain.com → EC2_PUBLIC_IP
   - Create A record: api.yourdomain.com → EC2_PUBLIC_IP

2. **Install SSL Certificate**
   ```bash
   # Install certbot
   sudo apt-get install certbot python3-certbot-nginx

   # Get certificate
   sudo certbot --nginx -d yourdomain.com -d www.yourdomain.com
   ```

3. **Update Configuration**
   - Update `.env` FRONTEND_URL
   - Update nginx configuration for SSL

## 🔧 Post-Deployment Configuration

### Setup Database Backups

```bash
# Create backup script
cat > /var/www/fullstack-app/backup-db.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/var/www/fullstack-app/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

docker-compose exec -T mysql mysqldump \
  -u root -p$DB_PASSWORD fullstack_db \
  > $BACKUP_DIR/backup_$TIMESTAMP.sql

# Keep only last 7 days
find $BACKUP_DIR -name "backup_*.sql" -mtime +7 -delete
EOF

chmod +x /var/www/fullstack-app/backup-db.sh

# Add to crontab for daily backup at 2 AM
crontab -e
# Add this line:
# 0 2 * * * /var/www/fullstack-app/backup-db.sh
```

### Setup Monitoring

```bash
# Install monitoring tools
sudo apt-get install -y htop iotop nethogs

# Monitor Docker containers
docker stats

# Monitor logs
docker-compose logs -f --tail=100
```

### Setup Log Rotation

```bash
# Configure Docker log rotation
sudo nano /etc/docker/daemon.json
```

Add:
```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
```

```bash
# Restart Docker
sudo systemctl restart docker
```

## 🔐 Security Hardening

### 1. Change Default Passwords

```bash
# Change admin password in application
# Login as admin → Change password in UI
```

### 2. Configure Firewall Rules

```bash
# Review UFW rules
sudo ufw status verbose

# Remove any unnecessary open ports
```

### 3. Setup Fail2Ban

```bash
# Install fail2ban
sudo apt-get install fail2ban

# Configure
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo nano /etc/fail2ban/jail.local

# Enable and start
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

### 4. Regular Updates

```bash
# Create update script
cat > /var/www/fullstack-app/update-system.sh << 'EOF'
#!/bin/bash
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get autoremove -y
EOF

chmod +x /var/www/fullstack-app/update-system.sh

# Schedule weekly updates
# Add to crontab: 0 3 * * 0 /var/www/fullstack-app/update-system.sh
```

## 📊 Monitoring & Maintenance

### Check Application Health

```bash
# Check all services
docker-compose ps

# Check application health
curl http://localhost/health
curl http://localhost:5000/health

# Check resource usage
docker stats
```

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend

# Last 100 lines
docker-compose logs --tail=100 backend
```

### Restart Services

```bash
# Restart specific service
docker-compose restart backend

# Restart all services
docker-compose restart

# Full restart with rebuild
docker-compose down
docker-compose up -d --build
```

## 🚨 Troubleshooting

### Service Won't Start

```bash
# Check logs
docker-compose logs SERVICE_NAME

# Check if port is in use
sudo lsof -i :PORT

# Restart Docker
sudo systemctl restart docker
docker-compose up -d
```

### High Memory Usage

```bash
# Check usage
free -h
docker stats

# Clean up Docker
docker system prune -a
```

### Database Connection Issues

```bash
# Check MySQL is running
docker-compose ps mysql

# Check MySQL logs
docker-compose logs mysql

# Restart MySQL
docker-compose restart mysql
```

## 📈 Scaling Considerations

For production with high traffic:

1. **Use RDS for Database**
   - Migrate from container MySQL to AWS RDS
   - Better reliability and automatic backups

2. **Use Application Load Balancer**
   - Distribute traffic across multiple instances
   - SSL termination at load balancer

3. **Use Auto Scaling**
   - Configure auto-scaling group
   - Scale based on CPU/Memory metrics

4. **Use ECS/EKS**
   - Container orchestration at scale
   - Better for microservices architecture

5. **Use CloudFront**
   - CDN for frontend assets
   - Improved global performance

## 💰 Cost Optimization

- Use t2.micro for testing (free tier eligible)
- Use t2.medium for production (recommended)
- Enable Auto Scaling to scale down during low traffic
- Use Reserved Instances for long-term deployments
- Setup CloudWatch alerts for cost monitoring

## ✅ Deployment Checklist

- [ ] EC2 instance launched
- [ ] Security group configured
- [ ] SSH access working
- [ ] Docker and Docker Compose installed
- [ ] Jenkins installed and configured
- [ ] Application cloned from GitHub
- [ ] Environment variables configured
- [ ] Application running successfully
- [ ] Jenkins pipeline configured
- [ ] GitHub webhook configured
- [ ] SSL certificate installed (if using domain)
- [ ] Database backups configured
- [ ] Monitoring setup
- [ ] Security hardening complete
- [ ] Default passwords changed
- [ ] Application tested and verified

## 🎉 Deployment Complete!

Your application is now live on AWS EC2!

Access points:
- Application: http://YOUR_EC2_IP or https://yourdomain.com
- Jenkins: http://YOUR_EC2_IP:8080
- API: http://YOUR_EC2_IP:5000

Remember to:
- Monitor logs regularly
- Keep system updated
- Backup database regularly
- Review security settings periodically
