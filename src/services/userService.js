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
    
    // Add user to our array
    this.users.push(user);
    
    // Set as current user
    this.currentUser = user;
    
    // Save to persistent storage
    this.saveToStorage();
    
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
    
    // Update last login time
    user.lastLogin = new Date();
    
    // Save to persistent storage
    this.saveToStorage();
    
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
    
    // Save updated state to storage
    this.saveToStorage();
    
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
    
    // Save to persistent storage
    this.saveToStorage();
    
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
    
    // Save to persistent storage
    this.saveToStorage();
    
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
    
    // Save to persistent storage
    this.saveToStorage();
    
    return { success: true, message: 'Account deleted successfully' };
  }

  /**
   * Save users to data store
   * This would be a database operation in a real backend
   */
  saveToStorage() {
    // In a real application, this would save to a database
    // For our implementation, we'll use a JSON file for persistence
    try {
      const fs = require('fs');
      const path = require('path');
      
      // Create a data directory if it doesn't exist
      const dataDir = path.join(__dirname, '../../data');
      if (!fs.existsSync(dataDir)) {
        fs.mkdirSync(dataDir, { recursive: true });
      }
      
      // Save users to a JSON file
      const usersData = this.users.map(user => {
        // Create a serializable version of the user object
        return {
          id: user.id,
          name: user.name,
          email: user.email,
          password: user.password,
          preferences: user.preferences,
          createdAt: user.createdAt,
          lastLogin: user.lastLogin
        };
      });
      
      // Save current user ID if logged in
      const userData = {
        users: usersData,
        currentUserId: this.currentUser ? this.currentUser.id : null
      };
      
      // Write to file
      fs.writeFileSync(
        path.join(dataDir, 'users.json'),
        JSON.stringify(userData, null, 2)
      );
      
      return true;
    } catch (error) {
      console.error('Error saving users to storage:', error);
      return false;
    }
  }

  /**
   * Load users from data store
   * This would be a database operation in a real backend
   */
  loadFromStorage() {
    try {
      const fs = require('fs');
      const path = require('path');
      
      const dataPath = path.join(__dirname, '../../data/users.json');
      
      // Check if the users file exists
      if (fs.existsSync(dataPath)) {
        // Read and parse the users data
        const userData = JSON.parse(fs.readFileSync(dataPath, 'utf8'));
        
        // Convert plain objects to User instances
        this.users = userData.users.map(userObj => {
          const user = new User(
            userObj.id,
            userObj.name,
            userObj.email,
            userObj.password,
            userObj.preferences || {}
          );
          
          // Copy dates
          user.createdAt = new Date(userObj.createdAt);
          user.lastLogin = new Date(userObj.lastLogin);
          
          return user;
        });
        
        // Restore current user if there was one
        if (userData.currentUserId) {
          this.currentUser = this.getUserById(userData.currentUserId);
        }
      } else if (this.users.length === 0) {
        // If no file exists and we have no users, create a demo user
        this.users.push(new User(
          null,
          'Demo User',
          'demo@example.com',
          'password123',
          { darkMode: true }
        ));
        
        // Save to create the initial file
        this.saveToStorage();
      }
      
      return true;
    } catch (error) {
      console.error('Error loading users from storage:', error);
      
      // If there was an error and we have no users, add a demo user
      if (this.users.length === 0) {
        this.users.push(new User(
          null,
          'Demo User',
          'demo@example.com',
          'password123',
          { darkMode: true }
        ));
      }
      
      return false;
    }
  }
}

// Create a singleton instance
const userService = new UserService();

module.exports = userService;