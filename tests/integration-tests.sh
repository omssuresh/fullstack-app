#!/bin/bash

# Integration Tests for FullStack Application
# This script tests the complete application stack

set -e  # Exit on any error

echo "=========================================="
echo "🧪 FULLSTACK APPLICATION INTEGRATION TESTS"
echo "=========================================="

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Helper function to print test results
print_test_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✅ PASSED${NC}: $2"
        ((TESTS_PASSED++))
    else
        echo -e "${RED}❌ FAILED${NC}: $2"
        ((TESTS_FAILED++))
    fi
}

# Wait for service to be ready
wait_for_service() {
    local url=$1
    local service_name=$2
    local max_attempts=30
    local attempt=0
    
    echo -e "${YELLOW}⏳ Waiting for $service_name to be ready...${NC}"
    
    while [ $attempt -lt $max_attempts ]; do
        if curl -s -f "$url" > /dev/null 2>&1; then
            echo -e "${GREEN}✅ $service_name is ready${NC}"
            return 0
        fi
        attempt=$((attempt + 1))
        sleep 2
    done
    
    echo -e "${RED}❌ $service_name failed to start${NC}"
    return 1
}

echo ""
echo "=========================================="
echo "TEST 1: Verify Docker Containers"
echo "=========================================="

# Check if containers are running
BACKEND_RUNNING=$(docker-compose ps -q backend 2>/dev/null | wc -l)
FRONTEND_RUNNING=$(docker-compose ps -q frontend 2>/dev/null | wc -l)
MYSQL_RUNNING=$(docker-compose ps -q mysql 2>/dev/null | wc -l)

if [ "$BACKEND_RUNNING" -eq 1 ] && [ "$FRONTEND_RUNNING" -eq 1 ] && [ "$MYSQL_RUNNING" -eq 1 ]; then
    print_test_result 0 "All containers are running"
    docker-compose ps
else
    print_test_result 1 "Not all containers are running"
    docker-compose ps
fi

echo ""
echo "=========================================="
echo "TEST 2: Service Health Checks"
echo "=========================================="

# Wait for services to be ready
wait_for_service "http://localhost:5000/health" "Backend API"
BACKEND_READY=$?

wait_for_service "http://localhost:80" "Frontend"
FRONTEND_READY=$?

print_test_result $BACKEND_READY "Backend API health check"
print_test_result $FRONTEND_READY "Frontend health check"

echo ""
echo "=========================================="
echo "TEST 3: Database Connectivity"
echo "=========================================="

