/**
 * HealthSnapshot class for storing health snapshot data
 */
class HealthSnapshot {
  /**
   * Create a new health snapshot
   * @param {number} heartRate - Heart rate in BPM
   * @param {number} energyLevel - Energy level rating (1-5)
   * @param {string} hydration - Hydration status
   * @param {number} waterIntake - Water intake in glasses
   * @param {number} mood - Mood rating (1-5)
   * @param {number} stressLevel - Stress level rating (1-5)
   * @param {string} notes - Additional notes
   * @param {Object} location - Location data (optional)
   * @param {Date} timestamp - When the snapshot was taken
   */
  constructor(
    heartRate,
    energyLevel,
    hydration,
    waterIntake,
    mood,
    stressLevel,
    notes = '',
    location = null,
    timestamp = new Date()
  ) {
    this.id = 'snapshot_' + Date.now();
    this.heartRate = heartRate;
    this.energyLevel = energyLevel;
    this.hydration = hydration;
    this.waterIntake = waterIntake;
    this.mood = mood;
    this.stressLevel = stressLevel;
    this.notes = notes;
    this.location = location;
    this.timestamp = timestamp;
  }

  /**
   * Get a formatted date-time string
   * @returns {string} Formatted date-time string
   */
  getFormattedDateTime() {
    const date = this.timestamp;
    return `${date.toLocaleDateString()} at ${date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}`;
  }

  /**
   * Get energy level description
   * @returns {string} Energy level description
   */
  getEnergyLevelDescription() {
    const descriptions = {
      1: 'Very Tired',
      2: 'Tired',
      3: 'Average',
      4: 'Energetic',
      5: 'Very Energetic'
    };
    return descriptions[this.energyLevel] || 'Unknown';
  }

  /**
   * Get mood description
   * @returns {string} Mood description with emoji
   */
  getMoodDescription() {
    const descriptions = {
      1: '😞 Very Sad',
      2: '🙁 Sad',
      3: '😐 Neutral',
      4: '🙂 Happy',
      5: '😄 Very Happy'
    };
    return descriptions[this.mood] || 'Unknown';
  }

  /**
   * Validate if the snapshot has all required fields
   * @returns {boolean} True if the snapshot is valid
   */
  isValid() {
    // Check if required fields are present and valid
    if (
      !this.heartRate ||
      !this.energyLevel ||
      !this.hydration ||
      this.waterIntake === undefined ||
      !this.mood ||
      !this.stressLevel
    ) {
      return false;
    }

    // Validate heart rate (normal range is 30-220 bpm)
    if (this.heartRate < 30 || this.heartRate > 220) {
      return false;
    }

    // Validate energy level (1-5)
    if (this.energyLevel < 1 || this.energyLevel > 5) {
      return false;
    }

    // Validate mood (1-5)
    if (this.mood < 1 || this.mood > 5) {
      return false;
    }

    // Validate stress level (1-5)
    if (this.stressLevel < 1 || this.stressLevel > 5) {
      return false;
    }

    // Validate water intake (0-10+)
    if (this.waterIntake < 0) {
      return false;
    }

    return true;
  }
}

/**
 * HealthSnapshotTracker class to manage health snapshots
 */
class HealthSnapshotTracker {
  constructor() {
    this.snapshots = [];
    this.loadFromLocalStorage();
  }

  /**
   * Add a new snapshot
   * @param {HealthSnapshot} snapshot - The snapshot to add
   * @returns {boolean} True if the snapshot was added successfully
   */
  addSnapshot(snapshot) {
    if (!(snapshot instanceof HealthSnapshot) || !snapshot.isValid()) {
      return false;
    }

    this.snapshots.push(snapshot);
    this.saveToLocalStorage();
    return true;
  }

  /**
   * Get all snapshots
   * @returns {Array} List of snapshots
   */
  getSnapshots() {
    return [...this.snapshots];
  }

  /**
   * Get the most recent snapshot
   * @returns {HealthSnapshot|null} The most recent snapshot, or null if none exist
   */
  getMostRecentSnapshot() {
    if (this.snapshots.length === 0) {
      return null;
    }
    
    // Sort by timestamp (newest first) and return the first one
    return [...this.snapshots]
      .sort((a, b) => b.timestamp - a.timestamp)[0];
  }

  /**
   * Get snapshots for a specific date
   * @param {Date} date - The date to filter by
   * @returns {Array} List of snapshots for the given date
   */
  getSnapshotsByDate(date) {
    const dateKey = this.formatDateKey(date);
    return this.snapshots.filter(snapshot => {
      return this.formatDateKey(snapshot.timestamp) === dateKey;
    });
  }

  /**
   * Format a date as YYYY-MM-DD for filtering
   * @param {Date} date - Date to format
   * @returns {string} Formatted date
   */
  formatDateKey(date) {
    return date.toISOString().split('T')[0];
  }

  /**
   * Get a specific snapshot by ID
   * @param {string} id - The ID of the snapshot to retrieve
   * @returns {HealthSnapshot|null} The snapshot if found, or null
   */
  getSnapshotById(id) {
    return this.snapshots.find(snapshot => snapshot.id === id) || null;
  }

