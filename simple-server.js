const express = require('express');
const path = require('path');

// Create Express app
const app = express();
const PORT = 8080; // Try port 8080 for this simplified server

// Serve static files from public directory
app.use(express.static(path.join(__dirname, 'public')));

// Simple health check route
app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'healthy', 
    timestamp: new Date().toISOString()
  });
});

// Direct route to fitness page
app.get('/fitness', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'fitness.html'));
});

// Fallback route for other requests - serve index.html
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Start the server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Simple server running at http://0.0.0.0:${PORT}`);
});