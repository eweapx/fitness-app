/**
 * User authentication module for the Health & Wellness Tracker
 */

/**
 * User class for storing user information
 */
class User {
  /**
   * Create a new User
   * @param {string} id - Unique identifier
   * @param {string} name - User's name
   * @param {string} email - User's email address
   * @param {string} password - Hashed password
   * @param {Object} preferences - User preferences
   */
  constructor(id, name, email, password, preferences = {}) {
    this.id = id;
    this.name = name;
    this.email = email;
    this.password = password; // In a real app, this would be hashed
    this.preferences = preferences;
    this.createdAt = new Date();
    this.lastLogin = new Date();
  }
  
  /**
   * Update user profile information
   * @param {Object} updates - Fields to update
   * @returns {boolean} Success indicator
   */
  updateProfile(updates) {
    // Only allow updating certain fields
    if (updates.name) this.name = updates.name;
    if (updates.email) this.email = updates.email;
    if (updates.preferences) this.preferences = { ...this.preferences, ...updates.preferences };
    return true;
  }
  
  /**
   * Check if the provided password matches the stored password
   * @param {string} passwordToCheck - Password to verify
   * @returns {boolean} True if password matches
   */
  checkPassword(passwordToCheck) {
    // In a real app, this would compare hashed passwords
    return this.password === passwordToCheck;
  }
}

/**
 * AuthManager class to handle user authentication
 */
class AuthManager {
  constructor() {
    this.users = [];
    this.currentUser = null;
    this.loadFromLocalStorage();
  }
  
  /**
   * Register a new user
   * @param {string} name - User's name
   * @param {string} email - User's email address
   * @param {string} password - Password (will be stored hashed in a real app)
   * @returns {Object} Result with success flag and message or user
   */
  register(name, email, password) {
    // Validate input
    if (!name || !email || !password) {
      return { success: false, message: 'All fields are required' };
    }
    
    if (password.length < 8) {
      return { success: false, message: 'Password must be at least 8 characters long' };
    }
    
    if (!this.isValidEmail(email)) {
      return { success: false, message: 'Please enter a valid email address' };
    }
    
    // Check if user already exists
    if (this.getUserByEmail(email)) {
      return { success: false, message: 'A user with this email already exists' };
    }
    
    // Create new user
    const id = 'user_' + Date.now().toString(36) + Math.random().toString(36).substring(2);
    const user = new User(id, name, email, password);
    
    // Add user
    this.users.push(user);
    this.saveToLocalStorage();
    
    // Log in the new user
    this.currentUser = user;
    user.lastLogin = new Date();
    this.saveToLocalStorage();
    
    return { success: true, user };
  }
  
  /**
   * Log in a user
   * @param {string} email - User's email address
   * @param {string} password - User's password
   * @returns {Object} Result with success flag and message or user
   */
  login(email, password) {
    const user = this.getUserByEmail(email);
    
    if (!user) {
      return { success: false, message: 'No account found with this email' };
    }
    
    if (!user.checkPassword(password)) {
      return { success: false, message: 'Incorrect password' };
    }
    
    // Update login timestamp
    user.lastLogin = new Date();
    this.currentUser = user;
    this.saveToLocalStorage();
    
    return { success: true, user };
  }
  
  /**
   * Log out the current user
   * @returns {boolean} Success indicator
   */
  logout() {
    this.currentUser = null;
    this.saveToLocalStorage();
    return true;
  }
  
  /**
   * Check if a user is currently logged in
   * @returns {boolean} True if a user is logged in
   */
  isLoggedIn() {
    return this.currentUser !== null;
  }
  
  /**
   * Get the currently logged-in user
   * @returns {User|null} The current user or null if not logged in
   */
  getCurrentUser() {
    return this.currentUser;
  }
  
  /**
   * Find a user by email
   * @param {string} email - Email to search for
   * @returns {User|null} The user with the matching email or null if not found
   */
  getUserByEmail(email) {
    return this.users.find(user => user.email.toLowerCase() === email.toLowerCase());
  }
  
  /**
   * Find a user by ID
   * @param {string} id - User ID to search for
   * @returns {User|null} The user with the matching ID or null if not found
   */
  getUserById(id) {
    return this.users.find(user => user.id === id);
  }
  
  /**
   * Check if an email is valid
   * @param {string} email - Email to validate
   * @returns {boolean} True if email is valid
   */
  isValidEmail(email) {
    const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return re.test(email);
  }
  
  /**
   * Save user data to localStorage
   */
  saveToLocalStorage() {
    // Store users array
    localStorage.setItem('health_tracker_users', JSON.stringify(this.users));
    
    // Store current user ID (if logged in)
    if (this.currentUser) {
      localStorage.setItem('health_tracker_current_user', this.currentUser.id);
    } else {
      localStorage.removeItem('health_tracker_current_user');
    }
  }
  
  /**
   * Load user data from localStorage
   */
  loadFromLocalStorage() {
    // Load users
    const usersData = localStorage.getItem('health_tracker_users');
    
    if (usersData) {
      const parsedUsers = JSON.parse(usersData);
      
      // Convert plain objects to User instances
      this.users = parsedUsers.map(userData => {
        const user = new User(
          userData.id, 
          userData.name, 
          userData.email, 
          userData.password, 
          userData.preferences
        );
        user.createdAt = new Date(userData.createdAt);
        user.lastLogin = new Date(userData.lastLogin);
        return user;
      });
      
      // Load current user
      const currentUserId = localStorage.getItem('health_tracker_current_user');
      if (currentUserId) {
        this.currentUser = this.getUserById(currentUserId);
      }
    }
  }
}

// Create and export a singleton instance
const authManager = new AuthManager();