# Test database connection from backend
DB_TEST=$(docker-compose exec -T backend node -e "
const mysql = require('mysql2/promise');
(async () => {
    try {
        const connection = await mysql.createConnection({
            host: process.env.DB_HOST,
            user: process.env.DB_USER,
            password: process.env.DB_PASSWORD,
            database: process.env.DB_NAME
        });
        console.log('success');
        await connection.end();
    } catch (error) {
        console.log('failed');
    }
})();
" 2>&1 | grep -c "success" || echo "0")

if [ "$DB_TEST" -eq 1 ]; then
    print_test_result 0 "Backend can connect to database"
else
    print_test_result 1 "Backend cannot connect to database"
fi

echo ""
echo "=========================================="
echo "TEST 4: User Registration API"
echo "=========================================="

# Test user registration
TIMESTAMP=$(date +%s)
REGISTER_RESPONSE=$(curl -s -X POST http://localhost:5000/api/register \
    -H "Content-Type: application/json" \
    -d "{
        \"username\": \"testuser${TIMESTAMP}\",
        \"email\": \"test${TIMESTAMP}@example.com\",
        \"password\": \"Test@123\"
    }")

if echo "$REGISTER_RESPONSE" | grep -q '"success":true'; then
    print_test_result 0 "User registration successful"
    # Extract token for later use
    TOKEN=$(echo "$REGISTER_RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
else
    print_test_result 1 "User registration failed"
    echo "Response: $REGISTER_RESPONSE"
fi

echo ""
echo "=========================================="
echo "TEST 5: User Login API"
echo "=========================================="

# Test user login
LOGIN_RESPONSE=$(curl -s -X POST http://localhost:5000/api/login \
    -H "Content-Type: application/json" \
    -d "{
        \"email\": \"test${TIMESTAMP}@example.com\",
        \"password\": \"Test@123\"
    }")

if echo "$LOGIN_RESPONSE" | grep -q '"success":true'; then
    print_test_result 0 "User login successful"
    LOGIN_TOKEN=$(echo "$LOGIN_RESPONSE" | grep -o '"token":"[^"]*"' | cut -d'"' -f4)
else
    print_test_result 1 "User login failed"
    echo "Response: $LOGIN_RESPONSE"
fi

echo ""
echo "=========================================="
echo "TEST 6: JWT Authentication"
echo "=========================================="

# Test protected endpoint with token
if [ -n "$LOGIN_TOKEN" ]; then
    PROFILE_RESPONSE=$(curl -s -X GET http://localhost:5000/api/profile \
        -H "Authorization: Bearer $LOGIN_TOKEN")
    
    if echo "$PROFILE_RESPONSE" | grep -q '"success":true'; then
        print_test_result 0 "JWT authentication works"
    else
        print_test_result 1 "JWT authentication failed"
        echo "Response: $PROFILE_RESPONSE"
    fi
else
    print_test_result 1 "No token available for testing"
fi

echo ""
echo "=========================================="
echo "TEST 7: Protected Route Access Control"
echo "=========================================="

# Test protected endpoint without token
UNAUTHORIZED_RESPONSE=$(curl -s -w "%{http_code}" -X GET http://localhost:5000/api/profile)
HTTP_CODE="${UNAUTHORIZED_RESPONSE: -3}"

if [ "$HTTP_CODE" = "401" ]; then
    print_test_result 0 "Protected routes properly reject unauthorized access"
else
    print_test_result 1 "Protected routes not properly secured (HTTP $HTTP_CODE)"
fi

echo ""
echo "=========================================="
echo "TEST 8: Admin Endpoint Protection"
echo "=========================================="

# Test admin endpoint with regular user token
if [ -n "$LOGIN_TOKEN" ]; then
    ADMIN_RESPONSE=$(curl -s -w "%{http_code}" -X GET http://localhost:5000/api/admin/users \
        -H "Authorization: Bearer $LOGIN_TOKEN")
    ADMIN_HTTP_CODE="${ADMIN_RESPONSE: -3}"
    
    if [ "$ADMIN_HTTP_CODE" = "403" ]; then
        print_test_result 0 "Admin endpoints properly protected from non-admin users"
    else
        print_test_result 1 "Admin endpoints not properly protected (HTTP $ADMIN_HTTP_CODE)"
    fi
else
    print_test_result 1 "No token available for testing"
fi

echo ""
echo "=========================================="
echo "TEST 9: Frontend Accessibility"
echo "=========================================="

# Test frontend is serving content
FRONTEND_CONTENT=$(curl -s http://localhost:80)

if echo "$FRONTEND_CONTENT" | grep -q "app-root"; then
    print_test_result 0 "Frontend is serving Angular application"
else
    print_test_result 1 "Frontend not serving proper content"
fi

echo ""
echo "=========================================="
echo "TEST 10: CORS Configuration"
echo "=========================================="

# Test CORS headers
CORS_RESPONSE=$(curl -s -H "Origin: http://localhost" -I http://localhost:5000/health)

if echo "$CORS_RESPONSE" | grep -qi "access-control-allow-origin"; then
    print_test_result 0 "CORS headers present"
else
    print_test_result 1 "CORS headers missing"
fi

echo ""
echo "=========================================="
echo "📊 TEST SUMMARY"
echo "=========================================="
echo -e "${GREEN}Tests Passed: $TESTS_PASSED${NC}"
echo -e "${RED}Tests Failed: $TESTS_FAILED${NC}"
echo "Total Tests: $((TESTS_PASSED + TESTS_FAILED))"
echo "=========================================="

# Exit with appropriate code
if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ ALL TESTS PASSED!${NC}"
    exit 0
else
    echo -e "${RED}❌ SOME TESTS FAILED!${NC}"
    exit 1
fi
