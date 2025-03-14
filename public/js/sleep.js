/**
 * SleepRecord class for storing sleep data
 */
class SleepRecord {
  /**
   * Create a new SleepRecord
   * @param {Date} startTime - When the user went to bed
   * @param {Date} endTime - When the user woke up
   * @param {number} quality - Sleep quality rating (1-5)
   * @param {string} notes - Any notes about the sleep (optional)
   * @param {Array} disturbances - Array of sleep disturbances (optional)
   */
  constructor(startTime, endTime, quality, notes = '', disturbances = []) {
    this.id = crypto.randomUUID ? crypto.randomUUID() : Date.now().toString();
    this.startTime = startTime;
    this.endTime = endTime;
    this.quality = quality;
    this.notes = notes;
    this.disturbances = disturbances;
    this.date = startTime; // For consistent date-based filtering
  }
  
  /**
   * Get sleep duration in hours
   * @returns {number} Sleep duration in hours
   */
  getDuration() {
    const durationMs = this.endTime - this.startTime;
    return parseFloat((durationMs / (1000 * 60 * 60)).toFixed(1));
  }
  
  /**
   * Get formatted date string for display
   * @returns {string} Formatted date string
   */
  getFormattedDate() {
    return this.startTime.toLocaleDateString('en-US', { 
      weekday: 'short',
      month: 'short', 
      day: 'numeric'
    });
  }
  
  /**
   * Get formatted time string for display
   * @param {Date} time - Time to format
   * @returns {string} Formatted time string
   */
  getFormattedTime(time) {
    return time.toLocaleTimeString('en-US', { 
      hour: '2-digit', 
      minute: '2-digit',
      hour12: true
    });
  }
  
  /**
   * Get sleep quality description
   * @returns {string} Quality description
   */
  getQualityDescription() {
    switch(this.quality) {
      case 5:
        return 'Excellent';
      case 4:
        return 'Good';
      case 3:
        return 'Average';
      case 2:
        return 'Fair';
      case 1:
        return 'Poor';
      default:
        return 'Unknown';
    }
  }
  
  /**
   * Validate if the sleep record has all required fields
   * @returns {boolean} True if the sleep record is valid
   */
  isValid() {
    return (
      this.startTime instanceof Date && !isNaN(this.startTime) &&
      this.endTime instanceof Date && !isNaN(this.endTime) &&
      this.endTime > this.startTime &&
      typeof this.quality === 'number' && this.quality >= 1 && this.quality <= 5
    );
  }
}

/**
 * SleepTracker class to manage sleep data
 */
class SleepTracker {
  constructor() {
    this.sleepRecords = [];
    this.goals = {
      duration: 8, // Target sleep duration in hours
      quality: 4,  // Target sleep quality (1-5)
      consistency: 90 // Target bedtime consistency percentage
    };
    
    // Load data from localStorage
    this.loadFromLocalStorage();
  }
  
  /**
   * Add a new sleep record to the tracker
   * @param {SleepRecord} sleepRecord - The sleep record to add
   * @returns {boolean} True if the record was added successfully
   */
  addSleepRecord(sleepRecord) {
    // Validate the sleep record
    if (!sleepRecord.isValid()) {
      return false;
    }
    
    // Add the sleep record
    this.sleepRecords.push(sleepRecord);
    
    // Save to localStorage
    this.saveToLocalStorage();
    
    return true;
  }
  
  /**
   * Get all sleep records
   * @returns {Array} List of sleep records
   */
  getSleepRecords() {
    return this.sleepRecords;
  }
  
  /**
   * Get sleep records for a specific date
   * @param {Date} date - The date to filter by
   * @returns {Array} List of sleep records for the given date
   */
  getSleepRecordsByDate(date) {
    const dateKey = this.formatDateKey(date);
    
    return this.sleepRecords.filter(record => {
      const recordDateKey = this.formatDateKey(record.date);
      return recordDateKey === dateKey;
    });
  }
  
  /**
   * Delete a sleep record
   * @param {string} id - ID of the record to delete
   * @returns {boolean} True if the record was deleted successfully
   */
  deleteSleepRecord(id) {
    const initialLength = this.sleepRecords.length;
    this.sleepRecords = this.sleepRecords.filter(record => record.id !== id);
    
    if (this.sleepRecords.length < initialLength) {
      // Save to localStorage
      this.saveToLocalStorage();
      return true;
    }
    
    return false;
  }
  
  /**
   * Format a date as YYYY-MM-DD for filtering
   * @param {Date} date - Date to format
   * @returns {string} Formatted date
   */
  formatDateKey(date) {
    return `${date.getFullYear()}-${(date.getMonth() + 1).toString().padStart(2, '0')}-${date.getDate().toString().padStart(2, '0')}`;
  }
  
  /**
   * Get sleep summary for a specific date
   * @param {Date} date - The date to summarize
   * @returns {Object} Sleep summary with duration, quality, etc.
   */
  getSleepSummaryByDate(date) {
    const records = this.getSleepRecordsByDate(date);
    
    if (records.length === 0) {
      return {
        totalDuration: 0,
        averageQuality: 0,
        recordCount: 0
      };
    }
    
    const totalDuration = records.reduce((total, record) => total + record.getDuration(), 0);
    const totalQuality = records.reduce((total, record) => total + record.quality, 0);
    
    return {
      totalDuration,
      averageQuality: totalQuality / records.length,
      recordCount: records.length
    };
  }
  
