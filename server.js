const express = require('express');
const path = require('path');
const fs = require('fs');

// Create Express app
const app = express();
const PORT = 5000; // Using port 5000

// Middleware for parsing JSON bodies
app.use(express.json());

// Define paths to static content
const publicDir = path.join(__dirname, 'public');

// Set up logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
  next();
});

// Simple test endpoint that just returns a string
app.get('/test', (req, res) => {
  res.send('Server is running!');
});

// Serve static files from public directory
app.use(express.static(publicDir));

// API health endpoint
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    message: 'Fitness server is running properly',
    timestamp: new Date().toISOString() 
  });
});

// API version endpoint
app.get('/api/version', (req, res) => {
  res.json({ version: '1.0.0', platform: 'web' });
});

// Route for our fitness tracker app
app.get('/fitness', (req, res) => {
  res.sendFile(path.join(publicDir, 'fitness.html'));
});

// Route for simple test page
app.get('/test-page', (req, res) => {
  res.sendFile(path.join(publicDir, 'test.html'));
});

// Fallback route
app.get('*', (req, res) => {
  const indexPath = path.join(publicDir, 'index.html');
  
  if (fs.existsSync(indexPath)) {
    res.sendFile(indexPath);
  } else {
    res.status(404).send('No index.html found');
  }
});

// Start the server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server running at http://0.0.0.0:${PORT}`);
  console.log(`Server ready - listening on port ${PORT}`);
});

// Export for testing
module.exports = app;