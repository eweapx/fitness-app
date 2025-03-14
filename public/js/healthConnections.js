/**
 * Health Connections module for integrating with external health data sources
 * Supports Apple Health, Google Fit, and fitness watches
 */

class HealthConnection {
  /**
   * Create a new health data connection
   * @param {string} type - Connection type (apple-health, google-fit, fitness-watch)
   * @param {Object} settings - Connection settings
   * @param {Array} dataTypes - Types of data to sync (steps, workouts, sleep, etc.)
   * @param {string} syncFrequency - How often to sync (realtime, hourly, daily, manual)
   */
  constructor(type, settings, dataTypes, syncFrequency) {
    this.id = 'conn_' + Date.now();
    this.type = type;
    this.settings = settings || {};
    this.dataTypes = dataTypes || [];
    this.syncFrequency = syncFrequency || 'daily';
    this.connected = false;
    this.lastSync = null;
    this.stats = {
      workouts: 0,
      steps: 0,
      calories: 0
    };
  }

  /**
   * Connect to the health data source
   * @returns {Promise} Connection result
   */
  connect() {
    return new Promise((resolve, reject) => {
      console.log(`Attempting to connect to ${this.type}...`);
      
      // Simulate connection process
      setTimeout(() => {
        this.connected = true;
        this.lastSync = new Date();
        console.log(`Successfully connected to ${this.type}`);
        resolve({
          success: true,
          message: `Successfully connected to ${this.getDisplayName()}`
        });
      }, 1500);
    });
  }

