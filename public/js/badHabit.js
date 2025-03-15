/**
 * BadHabit class for tracking habits that users want to break (Deload)
 */
class BadHabit {
  /**
   * Create a new BadHabit to track with deload progression
   * @param {string} id - Unique identifier for the habit
   * @param {string} name - Name of the bad habit to break
   * @param {string} description - Why the user wants to quit
   * @param {number} frequency - Starting frequency value (times per day/week)
   * @param {string} frequencyUnit - Unit of frequency (daily or weekly)
   * @param {string} category - Type of habit (smoking, drinking, etc.)
   * @param {string} trigger - What triggers this habit
   * @param {string} alternative - Healthier alternative to replace the habit
   * @param {string} reminderTime - Daily time for check-in reminder
   * @param {number} deloadDuration - Duration of deload in days (default: 21)
   * @param {Date} startDate - When tracking of this habit began
   */
  constructor(id, name, description, frequency, frequencyUnit = 'daily', category, trigger, alternative, reminderTime, deloadDuration = 21, startDate = new Date()) {
    this.id = id || generateUUID();
    this.name = name;
    this.description = description;
    this.startingFrequency = parseInt(frequency) || 1;
    this.frequency = parseInt(frequency) || 1;
    this.frequencyUnit = frequencyUnit; // 'daily' or 'weekly'
    this.category = category;
    this.trigger = trigger;
    this.alternative = alternative;
    this.reminderTime = reminderTime;
    this.deloadDuration = parseInt(deloadDuration) || 21;
    this.startDate = startDate instanceof Date ? startDate : new Date(startDate);
    this.targetDate = new Date(this.startDate);
    this.targetDate.setDate(this.targetDate.getDate() + this.deloadDuration);
    
    // Check-in and streak tracking
    this.checkIns = {};
    this.currentStreak = 0;
    this.longestStreak = 0;
    this.lastCheckIn = null;
    
    // Difficulty tracking for analytics
    this.difficulties = {};
    this.notes = {};
    
    // Calculate deload targets when habit is created
    this.calculateDeloadTargets();
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
   * Calculate deload targets for each day/week of the program
   * Creates a gradual reduction in frequency to reach zero by the target date
   */
  calculateDeloadTargets() {
    // Create an array of targets from start to end date
    this.deloadTargets = [];
    
    // Calculate number of steps (days or weeks depending on frequency unit)
    const totalSteps = this.frequencyUnit === 'daily' 
      ? this.deloadDuration 
      : Math.ceil(this.deloadDuration / 7);
    
    // Calculate reduction per step
    // We want to reach 0 at the end, so divide starting frequency by number of steps
    const reductionPerStep = this.startingFrequency / totalSteps;
    
    // Generate targets for each step
    for (let i = 0; i < totalSteps; i++) {
      const targetValue = Math.max(0, Math.round((this.startingFrequency - (reductionPerStep * i)) * 10) / 10);
      this.deloadTargets.push(targetValue);
    }
    
    // Make sure the last value is 0
    if (this.deloadTargets.length > 0) {
      this.deloadTargets[this.deloadTargets.length - 1] = 0;
    }
    
    return this.deloadTargets;
  }
  
  /**
   * Get the current deload target
   * @returns {number} The target frequency for today
   */
  getCurrentTarget() {
    const daysSinceStart = this.getDaysSinceStart();
    
    // If past the deload duration, return 0
    if (daysSinceStart >= this.deloadDuration) {
      return 0;
    }
    
    if (this.frequencyUnit === 'daily') {
      // For daily frequency, return the target for the current day
      return this.deloadTargets[daysSinceStart] || 0;
    } else {
      // For weekly frequency, return the target for the current week
      const currentWeek = Math.floor(daysSinceStart / 7);
      return this.deloadTargets[currentWeek] || 0;
    }
  }
  
  /**
   * Get a plain-language description of the current status
   * @returns {string} Status description
   */
  getStatusDescription() {
    const daysSinceStart = this.getDaysSinceStart();
    
    // If complete
    if (daysSinceStart >= this.deloadDuration) {
      return "Deload complete! Maintain your progress.";
    }
    
    // If just started
    if (daysSinceStart === 0) {
      return "Starting your deload journey today.";
    }
    
    // In progress
    const progressPercent = Math.round((daysSinceStart / this.deloadDuration) * 100);
    const daysRemaining = this.deloadDuration - daysSinceStart;
    
    return `${progressPercent}% complete. ${daysRemaining} days remaining.`;
  }
  
  /**
   * Get deload progress percentage
   * @returns {number} Progress percentage (0-100)
   */
  getProgressPercentage() {
    const daysSinceStart = this.getDaysSinceStart();
    return Math.min(100, Math.round((daysSinceStart / this.deloadDuration) * 100));
  }
  
  /**
   * Record the difficulty level for a check-in
   * @param {Date} date - Date of check-in
   * @param {number} difficulty - Difficulty level (1-5)
   */
  recordDifficulty(date, difficulty) {
    const dateKey = this.formatDateKey(date);
    this.difficulties[dateKey] = parseInt(difficulty) || 3;
    return this.difficulties[dateKey];
  }
  
  /**
   * Add notes to a check-in
   * @param {Date} date - Date of check-in
   * @param {string} note - User notes about the day
   */
  addNote(date, note) {
    const dateKey = this.formatDateKey(date);
    this.notes[dateKey] = note;
    return true;
  }
  
  /**
   * Get a formatted target date string
   * @returns {string} Formatted date string
   */
  getFormattedTargetDate() {
    const options = { year: 'numeric', month: 'short', day: 'numeric' };
    return this.targetDate.toLocaleDateString('en-US', options);
  }
  
  /**
   * Get a friendly name for the habit based on category
   * @returns {string} User-friendly habit name
   */
  getFriendlyName() {
    // If it has a custom name, use that
    if (this.name && this.name !== this.category) {
      return this.name;
    }
    
    // Generate a friendly name based on category
    switch (this.category) {
      case 'smoking': return 'Smoking';
      case 'drinking': return 'Drinking';
      case 'fast-food': return 'Fast Food';
      case 'soda': return 'Soda/Sugary Drinks';
      case 'vaping': return 'Vaping';
      case 'social-media': return 'Social Media Overuse';
      case 'screen-time': return 'Excessive Screen Time';
      case 'procrastination': return 'Procrastination';
      default: return this.category || 'Bad Habit';
    }
  }
  
  /**
   * Check if the habit has all required fields
   * @returns {boolean} True if the habit is valid
   */
  isValid() {
    return (
      this.name && 
      this.name.trim() !== '' && 
      this.startingFrequency > 0 && 
      this.category &&
      this.deloadDuration > 0
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
   * @param {number} difficulty - Difficulty level (1-5, optional)
   * @param {string} notes - Optional notes about the day
   * @returns {Object|null} Updated streak data if successful, null otherwise
   */
  recordCheckIn(id, date, success, difficulty = null, notes = null) {
    const habit = this.getHabitById(id);
    
    if (habit) {
      // Record the check-in (success/failure)
      const result = habit.addCheckIn(date, success);
      
      // Add difficulty rating if provided
      if (difficulty !== null) {
        habit.recordDifficulty(date, difficulty);
      }
      
      // Add notes if provided
      if (notes !== null && notes.trim() !== '') {
        habit.addNote(date, notes);
      }
      
      this.saveToLocalStorage();
      return result;
    }
    
    return null;
  }
  
  /**
   * Get the check-in status for a specific habit on a specific day
   * @param {string} id - ID of the habit
   * @param {Date} date - Date to check
   * @returns {Object|null} Check-in data if found, null otherwise
   */
  getCheckInStatus(id, date) {
    const habit = this.getHabitById(id);
    
    if (!habit) {
      return null;
    }
    
    const dateKey = habit.formatDateKey(date);
    const success = habit.checkIns[dateKey];
    const difficulty = habit.difficulties?.[dateKey] || null;
    const notes = habit.notes?.[dateKey] || '';
    const target = habit.getCurrentTarget();
    
    // If there's no check-in data for this date
    if (success === undefined) {
      return {
        date,
        checked: false,
        target
      };
    }
    
    return {
      date,
      checked: true,
      success,
      difficulty,
      notes,
      target
    };
  }
  
  /**
   * Get check-ins for the past week for a specific habit
   * @param {string} id - ID of the habit
   * @returns {Array} Array of check-in data for the past 7 days
   */
  getWeeklyCheckIns(id) {
    const habit = this.getHabitById(id);
    
    if (!habit) {
      return [];
    }
    
    const result = [];
    const today = new Date();
    
    for (let i = 6; i >= 0; i--) {
      const date = new Date(today);
      date.setDate(today.getDate() - i);
      const status = this.getCheckInStatus(id, date);
      
      if (status) {
        result.push(status);
      }
    }
    
    return result;
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
          // Handle both old and new format habits
          const frequencyUnit = habit.frequencyUnit || 'daily';
          const deloadDuration = habit.deloadDuration || 21;
          
          return new BadHabit(
            habit.id,
            habit.name,
            habit.description,
            habit.startingFrequency || habit.frequency,
            frequencyUnit,
            habit.category,
            habit.trigger,
            habit.alternative,
            habit.reminderTime,
            deloadDuration,
            new Date(habit.startDate)
          );
        });
        
        // Restore check-ins and additional properties
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
          
          // Restore deload-specific data
          if (parsedHabits[index].difficulties) {
            habit.difficulties = parsedHabits[index].difficulties;
          }
          if (parsedHabits[index].notes) {
            habit.notes = parsedHabits[index].notes;
          }
          if (parsedHabits[index].deloadTargets) {
            habit.deloadTargets = parsedHabits[index].deloadTargets;
          } else {
            // Calculate deload targets if not present
            habit.calculateDeloadTargets();
          }
          
          // Recreate target date
          habit.targetDate = new Date(habit.startDate);
          habit.targetDate.setDate(habit.targetDate.getDate() + habit.deloadDuration);
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