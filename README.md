# FullStack Web Application

A complete two-tier web application with Angular frontend, Node.js/Express backend, MySQL database, Docker containerization, and Jenkins CI/CD pipeline.

## 📋 Table of Contents

- [Architecture Overview](#architecture-overview)
- [Features](#features)
- [Technology Stack](#technology-stack)
- [Prerequisites](#prerequisites)
- [Local Development Setup](#local-development-setup)
- [AWS EC2 Deployment](#aws-ec2-deployment)
- [Jenkins CI/CD Setup](#jenkins-cicd-setup)
- [API Documentation](#api-documentation)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting) yes

## 🏗️ Architecture Overview


## ✨ Features

### Frontend (Angular)
- ✅ User registration with validation
- ✅ User login with JWT authentication
- ✅ Role-based access control (Admin/User)
- ✅ Protected routes with guards
- ✅ HTTP interceptor for automatic token attachment
- ✅ Responsive design with Bootstrap
- ✅ Admin dashboard for user management
- ✅ User dashboard with personalized content

### Backend (Node.js/Express)
- ✅ RESTful API architecture
- ✅ JWT token-based authentication
- ✅ Password encryption with bcrypt
- ✅ Input validation and sanitization
- ✅ Role-based middleware
- ✅ MySQL database integration
- ✅ Error handling middleware
- ✅ CORS configuration
- ✅ Security headers with Helmet

### DevOps
- ✅ Docker containerization
- ✅ Multi-stage Docker builds
- ✅ Docker Compose orchestration
- ✅ Health checks for all services
- ✅ Persistent data volumes
- ✅ Jenkins pipeline automation
- ✅ Integration tests
- ✅ AWS EC2 deployment ready

## 🛠️ Technology Stack

**Frontend:**
- Angular 17
- TypeScript
- Bootstrap 5
- RxJS

**Backend:**
- Node.js
- Express.js
- MySQL2
- JWT (jsonwebtoken)
- bcrypt
- express-validator

**Database:**
- MySQL 8.0

**DevOps:**
- Docker & Docker Compose
- Jenkins
- Nginx
- AWS EC2


## ☁️ AWS EC2 Deployment

### 1. Launch EC2 Instance

- **AMI:** Ubuntu 20.04 or 22.04 LTS
- **Instance Type:** t2.medium or larger (recommended)
- **Storage:** 20GB minimum

### 2. Configure Security Group

Open the following ports:
- 22 (SSH)
- 80 (HTTP)
- 443 (HTTPS - optional)
- 5000 (Backend API)
- 8080 (Jenkins)
- 3306 (MySQL - only if external access needed)

### 3. Connect to EC2 Instance

```bash
ssh -i your-key.pem ubuntu@YOUR_EC2_PUBLIC_IP
```

### 4. Run Setup Script

```bash
# Download the setup script
wget https://raw.githubusercontent.com/YOUR_REPO/deployment/ec2-setup.sh

# Make it executable
chmod +x ec2-setup.sh

# Run the script
./ec2-setup.sh
```

### 5. Get Jenkins Initial Password

```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

## 🔄 Jenkins CI/CD Setup

### 1. Access Jenkins

Navigate to `http://YOUR_EC2_IP:8080`

### 2. Install Required Plugins

- Docker Pipeline
- Git plugin
- GitHub plugin

### 3. Create Pipeline Job

1. Click "New Item"
2. Enter job name: "FullStack-App"
3. Select "Pipeline"
4. Click "OK"

### 4. Configure Pipeline

**Pipeline Definition:** Pipeline script from SCM

**SCM:** Git

**Repository URL:** Your GitHub repository URL

**Script Path:** Jenkinsfile

### 5. Configure GitHub Webhook

1. Go to your GitHub repository settings
2. Navigate to "Webhooks"
3. Click "Add webhook"
4. **Payload URL:** `http://YOUR_EC2_IP:8080/github-webhook/`
5. **Content type:** application/json
6. **Events:** Just the push event
7. Click "Add webhook"

### 6. Test the Pipeline

Push a commit to your repository and watch Jenkins automatically:
1. Checkout code
2. Build Docker images
3. Run integration tests
4. Deploy the application

## 📡 API Documentation

### Authentication Endpoints

#### Register User
```http
POST /api/register
Content-Type: application/json

{
  "username": "johndoe",
  "email": "john@example.com",
  "password": "SecurePass123"
}
```

#### Login
```http
POST /api/login
Content-Type: application/json

{
  "email": "john@example.com",
  "password": "SecurePass123"
}
```

#### Get Profile (Protected)
```http
GET /api/profile
Authorization: Bearer YOUR_JWT_TOKEN
```

### Admin Endpoints

#### Get All Users (Admin Only)
```http
GET /api/admin/users
Authorization: Bearer ADMIN_JWT_TOKEN
```

#### Update User Role (Admin Only)
```http
PUT /api/admin/users/:id
Authorization: Bearer ADMIN_JWT_TOKEN
Content-Type: application/json

{
  "role": "admin"
}
```

#### Delete User (Admin Only)
```http
DELETE /api/admin/users/:id
Authorization: Bearer ADMIN_JWT_TOKEN
```

### Response Format

All API responses follow this format:

```json
{
  "success": true,
  "message": "Operation successful",
  "data": {
    // Response data here
  }
}
```

## 🧪 Testing

### Run Integration Tests

```bash
# Ensure application is running
docker-compose up -d

# Run tests
./tests/integration-tests.sh
```

### Test Coverage

The integration tests verify:
- ✅ All containers are running
- ✅ Service health checks
- ✅ Database connectivity
- ✅ User registration
- ✅ User login
- ✅ JWT authentication
- ✅ Protected route access control
- ✅ Admin endpoint protection
- ✅ Frontend accessibility
- ✅ CORS configuration

## 🐛 Troubleshooting

### Issue: Containers won't start

```bash
# Check logs
docker-compose logs

# Rebuild containers
docker-compose down -v
docker-compose up --build
```

### Issue: Database connection failed

```bash
# Check if MySQL is healthy
docker-compose ps

# Verify MySQL credentials in .env file
# Wait for MySQL to fully initialize (can take 30-60 seconds)
```

### Issue: Frontend can't connect to backend

```bash
# Verify backend is running
curl http://localhost:5000/health

# Check CORS configuration in backend
# Verify FRONTEND_URL in .env matches your frontend URL
```

### Issue: Jenkins can't build Docker images

```bash
# Ensure Jenkins user is in docker group
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

### Issue: Port already in use

```bash
# Find process using port
sudo lsof -i :PORT_NUMBER

# Stop the process or change port in docker-compose.yml
```

## 📁 Project Structure

```
fullstack-app/
├── frontend/                  # Angular application
│   ├── src/
│   │   ├── app/
│   │   │   ├── components/   # UI components
│   │   │   ├── services/     # API services
│   │   │   ├── guards/       # Route guards
│   │   │   └── interceptors/ # HTTP interceptors
│   │   └── environments/     # Environment configs
│   ├── Dockerfile
│   └── nginx.conf
│
├── backend/                   # Node.js/Express API
│   ├── config/               # Configuration files
│   ├── middleware/           # Express middleware
│   ├── models/               # Database models
│   ├── routes/               # API routes
│   ├── server.js             # Entry point
│   └── Dockerfile
│
├── deployment/               # Deployment scripts
│   ├── init.sql             # Database initialization
│   └── ec2-setup.sh         # EC2 setup script
│
├── tests/                    # Integration tests
│   └── integration-tests.sh
│
├── docker-compose.yml        # Docker orchestration
├── Jenkinsfile              # CI/CD pipeline
├── .env                     # Environment variables
└── README.md                # This file
```

## 🔐 Security Considerations

1. **Change Default Credentials:** Always change default admin password
2. **Environment Variables:** Never commit .env files to version control
3. **JWT Secret:** Use a strong, random JWT secret (min 32 characters)
4. **Database Password:** Use strong database passwords
5. **HTTPS:** Enable HTTPS in production (use Let's Encrypt)
6. **Security Headers:** Helmet middleware adds security headers
7. **Input Validation:** All inputs are validated and sanitized
8. **SQL Injection:** Using parameterized queries prevents SQL injection
9. **XSS Protection:** Content Security Policy headers prevent XSS

## 📝 License

This project is licensed under the MIT License.

## 👥 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📞 Support

For issues and questions:
- Create an issue in the GitHub repository
- Check existing documentation and troubleshooting guide
