-- Create database if not exists
CREATE DATABASE IF NOT EXISTS fullstack_db;
USE fullstack_db;

-- Create users table
CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(30) UNIQUE NOT NULL,
  email VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  role ENUM('user', 'admin') DEFAULT 'user',
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_email (email),
  INDEX idx_username (username),
  INDEX idx_role (role)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert default admin user
-- Password: Admin@123
INSERT INTO users (username, email, password_hash, role) 
VALUES (
  'admin', 
  'admin@example.com', 
  '$2b$10$YourHashedPasswordHere.8ZqVX9zP6vYK2JGnKqI4aO5O5mCJe',
  'admin'
) ON DUPLICATE KEY UPDATE id=id;

-- Note: The password hash above is a placeholder
-- In production, you should generate this using bcrypt with the actual password
-- Example in Node.js: bcrypt.hashSync('Admin@123', 10)
