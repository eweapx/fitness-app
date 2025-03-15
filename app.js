const express = require('express');
const path = require('path');

// Initialize Express app
const app = express();
const PORT = process.env.PORT || 5000;

// Serve static files from the 'public' directory
app.use(express.static(path.join(__dirname, 'public')));

// Simple API health endpoint
app.get('/api/health', (req, res) => {
  res.json({
    status: 'healthy',
    message: 'Fitness server is running properly',
    timestamp: new Date().toISOString()
  });
});

// Simple home route
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Start the server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Fitness server running at http://0.0.0.0:${PORT}`);
});