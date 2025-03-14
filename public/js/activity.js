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
      !isNaN(this.calories) && 
      !isNaN(this.duration) && 
      typeof this.type === 'string'
    );
  }
}

/**
 * FitnessTracker class to manage fitness activities
 */
class FitnessTracker {
  constructor() {
    this.activities = [];
    this.totalSteps = 0;
  }
  
  /**
   * Add a new activity to the tracker
   * @param {Activity} activity - The activity to add
   * @returns {boolean} True if the activity was added successfully
   */
  addActivity(activity) {
    if (!(activity instanceof Activity) || !activity.isValid()) {
      return false;
    }
    
    this.activities.push(activity);
    this.saveToLocalStorage();
    return true;
  }
  
  /**
   * Get all activities
   * @returns {Array} List of activities
   */
  getActivities() {
    return [...this.activities];
  }
  
  /**
   * Get total calories burned
   * @returns {number} Total calories burned
   */
  getTotalCalories() {
    return this.activities.reduce((total, activity) => total + activity.calories, 0);
  }
  
  /**
   * Get total steps
   * @returns {number} Total steps
   */
  getTotalSteps() {
    return this.totalSteps;
  }
  
  /**
   * Update step count
   * @param {number} steps - Number of steps to add
   * @returns {boolean} True if steps were added successfully
   */
  addSteps(steps) {
    if (isNaN(steps) || steps <= 0) {
      return false;
    }
    
    this.totalSteps += steps;
    this.saveToLocalStorage();
    return true;
  }
  
  /**
   * Get the number of activities logged
   * @returns {number} Number of activities logged
   */
  getActivitiesCount() {
    return this.activities.length;
  }
  
  /**
   * Save fitness data to localStorage
   */
  saveToLocalStorage() {
    try {
      // Save activities
      localStorage.setItem('fitnessActivities', JSON.stringify(this.activities));
      
      // Save steps count
      localStorage.setItem('totalSteps', this.totalSteps.toString());
    } catch (error) {
      console.error('Error saving to localStorage:', error);
    }
  }
  
  /**
   * Load fitness data from localStorage
   */
  loadFromLocalStorage() {
    try {
      // Load activities
      const storedActivities = localStorage.getItem('fitnessActivities');
      if (storedActivities) {
        const activityData = JSON.parse(storedActivities);
        
        // Reset and recreate activities
        this.activities = [];
        
        activityData.forEach(activityObj => {
          const activity = new Activity(
            activityObj.name,
            activityObj.calories,
            activityObj.duration,
            activityObj.type,
            new Date(activityObj.date)
          );
          
          this.activities.push(activity);
        });
      }
      
      // Load steps count
      const storedSteps = localStorage.getItem('totalSteps');
      if (storedSteps) {
        this.totalSteps = parseInt(storedSteps) || 0;
      }
    } catch (error) {
      console.error('Error loading from localStorage:', error);
    }
  }
  
  /**
   * Clear all fitness tracking data
   */
  reset() {
    this.activities = [];
    this.totalSteps = 0;
    localStorage.removeItem('fitnessActivities');
    localStorage.removeItem('totalSteps');
  }
}

// Create a global instance for the application
const tracker = new FitnessTracker();

// Initialize the tracker by loading from localStorage
document.addEventListener('DOMContentLoaded', () => {
  tracker.loadFromLocalStorage();
});