  /**
   * Get daily sleep summaries for the past week
   * @returns {Array} Array of daily sleep summaries
   */
  getWeeklySleepSummary() {
    const results = [];
    const today = new Date();
    
    // Get data for the past 7 days
    for (let i = 6; i >= 0; i--) {
      const date = new Date(today);
      date.setDate(date.getDate() - i);
      
      const summary = this.getSleepSummaryByDate(date);
      
      results.push({
        date,
        summary
      });
    }
    
    return results;
  }
  
  /**
   * Get sleep goals
   * @returns {Object} Sleep goals
   */
  getGoals() {
    return this.goals;
  }
  
  /**
   * Update sleep goals
   * @param {Object} newGoals - New sleep goals
   */
  updateGoals(newGoals) {
    if (newGoals.duration) {
      this.goals.duration = parseFloat(newGoals.duration);
    }
    
    if (newGoals.quality) {
      this.goals.quality = parseFloat(newGoals.quality);
    }
    
    if (newGoals.consistency) {
      this.goals.consistency = parseFloat(newGoals.consistency);
    }
    
    // Save to localStorage
    this.saveToLocalStorage();
  }
  
  /**
   * Get sleep statistics
   * @returns {Object} Sleep statistics 
   */
  getStats() {
    if (this.sleepRecords.length === 0) {
      return {
        averageDuration: 0,
        averageQuality: 0,
        consistencyScore: 0,
        recordCount: 0
      };
    }
    
    // Get records from the past 30 days for more relevant stats
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    
    const recentRecords = this.sleepRecords.filter(record => record.date >= thirtyDaysAgo);
    
    if (recentRecords.length === 0) {
      // Fall back to all-time stats if no recent records
      const totalDuration = this.sleepRecords.reduce((total, record) => total + record.getDuration(), 0);
      const totalQuality = this.sleepRecords.reduce((total, record) => total + record.quality, 0);
      
      return {
        averageDuration: totalDuration / this.sleepRecords.length,
        averageQuality: totalQuality / this.sleepRecords.length,
        consistencyScore: this.calculateConsistencyScore(this.sleepRecords),
        recordCount: this.sleepRecords.length
      };
    }
    
    // Calculate stats from recent records
    const totalDuration = recentRecords.reduce((total, record) => total + record.getDuration(), 0);
    const totalQuality = recentRecords.reduce((total, record) => total + record.quality, 0);
    
    return {
      averageDuration: totalDuration / recentRecords.length,
      averageQuality: totalQuality / recentRecords.length,
      consistencyScore: this.calculateConsistencyScore(recentRecords),
      recordCount: recentRecords.length
    };
  }
  
  /**
   * Calculate sleep consistency score (0-100)
   * @param {Array} records - Sleep records to analyze
   * @returns {number} Consistency score
   */
  calculateConsistencyScore(records) {
    if (records.length < 2) return 0;
    
    // Sort by date (oldest first)
    const sortedRecords = [...records].sort((a, b) => a.date - b.date);
    
    // Extract bedtime hours (in 24-hour format)
    const bedtimes = sortedRecords.map(record => {
      const hours = record.startTime.getHours();
      const minutes = record.startTime.getMinutes();
      return hours + (minutes / 60);
    });
    
    // Calculate standard deviation of bedtimes
    const avgBedtime = bedtimes.reduce((sum, time) => sum + time, 0) / bedtimes.length;
    const squaredDiffs = bedtimes.map(time => Math.pow(time - avgBedtime, 2));
    const avgSquaredDiff = squaredDiffs.reduce((sum, diff) => sum + diff, 0) / squaredDiffs.length;
    const stdDev = Math.sqrt(avgSquaredDiff);
    
    // Convert standard deviation to a 0-100 consistency score
    // Lower standard deviation = higher consistency
    // A stdDev of 0 means perfect consistency (100%)
    // A stdDev of 3+ hours means poor consistency (0%)
    const consistencyScore = Math.max(0, Math.min(100, 100 - (stdDev * 33.33)));
    
    return consistencyScore;
  }
  
  /**
   * Save sleep data to localStorage
   */
  saveToLocalStorage() {
    try {
      localStorage.setItem('sleepRecords', JSON.stringify(this.sleepRecords));
      localStorage.setItem('sleepGoals', JSON.stringify(this.goals));
    } catch (error) {
      console.error('Error saving sleep data to localStorage:', error);
    }
  }
  
  /**
   * Load sleep data from localStorage
   */
  loadFromLocalStorage() {
    try {
      // Load sleep records
      const sleepRecordsData = localStorage.getItem('sleepRecords');
      if (sleepRecordsData) {
        const parsedRecords = JSON.parse(sleepRecordsData);
        
        // Restore date objects
        this.sleepRecords = parsedRecords.map(record => {
          const sleepRecord = new SleepRecord(
            new Date(record.startTime),
            new Date(record.endTime),
            record.quality,
            record.notes,
            record.disturbances
          );
          sleepRecord.id = record.id;
          sleepRecord.date = new Date(record.date);
          return sleepRecord;
        });
      }
      
      // Load goals
      const sleepGoalsData = localStorage.getItem('sleepGoals');
      if (sleepGoalsData) {
        this.goals = JSON.parse(sleepGoalsData);
      }
    } catch (error) {
      console.error('Error loading sleep data from localStorage:', error);
      this.sleepRecords = [];
    }
  }
  
  /**
   * Clear all sleep tracking data
   */
  reset() {
    this.sleepRecords = [];
    this.goals = {
      duration: 8,
      quality: 4,
      consistency: 90
    };
    
    // Clear localStorage
    localStorage.removeItem('sleepRecords');
    localStorage.removeItem('sleepGoals');
  }
}

// Initialize the sleep tracker
const sleepTracker = new SleepTracker();