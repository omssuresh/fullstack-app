const { pool } = require('../config/database');
const bcrypt = require('bcryptjs');

const SALT_ROUNDS = 10;

class User {
  /**
   * Create a new user
   */
  static async create(userData) {
    const { username, email, password, role = 'user' } = userData;
    
    // Hash password
    const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);
    
    const query = `
      INSERT INTO users (username, email, password_hash, role)
      VALUES (?, ?, ?, ?)
    `;
    
    const [result] = await pool.execute(query, [username, email, passwordHash, role]);
    
    return {
      id: result.insertId,
      username,
      email,
      role
    };
  }

  /**
   * Find user by ID
   */
  static async findById(id) {
    const query = 'SELECT id, username, email, role, created_at FROM users WHERE id = ?';
    const [rows] = await pool.execute(query, [id]);
    return rows[0] || null;
  }

  /**
   * Find user by email (includes password for authentication)
   */
  static async findByEmail(email) {
    const query = 'SELECT * FROM users WHERE email = ?';
    const [rows] = await pool.execute(query, [email]);
    return rows[0] || null;
  }

  /**
   * Find user by username (includes password for authentication)
   */
  static async findByUsername(username) {
    const query = 'SELECT * FROM users WHERE username = ?';
    const [rows] = await pool.execute(query, [username]);
    return rows[0] || null;
  }

  /**
   * Get all users (admin only)
   */
  static async findAll() {
    const query = 'SELECT id, username, email, role, created_at FROM users ORDER BY created_at DESC';
    const [rows] = await pool.execute(query);
    return rows;
  }

  /**
   * Update user role (admin only)
   */
  static async updateRole(userId, newRole) {
    const query = 'UPDATE users SET role = ? WHERE id = ?';
    const [result] = await pool.execute(query, [newRole, userId]);
    return result.affectedRows > 0;
  }

  /**
   * Verify password
   */
  static async verifyPassword(plainPassword, hashedPassword) {
    return await bcrypt.compare(plainPassword, hashedPassword);
  }

  /**
   * Delete user
   */
  static async delete(userId) {
    const query = 'DELETE FROM users WHERE id = ?';
    const [result] = await pool.execute(query, [userId]);
    return result.affectedRows > 0;
  }
}

module.exports = User;
