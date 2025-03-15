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
   * @param {string} id - Unique identifier
   * @param {string} sourceConnection - ID of the health connection this activity came from
   * @param {string} sourceId - ID of the activity in the original health data source
   * @param {Object} workoutDetails - Additional workout details (for weights or specific exercises)
   * @param {number} intensity - Activity intensity (1-5)
   * @param {string} location - Location where activity took place
   * @param {Object} goals - Goals associated with this activity
   * @param {number} distance - Distance covered in km or miles
   * @param {Object} metrics - Additional metrics for the activity
   */
  constructor(name, calories, duration, type, date = new Date(), id = null, sourceConnection = null, sourceId = null, workoutDetails = null, intensity = 3, location = '', goals = null, distance = 0, metrics = null) {
    this.id = id || generateUUID();
    this.name = name;
    this.calories = calories;
    this.duration = duration;
    this.type = type;
    this.date = date instanceof Date ? date : new Date(date);
    
    // Track if this activity is from a health connection
    this.sourceConnection = sourceConnection; // ID of the health connection this activity came from
    this.sourceId = sourceId; // ID of the activity in the original health data source
    
    // Workout details for enhanced activity tracking
    this.workoutDetails = workoutDetails || {
      category: 'cardio', // 'cardio' or 'weights'
      exercises: []       // Array of exercise objects
    };
    
    // New fields for enhanced activity tracking
    this.intensity = intensity; // Scale of 1-5 (low to high)
    this.location = location; // Where the activity took place
    this.goals = goals || {
      enabled: false,
      calorieTarget: 0,
      durationTarget: 0,
      distanceTarget: 0
    };
    this.distance = distance; // Distance in kilometers/miles
    this.metrics = metrics || {
      heartRate: { min: 0, max: 0, avg: 0 },
      pace: { min: 0, max: 0, avg: 0 },
      elevationGain: 0,
      weather: { temp: null, conditions: null }
    };
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
  
  /**
   * Add an exercise to this activity
   * @param {Object} exercise - Exercise details
   * @returns {boolean} True if the exercise was added successfully
   */
  addExercise(exercise) {
    if (this.isValidExercise(exercise)) {
      this.workoutDetails.exercises.push(exercise);
      return true;
    }
    return false;
  }
  
  /**
   * Validate if an exercise has all required fields
   * @param {Object} exercise - Exercise to validate
   * @returns {boolean} True if the exercise is valid
   */
  isValidExercise(exercise) {
    return (
      exercise && 
      exercise.name && 
      exercise.name.trim() !== ''
    );
  }
  
  /**
   * Remove an exercise from this activity
   * @param {number} index - Index of the exercise to remove
   * @returns {boolean} True if the exercise was removed successfully
   */
  removeExercise(index) {
    if (index >= 0 && index < this.workoutDetails.exercises.length) {
      this.workoutDetails.exercises.splice(index, 1);
      return true;
    }
    return false;
  }
  
  /**
   * Update an exercise in this activity
   * @param {number} index - Index of the exercise to update
   * @param {Object} updatedExercise - Updated exercise details
   * @returns {boolean} True if the exercise was updated successfully
   */
  updateExercise(index, updatedExercise) {
    if (
      index >= 0 && 
      index < this.workoutDetails.exercises.length && 
      this.isValidExercise(updatedExercise)
    ) {
      this.workoutDetails.exercises[index] = updatedExercise;
      return true;
    }
    return false;
  }
  
  /**
   * Set the workout category
   * @param {string} category - The category ('cardio' or 'weights')
   * @returns {boolean} True if the category was set successfully
   */
  setWorkoutCategory(category) {
    if (category === 'cardio' || category === 'weights') {
      this.workoutDetails.category = category;
      return true;
    }
    return false;
  }
  
  /**
   * Calculate barbell weight from specified plates
   * @param {Array} plates - Array of plates on one side of the bar
   * @returns {number} Total weight including the bar (45lbs)
   */
  static calculateBarbellWeight(plates) {
    // Standard Olympic barbell weighs 45lbs
    const barWeight = 45;
    
    // If no plates provided, return just the bar weight
    if (!plates || !Array.isArray(plates) || plates.length === 0) {
      return barWeight;
    }
    
    // Calculate the total weight of all plates (doubled because plates are on both sides)
    const plateWeight = plates.reduce((total, plate) => total + parseFloat(plate), 0) * 2;
    
    // Return the total weight (bar + plates)
    return barWeight + plateWeight;
  }
  
  /**
   * Get intensity description
   * @returns {string} Description of the intensity level
   */
  getIntensityDescription() {
    const descriptions = [
      'Very Light',
      'Light',
      'Moderate',
      'Vigorous',
      'Maximum Effort'
    ];
    
    // Ensure intensity is within valid range
    const level = Math.min(Math.max(Math.floor(this.intensity), 1), 5);
    
    return descriptions[level - 1];
  }
  
  /**
   * Set activity goals
   * @param {Object} goals - Goals for this activity
   * @returns {boolean} True if goals were set successfully
   */
  setGoals(goals) {
    if (goals && typeof goals === 'object') {
      this.goals = {
        enabled: true,
        calorieTarget: Number(goals.calorieTarget) || 0,
        durationTarget: Number(goals.durationTarget) || 0,
        distanceTarget: Number(goals.distanceTarget) || 0
      };
      return true;
    }
    return false;
  }
  
  /**
   * Check if activity goals were met
   * @returns {Object} Object with status of each goal
   */
  checkGoalStatus() {
    if (!this.goals.enabled) {
      return { enabled: false };
    }
    
    return {
      enabled: true,
      calories: this.calories >= this.goals.calorieTarget,
      duration: this.duration >= this.goals.durationTarget,
      distance: this.distance >= this.goals.distanceTarget,
      overall: (
        this.calories >= this.goals.calorieTarget &&
        this.duration >= this.goals.durationTarget &&
        this.distance >= this.goals.distanceTarget
      )
    };
  }
  
  /**
   * Update heart rate metrics
   * @param {Object} heartRate - Heart rate metrics (min, max, avg)
   * @returns {boolean} True if metrics were updated successfully
   */
  updateHeartRate(heartRate) {
    if (heartRate && typeof heartRate === 'object') {
      this.metrics.heartRate = {
        min: Number(heartRate.min) || 0,
        max: Number(heartRate.max) || 0,
        avg: Number(heartRate.avg) || 0
      };
      return true;
    }
    return false;
  }
  
  /**
   * Update pace metrics
   * @param {Object} pace - Pace metrics in minutes per km/mile (min, max, avg)
   * @returns {boolean} True if metrics were updated successfully
   */
  updatePace(pace) {
    if (pace && typeof pace === 'object') {
      this.metrics.pace = {
        min: Number(pace.min) || 0,
        max: Number(pace.max) || 0,
        avg: Number(pace.avg) || 0
      };
      return true;
    }
    return false;
  }
  
  /**
   * Calculate activity pace
   * @returns {number} Pace in minutes per km/mile or 0 if no distance
   */
  calculatePace() {
    if (this.distance <= 0) return 0;
    return this.duration / this.distance;
  }
  
  /**
   * Calculate calories per minute
   * @returns {number} Calories burned per minute
   */
  calculateCaloriesPerMinute() {
    if (this.duration <= 0) return 0;
    return this.calories / this.duration;
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
    
    // Create updated activity object preserving source information and workout details
    const updatedActivity = new Activity(
      updates.name || originalActivity.name,
      updates.calories || originalActivity.calories,
      updates.duration || originalActivity.duration,
      updates.type || originalActivity.type,
      updates.date || originalActivity.date,
      id,
      originalActivity.sourceConnection,
      originalActivity.sourceId,
      updates.workoutDetails || originalActivity.workoutDetails,
      updates.intensity !== undefined ? updates.intensity : originalActivity.intensity,
      updates.location || originalActivity.location,
      updates.goals || originalActivity.goals,
      updates.distance !== undefined ? updates.distance : originalActivity.distance,
      updates.metrics || originalActivity.metrics
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
            activity.sourceId,
            activity.workoutDetails,
            activity.intensity,
            activity.location,
            activity.goals,
            activity.distance,
            activity.metrics
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
  
  /**
   * Get activities for a specific date range
   * @param {Date} startDate - Start date of the range
   * @param {Date} endDate - End date of the range
   * @returns {Array} List of activities in the date range
   */
  getActivitiesByDateRange(startDate, endDate) {
    return this.activities.filter(activity => {
      return activity.date >= startDate && activity.date <= endDate;
    });
  }
  
  /**
   * Get activities for the current week
   * @returns {Array} List of activities for this week
   */
  getActivitiesThisWeek() {
    const today = new Date();
    const startOfWeek = new Date(today);
    startOfWeek.setDate(today.getDate() - today.getDay()); // Sunday of this week
    startOfWeek.setHours(0, 0, 0, 0);
    
    const endOfWeek = new Date(startOfWeek);
    endOfWeek.setDate(startOfWeek.getDate() + 6); // Saturday of this week
    endOfWeek.setHours(23, 59, 59, 999);
    
    return this.getActivitiesByDateRange(startOfWeek, endOfWeek);
  }
  
  /**
   * Get activities for the current month
   * @returns {Array} List of activities for this month
   */
  getActivitiesThisMonth() {
    const today = new Date();
    const startOfMonth = new Date(today.getFullYear(), today.getMonth(), 1);
    const endOfMonth = new Date(today.getFullYear(), today.getMonth() + 1, 0, 23, 59, 59, 999);
    
    return this.getActivitiesByDateRange(startOfMonth, endOfMonth);
  }
  
  /**
   * Get total calories burned for a specific date range
   * @param {Date} startDate - Start date of the range
   * @param {Date} endDate - End date of the range
   * @returns {number} Total calories burned in the date range
   */
  getCaloriesByDateRange(startDate, endDate) {
    const activitiesInRange = this.getActivitiesByDateRange(startDate, endDate);
    return activitiesInRange.reduce((total, activity) => {
      return total + Number(activity.calories);
    }, 0);
  }
  
  /**
   * Get total duration for a specific date range
   * @param {Date} startDate - Start date of the range
   * @param {Date} endDate - End date of the range
   * @returns {number} Total duration in minutes for the date range
   */
  getDurationByDateRange(startDate, endDate) {
    const activitiesInRange = this.getActivitiesByDateRange(startDate, endDate);
    return activitiesInRange.reduce((total, activity) => {
      return total + Number(activity.duration);
    }, 0);
  }
  
  /**
   * Get average duration per activity
   * @returns {number} Average duration in minutes per activity
   */
  getAverageDuration() {
    if (this.activities.length === 0) return 0;
    
    const totalDuration = this.activities.reduce((total, activity) => {
      return total + Number(activity.duration);
    }, 0);
    
    return Math.round(totalDuration / this.activities.length);
  }
  
  /**
   * Get calories burned this week
   * @returns {number} Total calories burned this week
   */
  getWeeklyCalories() {
    const today = new Date();
    const startOfWeek = new Date(today);
    startOfWeek.setDate(today.getDate() - today.getDay()); // Sunday of this week
    startOfWeek.setHours(0, 0, 0, 0);
    
    const endOfWeek = new Date(startOfWeek);
    endOfWeek.setDate(startOfWeek.getDate() + 6); // Saturday of this week
    endOfWeek.setHours(23, 59, 59, 999);
    
    return this.getCaloriesByDateRange(startOfWeek, endOfWeek);
  }
  
  /**
   * Get total duration this week
   * @returns {number} Total duration in minutes this week
   */
  getWeeklyDuration() {
    const today = new Date();
    const startOfWeek = new Date(today);
    startOfWeek.setDate(today.getDate() - today.getDay()); // Sunday of this week
    startOfWeek.setHours(0, 0, 0, 0);
    
    const endOfWeek = new Date(startOfWeek);
    endOfWeek.setDate(startOfWeek.getDate() + 6); // Saturday of this week
    endOfWeek.setHours(23, 59, 59, 999);
    
    return this.getDurationByDateRange(startOfWeek, endOfWeek);
  }
  
  /**
   * Get activities by type
   * @param {string} type - The type of activity to filter by
   * @returns {Array} List of activities of the specified type
   */
  getActivitiesByType(type) {
    return this.activities.filter(activity => activity.type === type);
  }
  
  /**
   * Get activities sorted by the specified criteria
   * @param {string} sortBy - Sort criteria (date-desc, date-asc, duration-desc, calories-desc, intensity-desc, distance-desc)
   * @returns {Array} Sorted list of activities
   */
  getSortedActivities(sortBy = 'date-desc') {
    const sortedActivities = [...this.activities];
    
    switch(sortBy) {
      case 'date-asc':
        sortedActivities.sort((a, b) => a.date - b.date);
        break;
      case 'duration-desc':
        sortedActivities.sort((a, b) => Number(b.duration) - Number(a.duration));
        break;
      case 'calories-desc':
        sortedActivities.sort((a, b) => Number(b.calories) - Number(a.calories));
        break;
      case 'intensity-desc':
        sortedActivities.sort((a, b) => Number(b.intensity || 3) - Number(a.intensity || 3));
        break;
      case 'distance-desc':
        sortedActivities.sort((a, b) => Number(b.distance || 0) - Number(a.distance || 0));
        break;
      case 'date-desc':
      default:
        sortedActivities.sort((a, b) => b.date - a.date);
        break;
    }
    
    return sortedActivities;
  }
  
  /**
   * Filter activities by search text (name or type)
   * @param {string} searchText - Text to search for
   * @returns {Array} Filtered list of activities
   */
  searchActivities(searchText) {
    if (!searchText || searchText.trim() === '') return this.activities;
    
    const searchLower = searchText.toLowerCase().trim();
    return this.activities.filter(activity => {
      return activity.name.toLowerCase().includes(searchLower) || 
             activity.type.toLowerCase().includes(searchLower);
    });
  }
  
  /**
   * Get activity data for calendar display
   * @returns {Object} Activity data organized by date
   */
  getCalendarActivityData() {
    const activityByDate = {};
    
    this.activities.forEach(activity => {
      const dateKey = formatDateYYYYMMDD(activity.date);
      
      if (!activityByDate[dateKey]) {
        activityByDate[dateKey] = {
          count: 0,
          calories: 0,
          duration: 0,
          types: new Set()
        };
      }
      
      activityByDate[dateKey].count++;
      activityByDate[dateKey].calories += Number(activity.calories);
      activityByDate[dateKey].duration += Number(activity.duration);
      activityByDate[dateKey].types.add(activity.type);
    });
    
    // Convert Sets to Arrays for easier handling
    Object.keys(activityByDate).forEach(date => {
      activityByDate[date].types = Array.from(activityByDate[date].types);
    });
    
    return activityByDate;
  }
  
  /**
   * Get total distance for all activities or by type
   * @param {string} type - Optional activity type filter
   * @returns {number} Total distance
   */
  getTotalDistance(type = null) {
    let filteredActivities = this.activities;
    
    if (type) {
      filteredActivities = this.getActivitiesByType(type);
    }
    
    return filteredActivities.reduce((total, activity) => {
      return total + (Number(activity.distance) || 0);
    }, 0);
  }
  
  /**
   * Get average intensity of activities
   * @returns {number} Average intensity (1-5)
   */
  getAverageIntensity() {
    if (this.activities.length === 0) return 0;
    
    const totalIntensity = this.activities.reduce((total, activity) => {
      return total + (Number(activity.intensity) || 3); // Default to moderate if not set
    }, 0);
    
    return (totalIntensity / this.activities.length).toFixed(1);
  }
  
  /**
   * Compare two activities
   * @param {string} id1 - ID of first activity
   * @param {string} id2 - ID of second activity
   * @returns {Object} Comparison results
   */
  compareActivities(id1, id2) {
    const activity1 = this.getActivityById(id1);
    const activity2 = this.getActivityById(id2);
    
    if (!activity1 || !activity2) return null;
    
    return {
      calories: {
        diff: activity1.calories - activity2.calories,
        percent: activity2.calories ? ((activity1.calories - activity2.calories) / activity2.calories * 100).toFixed(1) : 0
      },
      duration: {
        diff: activity1.duration - activity2.duration,
        percent: activity2.duration ? ((activity1.duration - activity2.duration) / activity2.duration * 100).toFixed(1) : 0
      },
      distance: {
        diff: (activity1.distance || 0) - (activity2.distance || 0),
        percent: activity2.distance ? (((activity1.distance || 0) - (activity2.distance || 0)) / activity2.distance * 100).toFixed(1) : 0
      },
      intensity: {
        diff: (activity1.intensity || 3) - (activity2.intensity || 3)
      },
      pace: {
        activity1: activity1.calculatePace(),
        activity2: activity2.calculatePace(),
        diff: activity1.calculatePace() - activity2.calculatePace()
      }
    };
  }
  
  /**
   * Get activities with goals
   * @param {boolean} metGoalsOnly - Filter to only activities that met their goals
   * @returns {Array} Activities with goals
   */
  getActivitiesWithGoals(metGoalsOnly = false) {
    return this.activities.filter(activity => {
      if (!activity.goals || !activity.goals.enabled) return false;
      
      if (metGoalsOnly) {
        const goalStatus = activity.checkGoalStatus();
        return goalStatus.overall;
      }
      
      return true;
    });
  }
  
  /**
   * Get progress metrics for a given exercise across activities
   * @param {string} exerciseName - Name of the exercise to track
   * @returns {Object} Progress metrics
   */
  getExerciseProgress(exerciseName) {
    if (!exerciseName) return null;
    
    // Filter to weight activities that contain this exercise
    const relevantActivities = this.activities.filter(activity => {
      return activity.workoutDetails && 
             activity.workoutDetails.category === 'weights' &&
             activity.workoutDetails.exercises &&
             activity.workoutDetails.exercises.some(ex => ex.name === exerciseName);
    });
    
    if (relevantActivities.length === 0) return null;
    
    // Sort by date ascending
    relevantActivities.sort((a, b) => a.date - b.date);
    
    // Extract the metrics for each occurrence of the exercise
    const progressData = {
      dates: [],
      weights: [],
      reps: [],
      sets: []
    };
    
    relevantActivities.forEach(activity => {
      // Find all matching exercises in this activity (could be multiple sets)
      const exercises = activity.workoutDetails.exercises.filter(ex => ex.name === exerciseName);
      
      if (exercises.length > 0) {
        progressData.dates.push(formatDateYYYYMMDD(activity.date));
        
        // Calculate average weight and total reps for this session
        let totalWeight = 0;
        let totalReps = 0;
        
        exercises.forEach(ex => {
          totalWeight += (Number(ex.weight) || 0);
          totalReps += (Number(ex.reps) || 0);
        });
        
        progressData.weights.push(totalWeight / exercises.length);
        progressData.reps.push(totalReps);
        progressData.sets.push(exercises.length);
      }
    });
    
    return progressData;
  }
  
  /**
   * Get personal records by activity type
   * @returns {Object} Personal records organized by type
   */
  getPersonalRecords() {
    const records = {
      'running': { distance: 0, duration: 0, calories: 0, pace: Infinity },
      'cycling': { distance: 0, duration: 0, calories: 0, speed: 0 },
      'swimming': { distance: 0, duration: 0, calories: 0, pace: Infinity },
      'weights': { mostCalories: 0, longestWorkout: 0 }
    };
    
    this.activities.forEach(activity => {
      if (!activity.type) return;
      
      // Make sure the type exists in our records object
      if (!records[activity.type]) {
        records[activity.type] = { distance: 0, duration: 0, calories: 0 };
      }
      
      // Update general records for this type
      if (Number(activity.calories) > records[activity.type].calories) {
        records[activity.type].calories = Number(activity.calories);
      }
      
      if (Number(activity.duration) > records[activity.type].duration) {
        records[activity.type].duration = Number(activity.duration);
      }
      
      // Update activity-specific records
      if (activity.type === 'running' || activity.type === 'cycling' || activity.type === 'swimming') {
        if (Number(activity.distance) > records[activity.type].distance) {
          records[activity.type].distance = Number(activity.distance);
        }
        
        // For running & swimming, lower pace is better
        if ((activity.type === 'running' || activity.type === 'swimming') && activity.distance > 0) {
          const pace = activity.duration / activity.distance;
          if (pace < records[activity.type].pace && pace > 0) {
            records[activity.type].pace = pace;
          }
        }
        
        // For cycling, higher speed is better
        if (activity.type === 'cycling' && activity.duration > 0) {
          const speed = (activity.distance / (activity.duration / 60)).toFixed(1); // km/h or mph
          if (speed > records[activity.type].speed) {
            records[activity.type].speed = speed;
          }
        }
      }
    });
    
    return records;
  }
}