  /**
   * Delete a snapshot by ID
   * @param {string} id - The ID of the snapshot to delete
   * @returns {boolean} True if the snapshot was deleted
   */
  deleteSnapshot(id) {
    const initialLength = this.snapshots.length;
    this.snapshots = this.snapshots.filter(snapshot => snapshot.id !== id);
    
    if (initialLength !== this.snapshots.length) {
      this.saveToLocalStorage();
      return true;
    }
    
    return false;
  }

  /**
   * Get health trends over time
   * @param {number} days - Number of days to analyze (default: 7)
   * @returns {Object} Trend data for different metrics
   */
  getHealthTrends(days = 7) {
    const trends = {
      heartRate: [],
      energyLevel: [],
      hydration: [],
      waterIntake: [],
      mood: [],
      stressLevel: []
    };

    // Get data for the specified number of days
    const today = new Date();
    const startDate = new Date();
    startDate.setDate(today.getDate() - days + 1);
    startDate.setHours(0, 0, 0, 0);

    // Filter snapshots within the date range
    const relevantSnapshots = this.snapshots.filter(
      snapshot => snapshot.timestamp >= startDate
    );

    // Group snapshots by date
    const groupedByDate = {};
    for (let i = 0; i < days; i++) {
      const date = new Date();
      date.setDate(today.getDate() - i);
      const dateKey = this.formatDateKey(date);
      groupedByDate[dateKey] = [];
    }

    relevantSnapshots.forEach(snapshot => {
      const dateKey = this.formatDateKey(snapshot.timestamp);
      if (groupedByDate[dateKey]) {
        groupedByDate[dateKey].push(snapshot);
      }
    });

    // Calculate daily averages
    const dates = Object.keys(groupedByDate).sort();
    
    dates.forEach(dateKey => {
      const dailySnapshots = groupedByDate[dateKey];
      
      if (dailySnapshots.length > 0) {
        // Calculate averages for numeric values
        const heartRateSum = dailySnapshots.reduce((sum, s) => sum + s.heartRate, 0);
        const energyLevelSum = dailySnapshots.reduce((sum, s) => sum + parseInt(s.energyLevel), 0);
        const waterIntakeSum = dailySnapshots.reduce((sum, s) => sum + s.waterIntake, 0);
        const moodSum = dailySnapshots.reduce((sum, s) => sum + parseInt(s.mood), 0);
        const stressLevelSum = dailySnapshots.reduce((sum, s) => sum + parseInt(s.stressLevel), 0);
        
        trends.heartRate.push({
          date: dateKey,
          value: Math.round(heartRateSum / dailySnapshots.length)
        });
        
        trends.energyLevel.push({
          date: dateKey,
          value: Math.round(energyLevelSum / dailySnapshots.length * 10) / 10
        });
        
        trends.waterIntake.push({
          date: dateKey,
          value: Math.round(waterIntakeSum / dailySnapshots.length * 10) / 10
        });
        
        trends.mood.push({
          date: dateKey,
          value: Math.round(moodSum / dailySnapshots.length * 10) / 10
        });
        
        trends.stressLevel.push({
          date: dateKey,
          value: Math.round(stressLevelSum / dailySnapshots.length * 10) / 10
        });
        
        // For hydration, use the most common value
        const hydrationCounts = {};
        dailySnapshots.forEach(s => {
          hydrationCounts[s.hydration] = (hydrationCounts[s.hydration] || 0) + 1;
        });
        
        let mostCommonHydration = null;
        let highestCount = 0;
        
        Object.keys(hydrationCounts).forEach(hydration => {
          if (hydrationCounts[hydration] > highestCount) {
            mostCommonHydration = hydration;
            highestCount = hydrationCounts[hydration];
          }
        });
        
        trends.hydration.push({
          date: dateKey,
          value: mostCommonHydration
        });
      } else {
        // No data for this date, add null values
        trends.heartRate.push({ date: dateKey, value: null });
        trends.energyLevel.push({ date: dateKey, value: null });
        trends.hydration.push({ date: dateKey, value: null });
        trends.waterIntake.push({ date: dateKey, value: null });
        trends.mood.push({ date: dateKey, value: null });
        trends.stressLevel.push({ date: dateKey, value: null });
      }
    });

    // Sort by date (oldest first)
    Object.keys(trends).forEach(metric => {
      trends[metric].sort((a, b) => new Date(a.date) - new Date(b.date));
    });

    return trends;
  }

  /**
   * Save snapshots to localStorage
   */
  saveToLocalStorage() {
    localStorage.setItem('healthSnapshots', JSON.stringify(this.snapshots));
  }

  /**
   * Load snapshots from localStorage
   */
  loadFromLocalStorage() {
    try {
      const saved = localStorage.getItem('healthSnapshots');
      if (saved) {
        const parsedData = JSON.parse(saved);
        this.snapshots = parsedData.map(data => {
          // Convert timestamp string back to Date object
          data.timestamp = new Date(data.timestamp);
          return Object.assign(new HealthSnapshot(), data);
        });
      }
    } catch (error) {
      console.error('Error loading health snapshots from localStorage:', error);
      this.snapshots = [];
    }
  }

  /**
   * Clear all snapshot data
   */
  reset() {
    this.snapshots = [];
    this.saveToLocalStorage();
  }
}

// Create a singleton instance
const healthSnapshotTracker = new HealthSnapshotTracker();