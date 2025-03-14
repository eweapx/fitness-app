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

/**
 * FitnessTracker class to manage fitness activities
 */
class FitnessTracker {
  constructor() {
    this.activities = [];
    this.caloriesBurned = 0;
    this.stepsCount = 0;
    this.activitiesLogged = 0;
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

    this.activities.unshift(activity);
    this.caloriesBurned += activity.calories;
    this.activitiesLogged += 1;
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
    return this.caloriesBurned;
  }

  /**
   * Get total steps
   * @returns {number} Total steps
   */
  getTotalSteps() {
    return this.stepsCount;
  }

  /**
   * Update step count
   * @param {number} steps - Number of steps to add
   * @returns {boolean} True if steps were added successfully
   */
  addSteps(steps) {
    if (typeof steps !== 'number' || steps <= 0) {
      return false;
    }
    
    this.stepsCount += steps;
    return true;
  }

  /**
   * Get the number of activities logged
   * @returns {number} Number of activities logged
   */
  getActivitiesCount() {
    return this.activitiesLogged;
  }

  /**
   * Clear all fitness tracking data
   */
  reset() {
    this.activities = [];
    this.caloriesBurned = 0;
    this.stepsCount = 0;
    this.activitiesLogged = 0;
  }
}

// Create a global instance for the application
const tracker = new FitnessTracker();

// Example activities (for demonstration)
const runningActivity = new Activity('Morning Run', 250, 30, 'running', new Date());
const weightTrainingActivity = new Activity('Weight Training', 150, 45, 'weights', new Date(Date.now() - 24 * 60 * 60 * 1000));

// Add example activities
tracker.addActivity(runningActivity);
tracker.addActivity(weightTrainingActivity);

// Add some initial steps
tracker.addSteps(5000);

module.exports = {
  Activity,
  FitnessTracker,
  tracker
};