/**
 * Activity class for storing fitness activity data
 */
class Activity {
  /**
   * Create a new Activity
   * @param {string} name - Activity name
   * @param {number} calories - Calories burned
   * @param {number} duration - Duration in minutes
   * @param {string} type - Type of activity (running, cycling, weights, swimming)
   * @param {Date} date - Date and time of activity
   */
  constructor(name, calories, duration, type, date = new Date()) {
    this.name = name;
    this.calories = calories;
    this.duration = duration;
    this.type = type;
    this.date = date;
  }

  /**
   * Get a formatted date string
   * @returns {string} Formatted date string
   */
  getFormattedDate() {
    const options = { month: 'short', day: 'numeric', year: 'numeric' };
    return this.date.toLocaleDateString('en-US', options);
  }

  /**
   * Validate if the activity has all required fields
   * @returns {boolean} True if the activity is valid
   */
  isValid() {
    return (
      typeof this.name === 'string' && 
      this.name.trim() !== '' && 
      typeof this.calories === 'number' && 
      this.calories > 0 &&
      typeof this.duration === 'number' && 
      this.duration > 0 &&
      typeof this.type === 'string' &&
      ['running', 'cycling', 'weights', 'swimming'].includes(this.type)
    );
  }
}

module.exports = Activity;