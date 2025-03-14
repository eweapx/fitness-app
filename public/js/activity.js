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
  constructor(name, calories, duration, type, date = new Date(), id = null, sourceConnection = null, sourceId = null) {
    this.id = id || Date.now().toString();
    this.name = name;
    this.calories = calories;
    this.duration = duration;
    this.type = type;
    this.date = date instanceof Date ? date : new Date(date);
    
    // Track if this activity is from a health connection
    this.sourceConnection = sourceConnection; // ID of the health connection this activity came from
    this.sourceId = sourceId; // ID of the activity in the original health data source
  }

  /**
   * Get a formatted date string
   * @returns {string} Formatted date string
   */
  getFormattedDate() {
    const options = { 
      weekday: 'short', 
      month: 'short', 
      day: 'numeric',
      hour: '2-digit',
      minute: '2-digit'
    };
    return this.date.toLocaleDateString('en-US', options);
  }

  /**
   * Validate if the activity has all required fields
   * @returns {boolean} True if the activity is valid
   */
  isValid() {
    return (
      this.name && 
      this.name.trim() !== '' && 
      this.calories && 
      Number(this.calories) > 0 &&
      this.duration && 
      Number(this.duration) > 0 && 
      this.type
    );
  }
}

/**
 * FitnessTracker class to manage fitness activities
 */
class FitnessTracker {
  constructor() {
    this.activities = [];
    this.steps = 0;
    this.loadFromLocalStorage();
  }

  /**
   * Add a new activity to the tracker
   * @param {Activity} activity - The activity to add
   * @returns {boolean} True if the activity was added successfully
   */
  addActivity(activity) {
    if (activity.isValid()) {
      this.activities.push(activity);
      this.saveToLocalStorage();
      return true;
    }
    return false;
  }

  /**
   * Get all activities
   * @returns {Array} List of activities
   */
  getActivities() {
    return this.activities;
  }

  /**
   * Get total calories burned
   * @returns {number} Total calories burned
   */
  getTotalCalories() {
    return this.activities.reduce((total, activity) => {
      return total + Number(activity.calories);
    }, 0);
  }

  /**
   * Get total steps
   * @returns {number} Total steps
   */
  getTotalSteps() {
    return this.steps;
  }

  /**
   * Update step count
   * @param {number} steps - Number of steps to add
   * @returns {boolean} True if steps were added successfully
   */
  addSteps(steps) {
    if (steps && Number(steps) > 0) {
      this.steps += Number(steps);
      this.saveToLocalStorage();
      return true;
    }
    return false;
  }

  /**
   * Get the number of activities logged
   * @returns {number} Number of activities logged
   */
  getActivitiesCount() {
    return this.activities.length;
  }
  
  /**
   * Get an activity by ID
   * @param {string} id - The ID of the activity to find
   * @returns {Activity|null} The activity if found, null otherwise
   */
  getActivityById(id) {
    return this.activities.find(activity => activity.id === id) || null;
  }
  
  /**
   * Update an existing activity
   * @param {string} id - The ID of the activity to update
   * @param {Object} updates - The fields to update
   * @returns {boolean} True if the activity was updated successfully
   */
  updateActivity(id, updates) {
    const activityIndex = this.activities.findIndex(activity => activity.id === id);
    
    if (activityIndex === -1) return false;
    
    // Get the original activity
    const originalActivity = this.activities[activityIndex];
    
    // Create updated activity object preserving source information
    const updatedActivity = new Activity(
      updates.name || originalActivity.name,
      updates.calories || originalActivity.calories,
      updates.duration || originalActivity.duration,
      updates.type || originalActivity.type,
      updates.date || originalActivity.date,
      id,
      originalActivity.sourceConnection,
      originalActivity.sourceId
    );
    
    if (updatedActivity.isValid()) {
      this.activities[activityIndex] = updatedActivity;
      this.saveToLocalStorage();
      return true;
    }
    
    return false;
  }
  
  /**
   * Delete an activity by ID
   * @param {string} id - The ID of the activity to delete
   * @returns {boolean} True if the activity was deleted successfully
   */
  deleteActivity(id) {
    const initialLength = this.activities.length;
    this.activities = this.activities.filter(activity => activity.id !== id);
    
    if (this.activities.length < initialLength) {
      this.saveToLocalStorage();
      return true;
    }
    
    return false;
  }

  /**
   * Save fitness data to localStorage
   */
  saveToLocalStorage() {
    localStorage.setItem('fitnessActivities', JSON.stringify(this.activities));
    localStorage.setItem('fitnessSteps', this.steps);
  }

  /**
   * Load fitness data from localStorage
   */
  loadFromLocalStorage() {
    try {
      const savedActivities = localStorage.getItem('fitnessActivities');
      const savedSteps = localStorage.getItem('fitnessSteps');
      
      if (savedActivities) {
        const parsedActivities = JSON.parse(savedActivities);
        this.activities = parsedActivities.map(activity => {
          const newActivity = new Activity(
            activity.name,
            activity.calories,
            activity.duration,
            activity.type,
            new Date(activity.date),
            activity.id,
            activity.sourceConnection,
            activity.sourceId
          );
          // Ensure the activity ID is preserved
          newActivity.id = activity.id || newActivity.id;
          return newActivity;
        });
      }
      
      if (savedSteps) {
        this.steps = Number(savedSteps);
      }
    } catch (error) {
      console.error('Error loading fitness data from localStorage:', error);
    }
  }

  /**
   * Clear all fitness tracking data
   */
  reset() {
    this.activities = [];
    this.steps = 0;
    this.saveToLocalStorage();
  }
}