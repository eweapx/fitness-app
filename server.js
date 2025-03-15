const express = require('express');
const path = require('path');
const { tracker, Activity } = require('./models');

// Create Express app
const app = express();
const PORT = 5000;

// Middleware for parsing JSON bodies
app.use(express.json());

// Log all requests
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
  next();
});

// Serve static files from the public directory
app.use(express.static('public'));

// API endpoint for health check
app.get('/api/health', (req, res) => {
  res.json({
    status: 'healthy',
    message: 'Fitness server is running properly',
    timestamp: new Date().toISOString()
  });
});

// API endpoint to get all activities
app.get('/api/activities', (req, res) => {
  res.json({
    success: true,
    data: tracker.getActivities()
  });
});

// API endpoint to add an activity
app.post('/api/activities', (req, res) => {
  const { name, calories, duration, type } = req.body;
  
  const activity = new Activity(
    name,
    parseInt(calories),
    parseInt(duration),
    type,
    new Date()
  );
  
  const success = tracker.addActivity(activity);
  
  if (success) {
    res.status(201).json({
      success: true,
      message: 'Activity added successfully',
      data: activity
    });
  } else {
    res.status(400).json({
      success: false,
      message: 'Invalid activity data'
    });
  }
});

// API endpoint to get fitness stats
app.get('/api/stats', (req, res) => {
  res.json({
    success: true,
    data: {
      totalCalories: tracker.getTotalCalories(),
      totalSteps: tracker.getTotalSteps(),
      activitiesCount: tracker.getActivitiesCount()
    }
  });
});

// API endpoint to add steps
app.post('/api/steps', (req, res) => {
  const { steps } = req.body;
  const success = tracker.addSteps(parseInt(steps));
  
  if (success) {
    res.status(201).json({
      success: true,
      message: 'Steps added successfully',
      totalSteps: tracker.getTotalSteps()
    });
  } else {
    res.status(400).json({
      success: false,
      message: 'Invalid steps data'
    });
  }
});

// API endpoint to reset all data (for testing)
app.post('/api/reset', (req, res) => {
  tracker.reset();
  res.json({
    success: true,
    message: 'All data has been reset'
  });
});

// Start the server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Fitness server running at http://0.0.0.0:${PORT}`);
});