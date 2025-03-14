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
    this.id = id;
    this.name = name;
    this.description = description;
    this.frequency = frequency;
    this.category = category;
    this.trigger = trigger;
    this.alternative = alternative;
    this.reminderTime = reminderTime;
    this.startDate = startDate;
    this.streakData = {
      currentStreak: 0,
      bestStreak: 0,
      daysWithout: 0,
      successRate: 0
    };
    this.checkIns = []; // Array of check-in dates and success (boolean)
  }

  /**
   * Add a check-in for this habit
   * @param {Date} date - Date of check-in
   * @param {boolean} success - Whether the user successfully avoided the habit
   * @returns {Object} Updated streak data
   */
  addCheckIn(date, success) {
    // Store the check-in
    this.checkIns.push({
      date: date,
      success: success
    });

    // Update streak data
    return this.updateStreaks();
  }

  /**
   * Update streak calculations based on check-ins
   * @returns {Object} Updated streak data
   */
  updateStreaks() {
    // Sort check-ins by date
    const sortedCheckIns = [...this.checkIns].sort((a, b) => a.date - b.date);
    
    let currentStreak = 0;
    let bestStreak = 0;
    let daysWithout = 0;
    
    // Calculate current streak (consecutive successful days)
    for (let i = sortedCheckIns.length - 1; i >= 0; i--) {
      if (sortedCheckIns[i].success) {
        currentStreak++;
      } else {
        break;
      }
    }
    
    // Calculate best streak
    let tempStreak = 0;
    for (let checkIn of sortedCheckIns) {
      if (checkIn.success) {
        tempStreak++;
        bestStreak = Math.max(bestStreak, tempStreak);
      } else {
        tempStreak = 0;
      }
    }
    
    // Days without the habit (from the most recent successful check-in)
    if (sortedCheckIns.length > 0 && sortedCheckIns[sortedCheckIns.length - 1].success) {
      const lastCheckIn = sortedCheckIns[sortedCheckIns.length - 1].date;
      daysWithout = Math.floor((new Date() - lastCheckIn) / (1000 * 60 * 60 * 24)) + 1;
    }
    
    // Success rate calculation
    const successCount = this.checkIns.filter(checkIn => checkIn.success).length;
    const successRate = this.checkIns.length > 0 ? Math.round((successCount / this.checkIns.length) * 100) : 0;
    
    // Update and return streak data
    this.streakData = { currentStreak, bestStreak, daysWithout, successRate };
    return this.streakData;
  }

  /**
   * Get check-ins for the past week
   * @returns {Array} Array of check-ins for the past 7 days
   */
  getWeeklyProgress() {
    const today = new Date();
    const oneWeekAgo = new Date(today);
    oneWeekAgo.setDate(oneWeekAgo.getDate() - 6); // Get data for 7 days (including today)
    
    // Create a mapping of dates to their day of week
    const weekDays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    const weekData = {};
    
    // Initialize all days of the week
    for (let i = 0; i < 7; i++) {
      const date = new Date(oneWeekAgo);
      date.setDate(date.getDate() + i);
      const dayOfWeek = weekDays[date.getDay()];
      const dateStr = this.formatDateKey(date);
      weekData[dateStr] = { day: dayOfWeek, success: null }; // null means no check-in
    }
    
    // Add actual check-in data
    for (const checkIn of this.checkIns) {
      const checkInDate = new Date(checkIn.date);
      if (checkInDate >= oneWeekAgo && checkInDate <= today) {
        const dateStr = this.formatDateKey(checkInDate);
        if (weekData[dateStr]) {
          weekData[dateStr].success = checkIn.success;
        }
      }
    }
    
    return Object.values(weekData);
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
    return Math.floor((new Date() - this.startDate) / (1000 * 60 * 60 * 24)) + 1;
  }
  
  /**
   * Check if the habit has all required fields
   * @returns {boolean} True if the habit is valid
   */
  isValid() {
    return (
      typeof this.name === 'string' && 
      this.name.trim() !== '' && 
      typeof this.description === 'string' &&
      typeof this.frequency === 'string' && 
      typeof this.category === 'string'
    );
  }
}

