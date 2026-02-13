const express = require('express');
const router = express.Router();
const { body, param, validationResult } = require('express-validator');
const User = require('../models/User');
const { authenticateToken, isAdmin } = require('../middleware/auth');

/**
 * @route   GET /api/admin/users
 * @desc    Get all users
 * @access  Private/Admin
 */
router.get('/users', authenticateToken, isAdmin, async (req, res, next) => {
  try {
    const users = await User.findAll();
    
    res.json({
      success: true,
      data: { 
        users,
        count: users.length 
      }
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @route   PUT /api/admin/users/:id
 * @desc    Update user role
 * @access  Private/Admin
 */
router.put('/users/:id', [
  authenticateToken,
  isAdmin,
  param('id').isInt().withMessage('Invalid user ID'),
  body('role')
    .isIn(['user', 'admin'])
    .withMessage('Role must be either "user" or "admin"')
], async (req, res, next) => {
  try {
    // Check for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ 
        success: false, 
        message: 'Validation failed',
        errors: errors.array() 
      });
    }

    const userId = parseInt(req.params.id);
    const { role } = req.body;

    // Prevent admin from changing their own role
    if (userId === req.user.id) {
      return res.status(403).json({ 
        success: false, 
        message: 'Cannot change your own role' 
      });
    }

    // Check if user exists
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ 
        success: false, 
        message: 'User not found' 
      });
    }

    // Update role
    const updated = await User.updateRole(userId, role);
    
    if (!updated) {
      return res.status(500).json({ 
        success: false, 
        message: 'Failed to update user role' 
      });
    }

    // Get updated user
    const updatedUser = await User.findById(userId);

    res.json({
      success: true,
      message: 'User role updated successfully',
      data: { user: updatedUser }
    });
  } catch (error) {
    next(error);
  }
});

/**
 * @route   DELETE /api/admin/users/:id
 * @desc    Delete a user
 * @access  Private/Admin
 */
router.delete('/users/:id', [
  authenticateToken,
  isAdmin,
  param('id').isInt().withMessage('Invalid user ID')
], async (req, res, next) => {
  try {
    // Check for validation errors
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ 
        success: false, 
        message: 'Validation failed',
        errors: errors.array() 
      });
    }

    const userId = parseInt(req.params.id);

    // Prevent admin from deleting themselves
    if (userId === req.user.id) {
      return res.status(403).json({ 
        success: false, 
        message: 'Cannot delete your own account' 
      });
    }

    // Check if user exists
    const user = await User.findById(userId);
    if (!user) {
      return res.status(404).json({ 
        success: false, 
        message: 'User not found' 
      });
    }

    // Delete user
    const deleted = await User.delete(userId);
    
    if (!deleted) {
      return res.status(500).json({ 
        success: false, 
        message: 'Failed to delete user' 
      });
    }

    res.json({
      success: true,
      message: 'User deleted successfully'
    });
  } catch (error) {
    next(error);
  }
});

module.exports = router;
