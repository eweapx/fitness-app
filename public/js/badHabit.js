/**
 * BadHabit class for tracking habits that users want to break
 */
class BadHabit {
  /**
   * Create a new BadHabit to track
   * @param {string} id - Unique identifier for the habit
   * @param {string} name - Name of the bad habit to break
   * @param {string} description - Why the user wants to quit
   * @param {string} frequency - How often the habit occurs (daily, weekly, etc.)
   * @param {string} category - Type of habit (screen, food, productivity, health, other)
   * @param {string} trigger - What triggers this habit
   * @param {string} alternative - Healthier alternative to replace the habit
   * @param {string} reminderTime - Daily time for check-in reminder
   * @param {Date} startDate - When tracking of this habit began
   */
  constructor(id, name, description, frequency, category, trigger, alternative, reminderTime, startDate = new Date()) {
    this.id = id || crypto.randomUUID(); // Generate ID if not provided
    this.name = name;
    this.description = description;
    this.frequency = frequency;
    this.category = category;
    this.trigger = trigger;
    this.alternative = alternative;
    this.reminderTime = reminderTime;
    this.startDate = startDate;
    this.checkIns = {};
    this.streak = {
      current: 0,
      longest: 0,
      lastCheckIn: null
    };
  }
  
  /**
   * Add a check-in for this habit
   * @param {Date} date - Date of check-in
   * @param {boolean} success - Whether the user successfully avoided the habit
   * @returns {Object} Updated streak data
   */
  addCheckIn(date, success) {
    const dateKey = this.formatDateKey(date);
    
    // Store the check-in
    this.checkIns[dateKey] = {
      success,
      timestamp: date.getTime()
    };
    
    // Update streak data
    return this.updateStreaks();
  }
  
  /**
   * Update streak calculations based on check-ins
   * @returns {Object} Updated streak data
   */
  updateStreaks() {
    // Convert check-ins to array for sorting
    const checkInArray = Object.entries(this.checkIns)
      .map(([dateKey, data]) => ({
        date: dateKey,
        success: data.success,
        timestamp: data.timestamp
      }))
      .sort((a, b) => a.timestamp - b.timestamp);
    
    // If no check-ins, return default streak data
    if (checkInArray.length === 0) {
      return this.streak;
    }
    
    // Calculate current streak
    let currentStreak = 0;
    let longestStreak = 0;
    const lastCheckIn = checkInArray[checkInArray.length - 1];
    
    // Start from the most recent check-in and go backwards
    for (let i = checkInArray.length - 1; i >= 0; i--) {
      if (checkInArray[i].success) {
        currentStreak++;
      } else {
        break; // Streak ends when there's a failure
      }
    }
    
    // Calculate longest streak
    let tempStreak = 0;
    for (const checkIn of checkInArray) {
      if (checkIn.success) {
        tempStreak++;
        if (tempStreak > longestStreak) {
          longestStreak = tempStreak;
        }
      } else {
        tempStreak = 0;
      }
    }
    
    // Update the streak data
    this.streak = {
      current: currentStreak,
      longest: longestStreak,
      lastCheckIn: lastCheckIn.date
    };
    
    return this.streak;
  }
  
  /**
   * Get check-ins for the past week
   * @returns {Array} Array of check-ins for the past 7 days
   */
  getWeeklyProgress() {
    const today = new Date();
    const results = [];
    
    // Loop through the past 7 days
    for (let i = 6; i >= 0; i--) {
      const date = new Date();
      date.setDate(today.getDate() - i);
      const dateKey = this.formatDateKey(date);
      
      results.push({
        date: date,
        dateKey: dateKey,
        checkIn: this.checkIns[dateKey] || null
      });
    }
    
    return results;
  }
  
  /**
   * Format a date as YYYY-MM-DD for consistent keys
   * @param {Date} date - Date to format
   * @returns {string} Formatted date
   */
  formatDateKey(date) {
    return `${date.getFullYear()}-${(date.getMonth() + 1).toString().padStart(2, '0')}-${date.getDate().toString().padStart(2, '0')}`;
  }
  
  /**
   * Get a formatted date string for displaying the start date
   * @returns {string} Formatted date string
   */
  getFormattedStartDate() {
    const options = { month: 'short', day: 'numeric', year: 'numeric' };
    return this.startDate.toLocaleDateString('en-US', options);
  }
  
  /**
   * Get days since tracking started
   * @returns {number} Number of days since tracking began
   */
  getDaysSinceStart() {
    const today = new Date();
    const diffTime = Math.abs(today - this.startDate);
    const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));
    return diffDays;
  }
  
  /**
   * Check if the habit has all required fields
   * @returns {boolean} True if the habit is valid
   */
  isValid() {
    return (
      this.id &&
      typeof this.name === 'string' && 
      this.name.trim() !== '' && 
      typeof this.category === 'string' &&
      typeof this.frequency === 'string'
    );
  }
}