/**
 * HabitTracker class to manage bad habits
 */
class HabitTracker {
  constructor() {
    this.habits = [];
    this.nextId = 1;
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
    
    // Generate ID if not provided
    if (!habit.id) {
      habit.id = this.nextId.toString();
      this.nextId++;
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
    
    const habit = this.habits[habitIndex];
    
    // Update fields
    Object.keys(updates).forEach(key => {
      if (key !== 'id' && key !== 'checkIns' && key !== 'streakData') {
        habit[key] = updates[key];
      }
    });
    
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
    
    const streakData = habit.addCheckIn(date, success);
    this.saveToLocalStorage();
    return streakData;
  }
  
  /**
   * Delete a habit from tracking
   * @param {string} id - ID of the habit to delete
   * @returns {boolean} True if the habit was deleted successfully
   */
  deleteHabit(id) {
    const initialLength = this.habits.length;
    this.habits = this.habits.filter(habit => habit.id !== id);
    
    if (this.habits.length !== initialLength) {
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
    if (this.habits.length === 0) {
      return {
        successRate: 0,
        currentStreak: 0,
        bestStreak: 0,
        daysWithout: 0,
        totalHabits: 0
      };
    }
    
    // Calculate aggregate statistics
    let totalSuccessRate = 0;
    let bestOverallStreak = 0;
    let totalCurrentStreak = 0;
    let totalDaysWithout = 0;
    
    this.habits.forEach(habit => {
      totalSuccessRate += habit.streakData.successRate;
      bestOverallStreak = Math.max(bestOverallStreak, habit.streakData.bestStreak);
      totalCurrentStreak += habit.streakData.currentStreak;
      totalDaysWithout += habit.streakData.daysWithout;
    });
    
    return {
      successRate: Math.round(totalSuccessRate / this.habits.length),
      currentStreak: Math.round(totalCurrentStreak / this.habits.length),
      bestStreak: bestOverallStreak,
      daysWithout: Math.round(totalDaysWithout / this.habits.length),
      totalHabits: this.habits.length
    };
  }
  
  /**
   * Save habits to localStorage
   */
  saveToLocalStorage() {
    try {
      localStorage.setItem('badHabits', JSON.stringify(this.habits));
    } catch (error) {
      console.error('Error saving habits to localStorage:', error);
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
        
        // Reset the habits array
        this.habits = [];
        
        // Find the highest ID to set nextId correctly
        let maxId = 0;
        
        habitData.forEach(habitObj => {
          // Convert date strings back to Date objects
          const startDate = new Date(habitObj.startDate);
          
          // Create a new BadHabit instance
          const habit = new BadHabit(
            habitObj.id,
            habitObj.name,
            habitObj.description,
            habitObj.frequency,
            habitObj.category,
            habitObj.trigger,
            habitObj.alternative,
            habitObj.reminderTime,
            startDate
          );
          
          // Set the streak data
          habit.streakData = habitObj.streakData || {
            currentStreak: 0,
            bestStreak: 0,
            daysWithout: 0,
            successRate: 0
          };
          
          // Convert checkIn dates back to Date objects
          habit.checkIns = (habitObj.checkIns || []).map(checkIn => ({
            date: new Date(checkIn.date),
            success: checkIn.success
          }));
          
          // Add the habit to our collection
          this.habits.push(habit);
          
          // Update maxId if needed
          const habitId = parseInt(habitObj.id);
          if (!isNaN(habitId) && habitId > maxId) {
            maxId = habitId;
          }
        });
        
        // Set the next ID to be one higher than the max found
        this.nextId = maxId + 1;
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
    this.nextId = 1;
    localStorage.removeItem('badHabits');
  }
}

// Create a global instance for the application
const habitTracker = new HabitTracker();

// Initialize the tracker by loading from localStorage
document.addEventListener('DOMContentLoaded', () => {
  habitTracker.loadFromLocalStorage();
});