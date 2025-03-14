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
      
      // Simulate data sync
      setTimeout(() => {
        // Generate some sample fitness data
        const newData = this.generateSampleData();
        
        // Update stats
        this.stats.workouts += newData.workouts.length;
        this.stats.steps += newData.steps;
        this.stats.calories += newData.calories;
        
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
   * Generate sample data for demo purposes
   * In a real implementation, this would fetch actual data from the health API
   * @returns {Object} Sample health data
   */
  generateSampleData() {
    // In a real implementation, this would actually fetch data from the health API
    const today = new Date();
    
    return {
      steps: Math.floor(Math.random() * 5000) + 2000, // Random steps between 2000-7000
      calories: Math.floor(Math.random() * 400) + 100, // Random calories between 100-500
      workouts: [
        {
          type: ['running', 'cycling', 'walking', 'swimming', 'strength'][Math.floor(Math.random() * 5)],
          duration: Math.floor(Math.random() * 60) + 15, // 15-75 minutes
          calories: Math.floor(Math.random() * 300) + 100, // 100-400 calories
          date: today
        }
      ],
      sleep: this.dataTypes.includes('sleep') ? {
        startTime: new Date(today.setHours(22, 0, 0, 0)),
        endTime: new Date(today.setHours(7, 0, 0, 0)),
        quality: Math.floor(Math.random() * 5) + 1 // 1-5 quality
      } : null
    };
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