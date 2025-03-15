const express = require('express');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 5000;

// Middleware to log all requests
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
  next();
});

// Serve static files from the public directory
app.use(express.static(path.join(__dirname, 'public')));

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({ status: 'healthy' });
});

// Serve the fitness tracker HTML
app.get('/fitness', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'fitness.html'));
});

// Route for the test page
app.get('/test', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'test.html'));
});

// Route for the basic fitness tracker
app.get('/basic', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'basic-index.html'));
});

// Serve simple-index.html as the home page
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'simple-index.html'));
});

// Serve index.html as fallback for other routes
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Start the server
app.listen(PORT, '0.0.0.0', () => {
  console.log(`Simple server running at http://0.0.0.0:${PORT}`);
});