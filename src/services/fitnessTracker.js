const Activity = require('../models/activity');

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

module.exports = FitnessTracker;