  /**
   * Sync data from the health source
   * @returns {Promise} Sync result with data
   */
  syncData() {
    return new Promise((resolve, reject) => {
      console.log(`Syncing data from ${this.type}...`);
      
      // In a real implementation, this would connect to the actual health API
      setTimeout(() => {
        // Get data from the health source API
        const newData = this.fetchHealthData();
        
        // Tag each workout with this connection as the source
        if (newData.workouts && newData.workouts.length > 0) {
          newData.workouts.forEach(workout => {
            workout.sourceConnection = this.id;
            workout.sourceId = `${this.type}_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
          });
        }
        
        // Update stats
        this.stats.workouts += newData.workouts ? newData.workouts.length : 0;
        this.stats.steps += newData.steps || 0;
        this.stats.calories += newData.calories || 0;
        
        this.lastSync = new Date();
        
        console.log(`Successfully synced data from ${this.type}`);
        resolve({
          success: true,
          message: `Successfully synced data from ${this.getDisplayName()}`,
          data: newData
        });
      }, 2000);
    });
  }
  
  /**
   * Delete an activity from the health data source
   * @param {string} sourceId - The source-specific ID of the activity to delete
   * @returns {Promise} Delete result
   */
  deleteActivityFromSource(sourceId) {
    return new Promise((resolve, reject) => {
      console.log(`Deleting activity ${sourceId} from ${this.type}...`);
      
      // In a real implementation, this would call the health API to delete the activity
      setTimeout(() => {
        console.log(`Successfully deleted activity from ${this.type}`);
        
        // Update stats (decrement workouts count)
        this.stats.workouts = Math.max(0, this.stats.workouts - 1);
        
        resolve({
          success: true,
          message: `Successfully deleted activity from ${this.getDisplayName()}`
        });
      }, 1000);
    });
  }

  /**
   * Disconnect from the health data source
   * @returns {Promise} Disconnect result
   */
  disconnect() {
    return new Promise((resolve, reject) => {
      console.log(`Disconnecting from ${this.type}...`);
      
      // Simulate disconnection
      setTimeout(() => {
        this.connected = false;
        console.log(`Successfully disconnected from ${this.type}`);
        resolve({
          success: true,
          message: `Successfully disconnected from ${this.getDisplayName()}`
        });
      }, 1000);
    });
  }

  /**
   * Get a friendly display name for this connection
   * @returns {string} Display name
   */
  getDisplayName() {
    switch(this.type) {
      case 'apple-health':
        return 'Apple Health';
      case 'google-fit':
        return 'Google Fit';
      case 'fitness-watch':
        const brand = this.settings.brand || 'Unknown';
        switch(brand) {
          case 'apple-watch': return 'Apple Watch';
          case 'fitbit': return 'Fitbit';
          case 'garmin': return 'Garmin';
          case 'samsung': return 'Samsung Galaxy Watch';
          default: return `${brand} Watch`;
        }
      default:
        return this.type;
    }
  }

  /**
   * Get formatted last sync time
   * @returns {string} Formatted time
   */
  getFormattedLastSync() {
    if (!this.lastSync) {
      return 'Never';
    }
    return this.lastSync.toLocaleString();
  }

  /**
   * Fetch health data from the connected device/service
   * In a real app, this would use the respective health API
   * @returns {Object} The health data from the device
   */
  fetchHealthData() {
    // In a real implementation, this would connect to Apple Health, Google Fit, or device API
    // and retrieve the actual health data using their respective SDKs
    
    const data = {};
    const today = new Date();
    
    // Only include data types that the user has authorized
    if (this.dataTypes.includes('steps')) {
      // For demo purposes, use more realistic step counts based on device type
      switch (this.type) {
        case 'apple-health':
          data.steps = 10872; // More realistic step count from real device
          break;
        case 'google-fit':
          data.steps = 9543;
          break;
        case 'fitness-watch':
          data.steps = 11249;
          break;
        default:
          data.steps = 8000 + Math.floor(Math.random() * 4000); // 8000-12000 range
      }
    }
    
    if (this.dataTypes.includes('workouts')) {
      // Create sample workout with realistic data
      const workoutTypes = ['running', 'cycling', 'walking', 'swimming', 'strength'];
      const workoutType = workoutTypes[Math.floor(Math.random() * workoutTypes.length)];
      
      // Calculate realistic calories based on workout type and duration
      let baseDuration, baseCalories;
      
      switch (workoutType) {
        case 'running':
          baseDuration = 30 + Math.floor(Math.random() * 30); // 30-60 mins
          baseCalories = 10 * baseDuration; // ~10 calories per minute
          break;
        case 'cycling':
          baseDuration = 45 + Math.floor(Math.random() * 45); // 45-90 mins
          baseCalories = 8 * baseDuration; // ~8 calories per minute
          break;
        case 'walking':
          baseDuration = 30 + Math.floor(Math.random() * 90); // 30-120 mins
          baseCalories = 5 * baseDuration; // ~5 calories per minute
          break;
        case 'swimming':
          baseDuration = 30 + Math.floor(Math.random() * 30); // 30-60 mins
          baseCalories = 9 * baseDuration; // ~9 calories per minute
          break;
        case 'strength':
          baseDuration = 45 + Math.floor(Math.random() * 30); // 45-75 mins
          baseCalories = 7 * baseDuration; // ~7 calories per minute
          break;
        default:
          baseDuration = 30;
          baseCalories = 200;
      }
      
      // Add slight randomization to calories
      const calories = baseCalories + Math.floor(Math.random() * 50 - 25); // +/- 25 calories
      
      data.workouts = [
        {
          type: workoutType,
          duration: baseDuration,
          calories: calories,
          date: today
        }
      ];
      
      // Add calories from workout to total calories
      data.calories = calories;
    } else if (this.dataTypes.includes('calories')) {
      // Provide base caloric burn if no workout but calories tracking is enabled
      data.calories = 1800 + Math.floor(Math.random() * 500); // 1800-2300 base calories
    }
    
    if (this.dataTypes.includes('sleep')) {
      // Create realistic sleep data
      const bedTime = new Date(today);
      bedTime.setDate(bedTime.getDate() - 1);
      bedTime.setHours(22, 30, 0, 0); // 10:30 PM
      
      const wakeTime = new Date(today);
      wakeTime.setHours(6, 45, 0, 0); // 6:45 AM
      
      data.sleep = {
        startTime: bedTime,
        endTime: wakeTime,
        quality: 4 // 1-5 quality (4 = good sleep)
      };
    }
    
    return data;
  }
}

/**
 * HealthConnectionManager class to manage all external health data connections
 */
class HealthConnectionManager {
  constructor() {
    this.connections = [];
    this.loadFromLocalStorage();
  }

  /**
   * Add a new health connection
   * @param {HealthConnection} connection - The connection to add
   * @returns {Promise} Connection result
   */
  addConnection(connection) {
    return new Promise((resolve, reject) => {
      // Check if connection of same type already exists
      const existingConnection = this.connections.find(conn => conn.type === connection.type);
      if (existingConnection) {
        if (connection.type === 'fitness-watch' && 
            existingConnection.settings.brand !== connection.settings.brand) {
          // Allow multiple fitness watches of different brands
        } else {
          // Replace existing connection of same type
          this.removeConnection(existingConnection.id);
        }
      }
      
      // Connect to the health data source
      connection.connect()
        .then(result => {
          this.connections.push(connection);
          this.saveToLocalStorage();
          
          // Start initial sync
          return connection.syncData();
        })
        .then(syncResult => {
          this.saveToLocalStorage();
          resolve({
            success: true,
            connection: connection,
            syncResult: syncResult
          });
        })
        .catch(error => {
          reject({
            success: false,
            error: error
          });
        });
    });
  }

  /**
   * Get all connections
   * @returns {Array} List of connections
   */
  getConnections() {
    return [...this.connections];
  }

  /**
   * Get a specific connection by ID
   * @param {string} id - Connection ID
   * @returns {HealthConnection|null} The connection if found, null otherwise
   */
  getConnectionById(id) {
    return this.connections.find(conn => conn.id === id) || null;
  }

  /**
   * Remove a connection by ID
   * @param {string} id - Connection ID to remove
   * @returns {Promise} Disconnect result
   */
  removeConnection(id) {
    const connection = this.getConnectionById(id);
    if (!connection) {
      return Promise.resolve({ success: false, message: 'Connection not found' });
    }
    
    return connection.disconnect()
      .then(result => {
        this.connections = this.connections.filter(conn => conn.id !== id);
        this.saveToLocalStorage();
        return {
          success: true,
          message: `Removed connection to ${connection.getDisplayName()}`
        };
      });
  }

  /**
   * Sync data from all connections
   * @returns {Promise} Sync results
   */
  syncAllConnections() {
    const syncPromises = this.connections.map(conn => conn.syncData());
    
    return Promise.all(syncPromises)
      .then(results => {
        this.saveToLocalStorage();
        return {
          success: true,
          results: results
        };
      });
  }

  /**
   * Save connections to localStorage
   */
  saveToLocalStorage() {
    localStorage.setItem('healthConnections', JSON.stringify(this.connections));
  }

  /**
   * Load connections from localStorage
   */
  loadFromLocalStorage() {
    const savedConnections = localStorage.getItem('healthConnections');
    
    if (savedConnections) {
      try {
        const parsedConnections = JSON.parse(savedConnections);
        
        // Convert plain objects back to HealthConnection instances
        this.connections = parsedConnections.map(conn => {
          const connection = new HealthConnection(
            conn.type,
            conn.settings,
            conn.dataTypes,
            conn.syncFrequency
          );
          
          // Restore properties
          connection.id = conn.id;
          connection.connected = conn.connected;
          connection.stats = conn.stats || { workouts: 0, steps: 0, calories: 0 };
          
          // Convert lastSync back to Date object if it exists
          if (conn.lastSync) {
            connection.lastSync = new Date(conn.lastSync);
          }
          
          return connection;
        });
      } catch (error) {
        console.error('Error loading health connections from localStorage', error);
        this.connections = [];
      }
    }
  }

  /**
   * Get aggregate statistics across all connections
   * @returns {Object} Aggregated stats
   */
  getAggregateStats() {
    const stats = {
      workouts: 0,
      steps: 0,
      calories: 0,
      lastSync: null
    };
    
    this.connections.forEach(conn => {
      stats.workouts += conn.stats.workouts;
      stats.steps += conn.stats.steps;
      stats.calories += conn.stats.calories;
      
      // Track most recent sync across all connections
      if (conn.lastSync && (!stats.lastSync || conn.lastSync > stats.lastSync)) {
        stats.lastSync = conn.lastSync;
      }
    });
    
    return stats;
  }
}