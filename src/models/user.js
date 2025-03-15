/**
 * User model for authentication and user management
 */
class User {
  /**
   * Create a new User
   * @param {string} id - Unique identifier
   * @param {string} name - User's full name
   * @param {string} email - User's email address
   * @param {string} password - User's hashed password
   * @param {Object} preferences - User's app preferences
   * @param {Date} createdAt - Account creation date
   */
  constructor(id, name, email, password, preferences = {}, createdAt = new Date()) {
    this.id = id || generateUUID();
    this.name = name;
    this.email = email;
    this.password = password; // In a real app, this would be hashed
    this.preferences = preferences;
    this.createdAt = createdAt;
  }

  /**
   * Validate if the user has all required fields
   * @returns {boolean} True if the user is valid
   */
  isValid() {
    return (
      this.name && this.name.trim() !== '' &&
      this.email && this.email.trim() !== '' &&
      this.password && this.password.trim() !== '' &&
      this.isValidEmail(this.email)
    );
  }

  /**
   * Check if an email is valid
   * @param {string} email - Email to validate
   * @returns {boolean} True if email is valid
   */
  isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }

  /**
   * Create a safe user object without sensitive data
   * @returns {Object} Safe user object
   */
  toSafeObject() {
    const { password, ...safeUser } = this;
    return safeUser;
  }
}

// Helper function to generate a UUID
function generateUUID() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    const r = Math.random() * 16 | 0;
    const v = c === 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
}

module.exports = User;