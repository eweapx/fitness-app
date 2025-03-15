const express = require('express');
const path = require('path');

// Create Express app
const app = express();
const PORT = process.env.PORT || 5000;

// Define path to public directory
const publicDir = path.join(__dirname, 'public');

// Set up logging middleware
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
  next();
});

// Serve static files from public directory
app.use(express.static(publicDir));

// API health route
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    version: '1.0.0'
  });
});

// Route for our fitness tracker app
app.get('/fitness', (req, res) => {
  res.sendFile(path.join(publicDir, 'fitness.html'));
});

// Default route for index
app.get('/', (req, res) => {
  res.sendFile(path.join(publicDir, 'index.html'));
});

// Start the server
const server = app.listen(PORT, '0.0.0.0', () => {
  console.log(`Simple server running at http://0.0.0.0:${PORT}`);
  console.log(`Server ready - listening on port ${PORT}`);
});

// Handle server errors
server.on('error', (error) => {
  console.error(`Server error: ${error.message}`);
  if (error.code === 'EADDRINUSE') {
    console.error(`Port ${PORT} is already in use. Try a different port.`);
  }
  process.exit(1);
});

// Export for testing
module.exports = app;