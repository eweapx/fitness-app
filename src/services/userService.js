/**
 * User authentication and management service
 */
const User = require('../models/user');

class UserService {
  constructor() {
    this.users = [];
    this.currentUser = null;
  }

  /**
   * Register a new user
   * @param {string} name - User's name
   * @param {string} email - User's email
   * @param {string} password - User's password (will be stored hashed in a real app)
   * @returns {Object} Result with success flag and message or user
   */
  register(name, email, password) {
    // Check if user with email already exists
    const existingUser = this.getUserByEmail(email);
    if (existingUser) {
      return { success: false, message: 'Email already in use' };
    }

    // Create new user
    const user = new User(null, name, email, password);
    
    // Validate user
    if (!user.isValid()) {
      return { success: false, message: 'Invalid user data' };
    }
    
    // Add user
    this.users.push(user);
    
    // Return success with safe user object
    return { 
      success: true, 
      user: user.toSafeObject(),
      message: 'Registration successful' 
    };
  }

  /**
   * Log in a user
   * @param {string} email - User's email
   * @param {string} password - User's password
   * @returns {Object} Result with success flag and message or user
   */
  login(email, password) {
    const user = this.getUserByEmail(email);
    
    // Check if user exists
    if (!user) {
      return { success: false, message: 'User not found' };
    }
    
    // Check password (in a real app, you would hash and compare)
    if (user.password !== password) {
      return { success: false, message: 'Invalid password' };
    }
    
    // Set current user
    this.currentUser = user;
    
    // Return success with safe user object
    return { 
      success: true, 
      user: user.toSafeObject(),
      message: 'Login successful' 
    };
  }

  /**
   * Log out the current user
   * @returns {Object} Result with success flag and message
   */
  logout() {
    if (!this.currentUser) {
      return { success: false, message: 'No user is logged in' };
    }
    
    this.currentUser = null;
    return { success: true, message: 'Logout successful' };
  }

  /**
   * Get the currently logged in user
   * @returns {Object|null} Safe user object or null if not logged in
   */
  getCurrentUser() {
    return this.currentUser ? this.currentUser.toSafeObject() : null;
  }

  /**
   * Get a user by email
   * @param {string} email - Email to search for
   * @returns {User|null} User object or null if not found
   */
  getUserByEmail(email) {
    return this.users.find(user => user.email === email);
  }

  /**
   * Get a user by ID
   * @param {string} id - User ID to search for
   * @returns {User|null} User object or null if not found
   */
  getUserById(id) {
    return this.users.find(user => user.id === id);
  }

  /**
   * Update a user's profile
   * @param {string} userId - ID of the user to update
   * @param {Object} updates - User properties to update
   * @returns {Object} Result with success flag and message or user
   */
  updateUser(userId, updates) {
    const userIndex = this.users.findIndex(user => user.id === userId);
    
    if (userIndex === -1) {
      return { success: false, message: 'User not found' };
    }
    
    // Prevent updating sensitive fields directly
    const { id, password, ...safeUpdates } = updates;
    
    // Update user
    this.users[userIndex] = { ...this.users[userIndex], ...safeUpdates };
    
    // If this is the current user, update current user as well
    if (this.currentUser && this.currentUser.id === userId) {
      this.currentUser = this.users[userIndex];
    }
    
    return { 
      success: true, 
      user: this.users[userIndex].toSafeObject(),
      message: 'Profile updated successfully' 
    };
  }

  /**
   * Change a user's password
   * @param {string} userId - ID of the user
   * @param {string} currentPassword - Current password for verification
   * @param {string} newPassword - New password to set
   * @returns {Object} Result with success flag and message
   */
  changePassword(userId, currentPassword, newPassword) {
    const user = this.getUserById(userId);
    
    if (!user) {
      return { success: false, message: 'User not found' };
    }
    
    // Verify current password
    if (user.password !== currentPassword) {
      return { success: false, message: 'Current password is incorrect' };
    }
    
    // Update password
    user.password = newPassword;
    
    return { success: true, message: 'Password changed successfully' };
  }

  /**
   * Delete a user account
   * @param {string} userId - ID of the user to delete
   * @param {string} password - Password for verification
   * @returns {Object} Result with success flag and message
   */
  deleteAccount(userId, password) {
    const userIndex = this.users.findIndex(user => user.id === userId);
    
    if (userIndex === -1) {
      return { success: false, message: 'User not found' };
    }
    
    // Verify password
    if (this.users[userIndex].password !== password) {
      return { success: false, message: 'Password is incorrect' };
    }
    
    // Remove user
    this.users.splice(userIndex, 1);
    
    // If this was the current user, log out
    if (this.currentUser && this.currentUser.id === userId) {
      this.currentUser = null;
    }
    
    return { success: true, message: 'Account deleted successfully' };
  }

  /**
   * Save users to data store
   * This would be a database operation in a real backend
   */
  saveToStorage() {
    // In a real application, this would save to a database
    // For our implementation, data is already in memory
    return true;
  }

  /**
   * Load users from data store
   * This would be a database operation in a real backend
   */
  loadFromStorage() {
    // In a real application, this would load from a database
    // For our simple implementation, we'll add a demo user if none exists
    if (this.users.length === 0) {
      // Add a demo user for testing
      this.users.push(new User(
        null,
        'Demo User',
        'demo@example.com',
        'password123',
        { darkMode: true }
      ));
    }
    
    return true;
  }
}

// Create a singleton instance
const userService = new UserService();

module.exports = userService;