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
    this.id = id || generateUUID();
    this.name = name;
    this.description = description;
    this.frequency = frequency;
    this.category = category;
    this.trigger = trigger;
    this.alternative = alternative;
    this.reminderTime = reminderTime;
    this.startDate = startDate instanceof Date ? startDate : new Date(startDate);
    
    // Check-in and streak tracking
    this.checkIns = {};
    this.currentStreak = 0;
    this.longestStreak = 0;
    this.lastCheckIn = null;
  }

  /**
   * Add a check-in for this habit
   * @param {Date} date - Date of check-in
   * @param {boolean} success - Whether the user successfully avoided the habit
   * @returns {Object} Updated streak data
   */
  addCheckIn(date, success) {
    const dateKey = this.formatDateKey(date);
    this.checkIns[dateKey] = success;
    this.lastCheckIn = date;
    
    return this.updateStreaks();
  }

  /**
   * Update streak calculations based on check-ins
   * @returns {Object} Updated streak data
   */
  updateStreaks() {
    let currentStreak = 0;
    let longestStreak = this.longestStreak;
    
    // Sort dates in descending order (newest first)
    const dates = Object.keys(this.checkIns).sort().reverse();
    
    // Calculate current streak (consecutive successful days)
    for (let i = 0; i < dates.length; i++) {
      if (this.checkIns[dates[i]]) {
        currentStreak++;
      } else {
        break;
      }
    }
    
    // Update longest streak if needed
    if (currentStreak > longestStreak) {
      longestStreak = currentStreak;
    }
    
    this.currentStreak = currentStreak;
    this.longestStreak = longestStreak;
    
    return {
      currentStreak,
      longestStreak
    };
  }

  /**
   * Get check-ins for the past week
   * @returns {Array} Array of check-ins for the past 7 days
   */
  getWeeklyProgress() {
    const result = [];
    const today = new Date();
    
    for (let i = 6; i >= 0; i--) {
      const date = new Date(today);
      date.setDate(today.getDate() - i);
      const dateKey = this.formatDateKey(date);
      
      result.push({
        date: date,
        success: this.checkIns[dateKey] === true,
        checked: this.checkIns[dateKey] !== undefined
      });
    }
    
    return result;
  }

  /**
   * Format a date as YYYY-MM-DD for consistent keys
   * @param {Date} date - Date to format
   * @returns {string} Formatted date
   */
  formatDateKey(date) {
    const d = new Date(date);
    const year = d.getFullYear();
    const month = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    
    return `${year}-${month}-${day}`;
  }

  /**
   * Get a formatted date string for displaying the start date
   * @returns {string} Formatted date string
   */
  getFormattedStartDate() {
    const options = { year: 'numeric', month: 'short', day: 'numeric' };
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
      this.name && 
      this.name.trim() !== '' && 
      this.frequency && 
      this.category
    );
  }
}

/**
 * HabitTracker class to manage bad habits
 */
class HabitTracker {
  constructor() {
    this.habits = [];
    this.loadFromLocalStorage();
  }

  /**
   * Add a new habit to track
   * @param {BadHabit} habit - The habit to add
   * @returns {boolean} True if the habit was added successfully
   */
  addHabit(habit) {
    if (habit.isValid()) {
      this.habits.push(habit);
      this.saveToLocalStorage();
      return true;
    }
    return false;
  }

  /**
   * Get all habits being tracked
   * @returns {Array} List of habits
   */
  getHabits() {
    return this.habits;
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
    
    if (habitIndex >= 0) {
      // Merge updates with existing habit
      this.habits[habitIndex] = { 
        ...this.habits[habitIndex], 
        ...updates 
      };
      this.saveToLocalStorage();
      return true;
    }
    
    return false;
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
    
    if (habit) {
      const result = habit.addCheckIn(date, success);
      this.saveToLocalStorage();
      return result;
    }
    
    return null;
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
    
    // Get all check-ins from the past week
    const now = new Date();
    const pastWeek = new Date(now);
    pastWeek.setDate(now.getDate() - 7);
    
    let totalCheckIns = 0;
    let successfulCheckIns = 0;
    let longestStreak = 0;
    let totalCurrentStreak = 0;
    
    this.habits.forEach(habit => {
      // Count check-ins
      Object.keys(habit.checkIns).forEach(dateKey => {
        const checkInDate = new Date(dateKey);
        if (checkInDate >= pastWeek) {
          totalCheckIns++;
          if (habit.checkIns[dateKey]) {
            successfulCheckIns++;
          }
        }
      });
      
      // Track longest streak
      if (habit.longestStreak > longestStreak) {
        longestStreak = habit.longestStreak;
      }
      
      // Sum current streaks
      totalCurrentStreak += habit.currentStreak;
    });
    
    // Calculate success rate
    const successRate = totalCheckIns > 0 
      ? Math.round((successfulCheckIns / totalCheckIns) * 100) 
      : 0;
    
    // Average current streak
    const avgCurrentStreak = totalHabits > 0 
      ? Math.round(totalCurrentStreak / totalHabits) 
      : 0;
      
    return {
      totalHabits,
      totalCheckIns,
      successfulCheckIns,
      successRate,
      longestStreak,
      avgCurrentStreak
    };
  }

  /**
   * Save habits to localStorage
   */
  saveToLocalStorage() {
    localStorage.setItem('badHabits', JSON.stringify(this.habits));
  }

  /**
   * Load habits from localStorage
   */
  loadFromLocalStorage() {
    try {
      const savedHabits = localStorage.getItem('badHabits');
      
      if (savedHabits) {
        const parsedHabits = JSON.parse(savedHabits);
        this.habits = parsedHabits.map(habit => {
          return new BadHabit(
            habit.id,
            habit.name,
            habit.description,
            habit.frequency,
            habit.category,
            habit.trigger,
            habit.alternative,
            habit.reminderTime,
            new Date(habit.startDate)
          );
        });
        
        // Restore check-ins and streaks
        this.habits.forEach((habit, index) => {
          if (parsedHabits[index].checkIns) {
            habit.checkIns = parsedHabits[index].checkIns;
          }
          if (parsedHabits[index].currentStreak) {
            habit.currentStreak = parsedHabits[index].currentStreak;
          }
          if (parsedHabits[index].longestStreak) {
            habit.longestStreak = parsedHabits[index].longestStreak;
          }
          if (parsedHabits[index].lastCheckIn) {
            habit.lastCheckIn = new Date(parsedHabits[index].lastCheckIn);
          }
        });
      }
    } catch (error) {
      console.error('Error loading habits from localStorage:', error);
    }
  }

  /**
   * Clear all habit tracking data
   */
  reset() {
    this.habits = [];
    this.saveToLocalStorage();
  }
}