/**
 * HabitTracker class to manage bad habits
 */
class HabitTracker {
  constructor() {
    this.habits = [];
  }
  
  /**
   * Add a new habit to track
   * @param {BadHabit} habit - The habit to add
   * @returns {boolean} True if the habit was added successfully
   */
  addHabit(habit) {
    if (!(habit instanceof BadHabit) || !habit.isValid()) {
      return false;
    }
    
    this.habits.push(habit);
    this.saveToLocalStorage();
    return true;
  }
  
  /**
   * Get all habits being tracked
   * @returns {Array} List of habits
   */
  getHabits() {
    return [...this.habits];
  }
  
  /**
   * Get a specific habit by ID
   * @param {string} id - Habit ID to retrieve
   * @returns {BadHabit|null} The habit if found, null otherwise
   */
  getHabitById(id) {
    return this.habits.find(habit => habit.id === id) || null;
  }
  
  /**
   * Update an existing habit
   * @param {string} id - ID of the habit to update
   * @param {Object} updates - Properties to update
   * @returns {boolean} True if the habit was updated successfully
   */
  updateHabit(id, updates) {
    const habitIndex = this.habits.findIndex(habit => habit.id === id);
    
    if (habitIndex === -1) {
      return false;
    }
    
    // Update the habit properties
    Object.assign(this.habits[habitIndex], updates);
    
    this.saveToLocalStorage();
    return true;
  }
  
  /**
   * Record a check-in for a habit
   * @param {string} id - ID of the habit
   * @param {Date} date - Date of check-in
   * @param {boolean} success - Whether the user avoided the habit
   * @returns {Object|null} Updated streak data if successful, null otherwise
   */
  recordCheckIn(id, date, success) {
    const habit = this.getHabitById(id);
    
    if (!habit) {
      return null;
    }
    
    const streak = habit.addCheckIn(date, success);
    this.saveToLocalStorage();
    return streak;
  }
  
  /**
   * Delete a habit from tracking
   * @param {string} id - ID of the habit to delete
   * @returns {boolean} True if the habit was deleted successfully
   */
  deleteHabit(id) {
    const initialLength = this.habits.length;
    this.habits = this.habits.filter(habit => habit.id !== id);
    
    if (this.habits.length < initialLength) {
      this.saveToLocalStorage();
      return true;
    }
    
    return false;
  }
  
  /**
   * Get overall progress statistics
   * @returns {Object} Statistics on habit breaking progress
   */
  getOverallProgress() {
    const totalHabits = this.habits.length;
    let totalCheckIns = 0;
    let successfulCheckIns = 0;
    let longestStreak = 0;
    
    this.habits.forEach(habit => {
      // Count check-ins
      const checkInCount = Object.keys(habit.checkIns).length;
      totalCheckIns += checkInCount;
      
      // Count successful check-ins
      successfulCheckIns += Object.values(habit.checkIns).filter(checkIn => checkIn.success).length;
      
      // Track longest streak across all habits
      if (habit.streak.longest > longestStreak) {
        longestStreak = habit.streak.longest;
      }
    });
    
    return {
      totalHabits,
      totalCheckIns,
      successfulCheckIns,
      successRate: totalCheckIns > 0 ? (successfulCheckIns / totalCheckIns) * 100 : 0,
      longestStreak
    };
  }
  
  /**
   * Save habits to localStorage
   */
  saveToLocalStorage() {
    try {
      localStorage.setItem('badHabits', JSON.stringify(this.habits));
    } catch (error) {
      console.error('Error saving bad habits to localStorage:', error);
    }
  }
  
  /**
   * Load habits from localStorage
   */
  loadFromLocalStorage() {
    try {
      const storedHabits = localStorage.getItem('badHabits');
      
      if (storedHabits) {
        const habitData = JSON.parse(storedHabits);
        
        // Reset and recreate habits
        this.habits = [];
        
        habitData.forEach(habitObj => {
          const habit = new BadHabit(
            habitObj.id,
            habitObj.name,
            habitObj.description,
            habitObj.frequency,
            habitObj.category,
            habitObj.trigger,
            habitObj.alternative,
            habitObj.reminderTime,
            new Date(habitObj.startDate)
          );
          
          // Restore check-ins and streak data
          habit.checkIns = habitObj.checkIns || {};
          habit.streak = habitObj.streak || { current: 0, longest: 0, lastCheckIn: null };
          
          this.habits.push(habit);
        });
      }
    } catch (error) {
      console.error('Error loading bad habits from localStorage:', error);
    }
  }
  
  /**
   * Clear all habit tracking data
   */
  reset() {
    this.habits = [];
    localStorage.removeItem('badHabits');
  }
}

// Create a global instance for the application
const habitTracker = new HabitTracker();

// Initialize the tracker by loading from localStorage
document.addEventListener('DOMContentLoaded', () => {
  habitTracker.loadFromLocalStorage();
});